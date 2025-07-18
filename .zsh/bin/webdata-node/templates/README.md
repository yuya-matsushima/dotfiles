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
├── captures/           # Screenshot images (PNG)
{{DEVICE_TREE}}
└── markdown/           # Text content (Markdown)
```

## File Naming Convention

- Screenshots: `captures/{device}/{path}/{filename}.png`
- Markdown: `markdown/{path}/{filename}.md`
- Path structure follows the URL structure
- Root pages (`/`) are saved as `index`

## Usage for LLM

This directory contains website data captured for LLM processing:

1. **Screenshots**: Visual representation of pages in different device sizes
2. **Markdown**: Clean text content extracted from HTML
3. **Structure**: Organized by URL path for easy navigation

You can reference screenshots and markdown files to understand the website structure and content. The markdown files contain the main textual content, while screenshots provide visual context for layout and design elements.

## Notes

- Screenshots are taken with full page height
- Markdown content has scripts and styles removed
- File paths are sanitized for filesystem compatibility
- Generated automatically by webdata tool