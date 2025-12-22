# nmn3m's Blog

A bilingual (English/Arabic) blog built with Hugo, featuring a custom theme with dark mode support.

## Features

- **Custom Hugo Theme**: Clean, minimalist design
- **Bilingual Support**: Content in English and Arabic with RTL support
- **Dark Mode**: Toggle between light and dark themes with localStorage persistence
- **Responsive Design**: Mobile-friendly layout
- **Fast Performance**: Static site generation for optimal speed
- **Automated Deployment**: GitHub Actions workflow for continuous deployment
- **Easy Content Management**: Simple Makefile commands

## Quick Start

### Prerequisites

- Hugo Extended v0.140.0 or later (already included as `./hugo`)
- Git
- Make (optional, but recommended)

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/nmn3m/nmn3m.github.io.git
   cd nmn3m.github.io
   ```

2. **Start the development server**:
   ```bash
   make serve
   # or
   ./hugo server --buildDrafts --buildFuture
   ```

3. **View your site**: Open `http://localhost:1313` in your browser

### Creating Content

#### Create a new English post:
```bash
make new POST="my-new-post"
# or
./hugo new posts/my-new-post.md
```

#### Create a new Arabic post:
```bash
make new-ar POST="my-new-post"
# or
./hugo new posts/my-new-post.ar.md
```

### Building the Site

```bash
make build
# or
./hugo --minify
```

The generated site will be in the `public/` directory.

## Project Structure

```
.
├── content/              # Blog content
│   ├── posts/           # Blog posts
│   └── about/           # About pages
├── themes/custom/       # Custom theme
│   ├── layouts/         # HTML templates
│   │   ├── _default/   # Default layouts
│   │   └── partials/   # Reusable components
│   └── static/          # Static assets
│       ├── css/        # Stylesheets
│       └── js/         # JavaScript files
├── i18n/                # Translations
│   ├── en.toml         # English translations
│   └── ar.toml         # Arabic translations
├── .github/workflows/   # GitHub Actions
│   └── deploy.yml      # Deployment workflow
├── hugo.yaml           # Hugo configuration
├── Makefile            # Build automation
└── README.md           # This file
```

## Deployment

### GitHub Pages

This blog is configured to automatically deploy to GitHub Pages using GitHub Actions.

1. **Enable GitHub Pages**:
   - Go to your repository settings
   - Navigate to "Pages"
   - Set Source to "GitHub Actions"

2. **Push to main branch**:
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

3. The GitHub Action will automatically build and deploy your site

### Manual Deployment

To deploy manually:

```bash
make deploy
```

Then copy the contents of `public/` to your web server.

## Customization

### Site Configuration

Edit `hugo.yaml` to customize:
- Site title and description
- Author information
- Social media links
- Menu items

### Theme Colors

Modify theme colors in `themes/custom/static/css/style.css`:
- Light mode colors: `:root` section
- Dark mode colors: `[data-theme="dark"]` section

### Adding Languages

To add more languages:

1. Add language configuration to `hugo.yaml`
2. Create translation file in `i18n/` (e.g., `fr.toml`)
3. Create content with language suffix (e.g., `post.fr.md`)

## Available Make Commands

- `make help` - Show available commands
- `make serve` - Start development server
- `make build` - Build the site
- `make new POST="title"` - Create new English post
- `make new-ar POST="title"` - Create new Arabic post
- `make clean` - Clean the public directory
- `make deploy` - Build and prepare for deployment

## Writing Posts

Posts use Markdown with YAML frontmatter:

```markdown
---
title: "My Post Title"
date: 2025-12-20T10:00:00Z
draft: false
tags: ["tag1", "tag2"]
author: "nmn3m"
---

Post content here...

<!--more-->

Extended content after the summary...
```

### Frontmatter Fields

- `title`: Post title
- `date`: Publication date
- `draft`: Set to `false` to publish
- `tags`: List of tags
- `author`: Author name

## License

MIT License - feel free to use this theme for your own blog!

## Contributing

Issues and pull requests are welcome!

## Acknowledgments

Inspired by [utam0k.github.io](https://github.com/utam0k/utam0k.github.io)

---

Built with ❤️ using [Hugo](https://gohugo.io/)
