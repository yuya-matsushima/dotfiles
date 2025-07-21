# Website Data Capture

**Generated:** {{TIMESTAMP}}
**Tool:** webdata

## Source Information

**Type:** {{SOURCE_TYPE}}
**URL:** {{SOURCE_URL}}
{{PAGE_COUNT_INFO}}
{{PROCESSING_INFO}}

## Device Configurations

{{DEVICE_LIST}}

## Directory Structure

```
./
├── README.md           # This file
├── sitemap.xml         # Original sitemap.xml (if captured from sitemap)
├── captures/           # Screenshot images (PNG)
{{DEVICE_TREE}}
└── markdown/           # Text content (Markdown)
```

## File Naming Convention

- Screenshots: `captures/{device}/{path}/{filename}.png`
- Markdown: `markdown/{path}/{filename}.md`
- Path structure follows the URL structure
- Root pages (`/`) are saved as `index`

## Markdown File Format

Each markdown file contains:

### YAML Frontmatter
```yaml
---
title: "Page Title"        # Extracted from HTML <title> tag
url: "https://example.com" # Source URL
created: "2025-01-18T12:34:56.789Z" # Capture timestamp
description: "Page description"      # Extracted from <meta name="description"> (optional)
keywords: "keyword1, keyword2"      # Extracted from <meta name="keywords"> (optional)
---
```

### Content
- Clean markdown content converted from HTML
- Scripts, styles, and title tags removed
- Preserves text content and structure
- Images and links maintained with proper formatting

## Usage for LLM

This directory contains website data captured for LLM processing:

1. **Screenshots**: Visual representation of pages in different device sizes
2. **Markdown**: Clean text content extracted from HTML
3. **Structure**: Organized by URL path for easy navigation
4. **Sitemap**: Original sitemap.xml file (if source was a sitemap) containing all page URLs

You can reference screenshots and markdown files to understand the website structure and content. The markdown files contain the main textual content, while screenshots provide visual context for layout and design elements. When analyzing a site captured from sitemap.xml, you can use the sitemap.xml file to understand the complete site structure and available pages.

## Notes

- Screenshots are taken with full page height
- Markdown content has scripts and styles removed
- File paths are sanitized for filesystem compatibility
- Generated automatically by webdata tool
