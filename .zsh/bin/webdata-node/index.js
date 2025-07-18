#!/usr/bin/env node

const { chromium } = require('playwright');
const xml2js = require('xml2js');
const TurndownService = require('turndown');
const { program } = require('commander');
const fs = require('fs').promises;
const path = require('path');
const { URL } = require('url');
const readline = require('readline');

// Initialize Turndown service for HTML to Markdown conversion
const turndownService = new TurndownService({
  headingStyle: 'atx',
  codeBlockStyle: 'fenced'
});

// Configure turndown to handle common elements better
turndownService.addRule('images', {
  filter: 'img',
  replacement: (content, node) => {
    const alt = node.alt || '';
    const src = node.src || '';
    const title = node.title || '';
    return title ? `![${alt}](${src} "${title}")` : `![${alt}](${src})`;
  }
});

// Parse command line arguments
program
  .name('webdata')
  .description('Capture website data (screenshots and markdown)')
  .argument('<url>', 'URL to capture (sitemap.xml or webpage)')
  .option('-o, --output <directory>', 'output directory', './output')
  .option('-f, --force', 'skip overwrite confirmation')
  .option('-c, --concurrent <number>', 'number of concurrent pages to process', '1')
  .option('-i, --interval-sec <seconds>', 'interval between requests in seconds', '1')
  .option('--pc', 'capture PC size screenshots (1440x900)')
  .option('--tablet', 'capture tablet size screenshots (768x1024)')
  .option('--mobile', 'capture mobile size screenshots (375x667)')
  .parse();

const options = program.opts();
const url = program.args[0];
const outputDir = options.output;
const concurrentLimit = parseInt(options.concurrent) || 1;
const requestInterval = parseFloat(options.intervalSec) || 1;

// Global browser instance for cleanup
let globalBrowser = null;

// Graceful shutdown handler
async function gracefulShutdown(signal) {
  console.log(`\nReceived ${signal}. Shutting down gracefully...`);
  if (globalBrowser) {
    try {
      await globalBrowser.close();
      console.log('Browser closed successfully');
    } catch (error) {
      console.error('Error closing browser:', error.message);
    }
  }
  process.exit(0);
}

// Register signal handlers
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGQUIT', () => gracefulShutdown('SIGQUIT'));

// Memory usage monitoring
function checkMemoryUsage() {
  const usage = process.memoryUsage();
  const usedMB = Math.round(usage.heapUsed / 1024 / 1024);
  const totalMB = Math.round(usage.heapTotal / 1024 / 1024);

  if (usedMB > 1000) { // Warning if over 1GB
    console.warn(`⚠️  High memory usage: ${usedMB}MB / ${totalMB}MB`);
  }

  return { usedMB, totalMB };
}

// Domain-based rate limiting
const domainLimiter = new Map();
let DOMAIN_RATE_LIMIT_MS = requestInterval * 1000; // Convert seconds to milliseconds

async function rateLimitedOperation(url, operation) {
  const domain = new URL(url).hostname;
  const lastAccess = domainLimiter.get(domain) || 0;
  const now = Date.now();
  const timeSinceLastAccess = now - lastAccess;

  if (timeSinceLastAccess < DOMAIN_RATE_LIMIT_MS) {
    const waitTime = DOMAIN_RATE_LIMIT_MS - timeSinceLastAccess;
    console.log(`  Rate limiting: waiting ${waitTime}ms for ${domain}`);
    await new Promise(resolve => setTimeout(resolve, waitTime));
  }

  domainLimiter.set(domain, Date.now());
  return await operation();
}

// Device viewport configurations
const deviceConfigs = {
  pc: { width: 1440, height: 900 },
  tablet: { width: 768, height: 1024 },
  mobile: { width: 375, height: 667 }
};

// Determine which devices to capture
const devicesToCapture = [];
if (options.pc) devicesToCapture.push('pc');
if (options.tablet) devicesToCapture.push('tablet');
if (options.mobile) devicesToCapture.push('mobile');

