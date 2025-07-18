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
  .option('-o, --output <directory>', 'output directory', './web-data')
  .option('-f, --force', 'skip overwrite confirmation')
  .parse();

const options = program.opts();
const url = program.args[0];
const outputDir = options.output;

// Utility function to create directory if it doesn't exist
async function ensureDir(dir) {
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch (error) {
    console.error(`Error creating directory ${dir}:`, error);
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

// Capture single page
async function capturePage(page, url, outputDir) {
  console.log(`Capturing: ${url}`);
  
  try {
    // Navigate to the page
    await page.goto(url, { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    // Wait a bit for dynamic content
    await page.waitForTimeout(2000);
    
    // Get the file path
    const filePath = urlToFilePath(url);
    const fileName = path.basename(filePath) || 'index';
    const dirPath = path.dirname(filePath);
    
    // Create directories
    const captureDir = path.join(outputDir, 'captures', dirPath);
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
    
    // Remove script and style tags before conversion
    const cleanedHtml = htmlContent
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
      .replace(/<noscript\b[^<]*(?:(?!<\/noscript>)<[^<]*)*<\/noscript>/gi, '');
    
    const markdown = turndownService.turndown(cleanedHtml);
    
    // Save markdown
    const markdownPath = path.join(markdownDir, `${fileName}.md`);
    await fs.writeFile(markdownPath, markdown, 'utf8');
    console.log(`  Markdown saved: ${markdownPath}`);
    
  } catch (error) {
    console.error(`  Error capturing ${url}:`, error.message);
  }
}

// Main function
async function main() {
  console.log(`Starting webdata capture...`);
  console.log(`URL: ${url}`);
  console.log(`Output directory: ${outputDir}`);
  console.log();
  
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
  
  try {
    const page = await browser.newPage();
    
    // Set viewport
    await page.setViewportSize({ width: 1280, height: 800 });
    
    // Check if URL is a sitemap
    const isSitemap = url.toLowerCase().includes('sitemap.xml') || 
                      url.toLowerCase().endsWith('.xml');
    
    if (isSitemap) {
      console.log('Detected sitemap.xml, fetching all URLs...');
      
      // Fetch sitemap
      const response = await page.goto(url);
      const xmlContent = await response.text();
      
      // Parse sitemap
      const urls = await parseSitemap(xmlContent);
      console.log(`Found ${urls.length} URLs in sitemap`);
      console.log();
      
      // Process each URL
      for (let i = 0; i < urls.length; i++) {
        console.log(`Progress: ${i + 1}/${urls.length}`);
        await capturePage(page, urls[i], outputDir);
        console.log();
      }
    } else {
      // Single page capture
      await capturePage(page, url, outputDir);
    }
    
    console.log('Capture completed successfully!');
    
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

// Run main function
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});