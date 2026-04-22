# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Docsify-based static knowledge-base / study blog site, served at `http://starzn.xyz/`. All content is written in Chinese (zh-CN). There is no build system, no package manager, and no application code — the site is pure Markdown rendered client-side by Docsify loaded from CDN.

## Local Development

```bash
# Serve the docs directory locally (requires docsify-cli or any static server)
npx docsify-cli serve docs
# Or use any static file server:
python3 -m http.server 3000 --directory docs
```

There are no build, lint, or test commands. Changes to Markdown files are reflected immediately on refresh.

## Architecture

```
docs/
  index.html        — Docsify SPA shell (config, theme, SEO meta tags)
  _sidebar.md       — Sidebar navigation (must be updated when adding new articles)
  *.md              — Top-level articles (prompt engineering, LLM concepts)
  learn-cc-blogs/   — 12-part Claude Code source code study series
```

- **Docsify config** lives in a `<script>` block inside `docs/index.html` (window.$docsify). Key settings: `loadSidebar: true`, `subMaxLevel: 2`, alias `/.*/_sidebar.md` → `/_sidebar.md` (forces all subdirectories to use the root sidebar).
- **Adding new content**: create a `.md` file in `docs/`, then add an entry to `docs/_sidebar.md` for it to appear in navigation.
- **Claude Code series naming convention**: `sNN_topic_学习记录.md` (zero-padded two-digit number).

## Deployment

Pushing to `main` triggers `.github/workflows/deploy.yml`, which SSHs into the production server and runs `git fetch origin main && git reset --hard origin/main` at `/home/starzn/front-practice-samples`. Deployment is automatic — no manual steps needed.

## Conventions

- Commit messages use conventional commit prefixes with Chinese descriptions: `feat:`, `fix:`, `docs:`, etc.
- All written content is in Chinese (zh-CN).