// Default to pc if no devices specified
if (devicesToCapture.length === 0) {
  devicesToCapture.push('pc');
}

// URL validation function
function validateUrl(url) {
  try {
    const urlObj = new URL(url);
    return ['http:', 'https:'].includes(urlObj.protocol);
  } catch {
    return false;
  }
}

// Retry operation with exponential backoff
async function retryOperation(operation, maxRetries = 3, initialDelay = 1000) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      const delay = initialDelay * Math.pow(2, i);
      console.log(`  Retry ${i + 1}/${maxRetries} after ${delay}ms... (${error.message})`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

// Utility function to create directory if it doesn't exist
async function ensureDir(dir) {
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch (error) {
    console.error(`Error creating directory ${dir}:`, error);
  }
}

// Generate README.md content from template
async function generateReadmeContent(url, devicesToCapture, isSitemap, urls = null) {
  const templatePath = path.join(__dirname, 'templates', 'README.md');

  try {
    const template = await fs.readFile(templatePath, 'utf8');

    const timestamp = new Date().toISOString();
    const deviceList = devicesToCapture.map(d => `- ${d}: ${deviceConfigs[d].width}x${deviceConfigs[d].height}`).join('\n');
    const deviceTree = devicesToCapture.map(d => `│   ├── ${d}/            # ${d.charAt(0).toUpperCase() + d.slice(1)} size screenshots (${deviceConfigs[d].width}x${deviceConfigs[d].height})`).join('\n');

    let sourceType = isSitemap ? 'Sitemap' : 'Single Page';
    let pageCountInfo = '';
    let processingInfo = '';

    if (isSitemap && urls) {
      pageCountInfo = `**Pages captured:** ${urls.length}`;
      processingInfo = `**Processing:** sitemap.xml をベースに全ページを取得`;
    } else {
      processingInfo = `**Processing:** 単一ページを取得`;
    }

    return template
      .replace('{{TIMESTAMP}}', timestamp)
      .replace('{{SOURCE_TYPE}}', sourceType)
      .replace('{{SOURCE_URL}}', url)
      .replace('{{PAGE_COUNT_INFO}}', pageCountInfo)
      .replace('{{PROCESSING_INFO}}', processingInfo)
      .replace('{{DEVICE_LIST}}', deviceList)
      .replace('{{DEVICE_TREE}}', deviceTree);

  } catch (error) {
    console.error('Error reading template file:', error.message);
    // Fallback to simple content if template fails
    return `# Website Data Capture\n\n**Generated:** ${new Date().toISOString()}\n**URL:** ${url}\n**Devices:** ${devicesToCapture.join(', ')}\n`;
  }
}

// Create README.md in output directory
async function createReadme(outputDir, url, devicesToCapture, isSitemap, urls = null) {
  const readmeContent = await generateReadmeContent(url, devicesToCapture, isSitemap, urls);
  const readmePath = path.join(outputDir, 'README.md');

  try {
    await fs.writeFile(readmePath, readmeContent, 'utf8');
    console.log(`README.md created: ${readmePath}`);
  } catch (error) {
    console.error(`Error creating README.md:`, error.message);
  }
}

// Check if directory exists
async function dirExists(dir) {
  try {
    const stats = await fs.stat(dir);
    return stats.isDirectory();
  } catch (error) {
    return false;
  }
}

// Ask user for confirmation
async function askConfirmation(message) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(`${message} (y/N): `, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y');
    });
  });
}

