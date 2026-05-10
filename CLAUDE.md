# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

基于 Astro + Fuwari 主题的个人技术博客，内容为中文 (zh-CN)。部署在 https://starzn.xyz/。

## Commands

```bash
pnpm dev          # 启动开发服务器 (localhost:4321)
pnpm build        # 构建生产版本（含 Pagefind 搜索索引）
pnpm preview      # 预览构建结果
pnpm new-post     # 创建新文章脚手架
```

## Architecture

```
src/
  config.ts            — 站点配置（标题、语言 zh_CN、主题色 hue:210、导航栏、个人信息）
  content/
    config.ts          — Content Collection Zod schema
    posts/             — 博客文章 Markdown
      prompt-engineering/  — 提示词工程系列 (5 篇)
      learn-cc-blogs/      — Claude Code 学习记录 (12 篇)
    spec/
      about.md         — 关于页面
  i18n/languages/zh_CN.ts  — 中文 UI 翻译
  components/          — Svelte + Astro 组件
  pages/               — 文件路由（首页、归档、标签、搜索、RSS）
  plugins/             — Remark/Rehype Markdown 插件
  styles/              — 全局样式 + Swup 页面过渡动画
public/
  favicon/             — 亮色/暗色双 favicon
```

### 添加新文章

在 `src/content/posts/` 下创建 `.md` 文件，添加 frontmatter：

```yaml
---
title: 文章标题
published: 2026-04-22
description: "简短描述"
tags: [标签1, 标签2]
category: 分类名
lang: zh_CN
---
```

### 站点配置

所有关键配置在 `src/config.ts`：`siteConfig`（标题、语言、主题色）、`navBarConfig`（导航栏）、`profileConfig`（个人信息）。

## Deployment

推送到 `main` 分支触发 `.github/workflows/deploy.yml`，通过 SSH 连接阿里云服务器（用户 `deploy`），在 `/home/deploy/front-practice-samples` 目录下执行 `git fetch && pnpm install && pnpm build`。构建产物输出到 `dist/`，Nginx 指向该目录提供静态文件服务。

服务器环境：Node.js 24, pnpm 9.14.4

## Known Issues

- `src/styles/markdown.css` 中 `@apply link` 已展开为内联样式，因为 Tailwind v3.4.19 跨文件 `@apply` 自定义类会构建失败（Fuwari 模板本身的 bug）

## Conventions

- Commit messages 使用 conventional commit 前缀 + 中文描述
- 文章文件名使用英文短横线格式
- 内容语言为中文 (zh-CN)
- 包管理器为 pnpm