// Parse sitemap.xml and extract URLs
async function parseSitemap(xmlContent) {
  const parser = new xml2js.Parser();
  const result = await parser.parseStringPromise(xmlContent);
  const urls = [];

  // Handle different sitemap formats
  if (result.urlset && result.urlset.url) {
    result.urlset.url.forEach(urlEntry => {
      if (urlEntry.loc && urlEntry.loc[0]) {
        urls.push(urlEntry.loc[0]);
      }
    });
  } else if (result.sitemapindex && result.sitemapindex.sitemap) {
    // Handle sitemap index
    result.sitemapindex.sitemap.forEach(sitemapEntry => {
      if (sitemapEntry.loc && sitemapEntry.loc[0]) {
        urls.push(sitemapEntry.loc[0]);
      }
    });
  }

  return urls;
}

// Convert URL to file path
function urlToFilePath(urlString) {
  const urlObj = new URL(urlString);
  let pathname = urlObj.pathname;

  // Handle root path
  if (pathname === '/' || pathname === '') {
    return 'index';
  }

  // Remove leading and trailing slashes
  pathname = pathname.replace(/^\/|\/$/g, '');

  // Replace slashes with directory separators
  const parts = pathname.split('/');

  // If the last part has an extension, use it as is
  const lastPart = parts[parts.length - 1];
  if (!path.extname(lastPart) || lastPart.endsWith('.html') || lastPart.endsWith('.htm')) {
    // Remove .html/.htm extension or add index if no extension
    if (lastPart.endsWith('.html') || lastPart.endsWith('.htm')) {
      parts[parts.length - 1] = lastPart.replace(/\.html?$/, '');
    } else if (!path.extname(lastPart)) {
      // It's a directory, use the name as filename
      // Don't add index to avoid confusion
    }
  }

  return parts.join(path.sep);
}

// Simple semaphore implementation for concurrency control
class Semaphore {
  constructor(maxConcurrent) {
    this.maxConcurrent = maxConcurrent;
    this.current = 0;
    this.queue = [];
  }

  async acquire() {
    if (this.current < this.maxConcurrent) {
      this.current++;
      return Promise.resolve();
    }

    return new Promise((resolve) => {
      this.queue.push(resolve);
    });
  }

  release() {
    this.current--;
    if (this.queue.length > 0) {
      this.current++;
      const resolve = this.queue.shift();
      resolve();
    }
  }
}

// Capture single page
async function capturePage(page, url, outputDir, deviceType) {
  console.log(`Capturing: ${url}`);

  try {
    // Navigate to the page with retry logic and rate limiting
    await rateLimitedOperation(url, async () => {
      await retryOperation(async () => {
        await page.goto(url, {
          waitUntil: 'networkidle',
          timeout: 60000  // Increased timeout to 60 seconds
        });
      });
    });

    // Wait a bit for dynamic content
    await page.waitForTimeout(2000);

    // Check memory usage
    const { usedMB } = checkMemoryUsage();
    if (usedMB > 800) {
      console.log(`  Memory usage: ${usedMB}MB - considering cleanup`);
      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }
    }

    // Get the file path
    const filePath = urlToFilePath(url);
    const fileName = path.basename(filePath) || 'index';
    const dirPath = path.dirname(filePath);

    // Create directories with device type suffix for captures
    const captureDir = path.join(outputDir, 'captures', deviceType, dirPath);
    const markdownDir = path.join(outputDir, 'markdown', dirPath);
    await ensureDir(captureDir);
    await ensureDir(markdownDir);

    // Take screenshot
    const screenshotPath = path.join(captureDir, `${fileName}.png`);
    await page.screenshot({
      path: screenshotPath,
      fullPage: true
    });
    console.log(`  Screenshot saved: ${screenshotPath}`);

    // Get page content and convert to markdown
    const htmlContent = await page.content();

    // Extract title from HTML
    const titleMatch = htmlContent.match(/<title[^>]*>(.*?)<\/title>/i);
    const pageTitle = titleMatch ? titleMatch[1].trim() : 'Untitled';

    // Extract meta description
    const descriptionMatch = htmlContent.match(/<meta\s+name=['"']description['"']\s+content=['"']([^'"]*)['"'][^>]*>/i);
    const pageDescription = descriptionMatch ? descriptionMatch[1].trim() : '';

    // Extract meta keywords
    const keywordsMatch = htmlContent.match(/<meta\s+name=['"']keywords['"']\s+content=['"']([^'"]*)['"'][^>]*>/i);
    const pageKeywords = keywordsMatch ? keywordsMatch[1].trim() : '';

    // Remove script, style, and title tags before conversion
    const cleanedHtml = htmlContent
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
      .replace(/<noscript\b[^<]*(?:(?!<\/noscript>)<[^<]*)*<\/noscript>/gi, '')
      .replace(/<title\b[^<]*(?:(?!<\/title>)<[^<]*)*<\/title>/gi, '');

    const markdown = turndownService.turndown(cleanedHtml);

    // Clean up markdown: remove empty lines at the beginning
    const cleanedMarkdown = markdown.replace(/^\s*\n+/, '');

    // Add frontmatter with title
    const createdAt = new Date().toISOString();
    let frontmatter = `---\ntitle: "${pageTitle}"\nurl: "${url}"\ncreated: "${createdAt}"\n`;

    if (pageDescription) {
      frontmatter += `description: "${pageDescription}"\n`;
    }

    if (pageKeywords) {
      frontmatter += `keywords: "${pageKeywords}"\n`;
    }

    frontmatter += `---\n\n`;
    const markdownWithFrontmatter = frontmatter + cleanedMarkdown;

    // Save markdown (only once, not per device)
    const markdownPath = path.join(markdownDir, `${fileName}.md`);
    await fs.writeFile(markdownPath, markdownWithFrontmatter, 'utf8');
    console.log(`  Markdown saved: ${markdownPath}`);

  } catch (error) {
    console.error(`  Error capturing ${url}:`, error.message);
  }
}

// Process URLs with concurrency limit for multiple devices
async function processUrlsConcurrently(urls, browser, outputDir, devicesToCapture, concurrentLimit) {
  const semaphore = new Semaphore(concurrentLimit);
  const allPromises = [];

  // When interval is set (not default 1 second), process sequentially
  if (requestInterval !== 1) {
    console.log(`Using sequential processing with ${requestInterval}s interval between requests`);
    for (const url of urls) {
      for (const deviceType of devicesToCapture) {
        const page = await browser.newPage();
        await page.setViewportSize(deviceConfigs[deviceType]);
        await capturePage(page, url, outputDir, deviceType);
        await page.close();
        
        // Wait for the interval between requests (except for the last one)
        const isLastUrl = url === urls[urls.length - 1];
        const isLastDevice = deviceType === devicesToCapture[devicesToCapture.length - 1];
        if (!(isLastUrl && isLastDevice)) {
          await new Promise(resolve => setTimeout(resolve, requestInterval * 1000));
        }
      }
    }
    return;
  }

  // Original concurrent processing when using default interval
  for (const url of urls) {
    for (const deviceType of devicesToCapture) {
      const promise = (async () => {
        await semaphore.acquire();
        try {
          const page = await browser.newPage();
          await page.setViewportSize(deviceConfigs[deviceType]);
          await capturePage(page, url, outputDir, deviceType);
          await page.close();
        } finally {
          semaphore.release();
        }
      })();
      allPromises.push(promise);
    }
  }

  // Process all device/URL combinations concurrently
  let completed = 0;
  const total = urls.length * devicesToCapture.length;

  for (const promise of allPromises) {
    promise.then(() => {
      completed++;
      console.log(`Progress: ${completed}/${total}`);
    });
  }

  await Promise.all(allPromises);
}

// Main function
async function main() {
  // Validate URL
  if (!validateUrl(url)) {
    console.error('Error: Invalid URL format. Please provide a valid HTTP or HTTPS URL.');
    process.exit(1);
  }

  console.log(`Starting webdata capture...`);
  console.log(`URL: ${url}`);
  console.log(`Output directory: ${outputDir}`);
  console.log(`Device types: ${devicesToCapture.map(d => `${d} (${deviceConfigs[d].width}x${deviceConfigs[d].height})`).join(', ')}`);
  if (requestInterval !== 1) {
    console.log(`Request interval: ${requestInterval}s (concurrent processing disabled)`);
  }
  console.log(`Concurrent limit: ${concurrentLimit}`);
  console.log();

  // Create output directory
  await ensureDir(outputDir);

  // Check if captures or markdown directories already exist
  const capturesDir = path.join(outputDir, 'captures');
  const markdownDir = path.join(outputDir, 'markdown');
  const capturesExists = await dirExists(capturesDir);
  const markdownExists = await dirExists(markdownDir);

  if (capturesExists || markdownExists) {
    console.log('Warning: The following directories already exist:');
    if (capturesExists) console.log(`  - ${capturesDir}`);
    if (markdownExists) console.log(`  - ${markdownDir}`);
    console.log();

    if (!options.force) {
      const confirmed = await askConfirmation('Files in these directories may be overwritten. Continue?');
      if (!confirmed) {
        console.log('Operation cancelled.');
        process.exit(0);
      }
      console.log();
    } else {
      console.log('Force mode enabled, continuing without confirmation.');
      console.log();
    }
  }

  // Launch browser
  const browser = await chromium.launch({
    headless: true
  });

  // Set global browser for cleanup
  globalBrowser = browser;

  // Start periodic memory monitoring
  const memoryMonitor = setInterval(() => {
    const { usedMB, totalMB } = checkMemoryUsage();
    if (usedMB > 500) {
      console.log(`📊 Memory usage: ${usedMB}MB / ${totalMB}MB`);
    }
  }, 30000); // Check every 30 seconds

  try {
    // Check if URL is a sitemap
    const isSitemap = url.toLowerCase().includes('sitemap.xml') ||
                      url.toLowerCase().endsWith('.xml');

    if (isSitemap) {
      console.log('Detected sitemap.xml, fetching all URLs...');

      // Fetch sitemap with retry logic
      const page = await browser.newPage();
      const xmlContent = await retryOperation(async () => {
        const response = await page.goto(url, {
          waitUntil: 'networkidle',
          timeout: 60000
        });
        return await response.text();
      });
      await page.close();

      // Parse sitemap
      const urls = await parseSitemap(xmlContent);
      console.log(`Found ${urls.length} URLs in sitemap`);
      console.log();

      // Create README.md
      await createReadme(outputDir, url, devicesToCapture, true, urls);

      // Process URLs concurrently for all devices
      await processUrlsConcurrently(urls, browser, outputDir, devicesToCapture, concurrentLimit);
    } else {
      // Create README.md
      await createReadme(outputDir, url, devicesToCapture, false);

      // Single page capture for all devices
      for (let i = 0; i < devicesToCapture.length; i++) {
        const deviceType = devicesToCapture[i];
        console.log(`Capturing ${deviceType} size...`);
        const page = await browser.newPage();
        await page.setViewportSize(deviceConfigs[deviceType]);
        await capturePage(page, url, outputDir, deviceType);
        await page.close();
        
        // Wait for interval between device captures if custom interval is set
        if (requestInterval !== 1 && i < devicesToCapture.length - 1) {
          await new Promise(resolve => setTimeout(resolve, requestInterval * 1000));
        }
      }
    }

    console.log('Capture completed successfully!');

  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    // Stop memory monitoring
    if (memoryMonitor) {
      clearInterval(memoryMonitor);
    }

    // Clean up browser resources
    if (browser) {
      try {
        await browser.close();
        globalBrowser = null;
        console.log('Browser resources cleaned up');
      } catch (error) {
        console.error('Error cleaning up browser:', error.message);
      }
    }
  }
}

// Run main function
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
