# Astro Fuwari 博客迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有 Docsify 站点迁移到 Astro + Fuwari 主题，获得主题切换、适度动效和博客功能。

**Architecture:** 基于 Fuwari 模板初始化项目，迁移 17 篇 Markdown 文章（添加 frontmatter、文件名改英文），配置中文和蓝色主题色，更新部署流程。

**Tech Stack:** Astro 5, Fuwari 主题 (Svelte + TailwindCSS), Swup 页面过渡, Pagefind 搜索, pnpm

---

## 文件变更总览

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 创建 | `package.json`, `astro.config.mjs`, `tsconfig.json`, `tailwind.config.cjs`, `postcss.config.mjs`, `svelte.config.js`, `biome.json`, `pagefind.yml`, `pnpm-lock.yaml` | Fuwari 项目文件 |
| 创建 | `src/config.ts` | 站点配置 |
| 创建 | `src/content/config.ts` | Content Collection schema |
| 创建 | `src/content/posts/prompt-engineering/*.md` | 5 篇提示词工程文章 |
| 创建 | `src/content/posts/learn-cc-blogs/*.md` | 12 篇 Claude Code 学习记录 |
| 创建 | `src/content/spec/about.md` | 关于页面 |
| 创建 | `src/` 下其他目录（components, layouts, pages, i18n, plugins, styles, utils, etc.） | Fuwari 模板文件 |
| 创建 | `public/` | 静态资源 |
| 创建 | `scripts/new-post.js` | 新文章脚手架脚本 |
| 修改 | `.github/workflows/deploy.yml` | 加 npm build 步骤 |
| 修改 | `CLAUDE.md` | 更新开发说明 |
| 删除 | `docs/index.html`, `docs/_sidebar.md`, `docs/.nojekyll`, `docs/README.md`, `docs/favicon.svg`, `docs/robots.txt`, `docs/sitemap.xml` | Docsify 文件 |
| 删除 | `docs/*.md`, `docs/learn-cc-blogs/*.md` | 已迁移的旧文章 |
| 保留 | `docs/superpowers/` | 设计文档和计划 |

---

### Task 1: 克隆 Fuwari 模板并初始化项目

**Files:**
- Create: 项目根目录下所有 Fuwari 模板文件

- [ ] **Step 1: 在临时目录克隆 Fuwari 模板**

```bash
cd /tmp
git clone --depth 1 https://github.com/saicaca/fuwari.git fuwari-template
```

- [ ] **Step 2: 将模板文件复制到项目根目录**

将 Fuwari 的所有文件复制到 `front-practice-samples/`，排除 `.git` 目录和默认示例文章。保留现有项目中的 `.github/`、`.gitignore`、`CLAUDE.md`、`docs/superpowers/`。

```bash
cd /Users/venus/Desktop/front-practice-samples
# 复制模板文件（排除 .git, 默认 posts, README 等）
rsync -av --exclude='.git' --exclude='src/content/posts/*.md' --exclude='src/content/posts/guide/' --exclude='src/content/spec/about.md' --exclude='README.md' --exclude='LICENSE' --exclude='CONTRIBUTING.md' --exclude='docs/' /tmp/fuwari-template/ .
```

- [ ] **Step 3: 安装依赖**

```bash
pnpm install
```

- [ ] **Step 4: 验证开发服务器能启动**

```bash
pnpm dev
```

在浏览器访问 `http://localhost:4321`，确认 Fuwari 默认页面正常显示。

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "feat: 初始化 Astro Fuwari 项目结构"
```

---

### Task 2: 配置站点

**Files:**
- Modify: `src/config.ts`

- [ ] **Step 1: 修改 `src/config.ts`**

将配置改为：

```typescript
import type {
  NavBarConfig,
  ProfileConfig,
  SiteConfig,
  LicenseConfig,
} from "./types/config";
import { LinkPreset } from "./constants/link-presets";
import IconSvelte from "astro-icon/components/Svelte.astro";

export const siteConfig: SiteConfig = {
  title: "starzn-学习笔记",
  subtitle: "技术碎碎念",
  lang: "zh_CN",
  themeColor: {
    hue: 210,
    fixed: false,
  },
  banner: {
    enable: false,
  },
  toc: {
    enable: true,
    depth: 2,
  },
  favicon: [
    { src: "/favicon/icon.png", theme: "light", sizes: "32x32" },
    { src: "/favicon/dark-icon.png", theme: "dark", sizes: "32x32" },
  ],
};

export const navBarConfig: NavBarConfig = [
  {
    preset: LinkPreset.Home,
  },
  {
    preset: LinkPreset.Archive,
  },
  {
    preset: LinkPreset.About,
  },
];

export const profileConfig: ProfileConfig = {
  avatar: "/assets/images/demo-avatar.png",
  name: "starzn",
  bio: "技术碎碎念",
  links: [],
};

export const licenseConfig: LicenseConfig = {
  enable: false,
};
```

注意：保留模板中已有的 `expressiveCodeConfig` 配置不变。

- [ ] **Step 2: 修改 `astro.config.mjs` 中的 `site` 字段**

将 `site` 改为实际域名：

```javascript
site: "https://starzn.xyz/",
```

- [ ] **Step 3: 创建关于页面**

编辑 `src/content/spec/about.md`：

```markdown
---
title: 关于
---

## starzn-学习笔记

记录技术学习过程中的点滴，包括提示词工程、大模型、AI 工具等话题。
```

- [ ] **Step 4: 验证配置生效**

```bash
pnpm dev
```

确认站点标题显示为"starzn-学习笔记"，UI 为中文，主题色为蓝色系。

- [ ] **Step 5: 提交**

```bash
git add src/config.ts astro.config.mjs src/content/spec/about.md
git commit -m "feat: 配置站点标题、中文语言和蓝色主题色"
```

---

### Task 3: 迁移 prompt-engineering 文章（5 篇）

**Files:**
- Create: `src/content/posts/prompt-engineering/2-what-is-a-model.md`
- Create: `src/content/posts/prompt-engineering/3-understanding-llm-parameters.md`
- Create: `src/content/posts/prompt-engineering/4-9-prompt-engineering-techniques.md`
- Create: `src/content/posts/prompt-engineering/appendix-1-tongyi-ai-prompt-library.md`
- Create: `src/content/posts/prompt-engineering/appendix-2-llm-tools-and-agent-concepts.md`

对每篇文章：读取原文 → 添加 frontmatter → 写入新路径。

- [ ] **Step 1: 迁移第 1 篇 — 模型是什么**

读取 `docs/2.模型是什么.md`，在文件头部插入 frontmatter，写入 `src/content/posts/prompt-engineering/2-what-is-a-model.md`：

```yaml
---
title: "模型是什么"
published: 2025-01-15
description: "深入解释 AI 模型的本质，探讨 Agent 与模型的关系，梳理 Agent 概念的历史演变。"
tags: [AI模型, Agent, 深度学习, Transformer]
category: prompt-engineering
lang: zh_CN
---
```

- [ ] **Step 2: 迁移第 2 篇 — 理解大模型**

读取 `docs/3.理解大模型.md`，写入 `src/content/posts/prompt-engineering/3-understanding-llm-parameters.md`：

```yaml
---
title: "理解大模型"
published: 2025-01-20
description: "整理控制 AI 文本生成的核心参数：Temperature、Top-p、Frequency Penalty 和 Presence Penalty。"
tags: [大模型, Temperature, Top-p, 参数调优]
category: prompt-engineering
lang: zh_CN
---
```

- [ ] **Step 3: 迁移第 3 篇 — 提示词工程**

读取 `docs/4-9.提示词工程-模型-技巧.md`，写入 `src/content/posts/prompt-engineering/4-9-prompt-engineering-techniques.md`：

```yaml
---
title: "提示词工程"
published: 2025-02-01
description: "提示词工程概论，介绍四类提示词及如何优化输入提升模型输出质量。"
tags: [提示词工程, Prompt, System Prompt, 提示词优化]
category: prompt-engineering
lang: zh_CN
---
```

- [ ] **Step 4: 迁移第 4 篇 — 通义AI提示词库**

读取 `docs/附录1-通义AI完整提示词库.md`，写入 `src/content/posts/prompt-engineering/appendix-1-tongyi-ai-prompt-library.md`：

```yaml
---
title: "通义AI提示词完整库"
published: 2025-02-10
description: "收录通义AI与 LangGPT 社区共创的全部 42 条实用提示词，涵盖写作、翻译等场景。"
tags: [提示词库, 通义AI, LangGPT, Prompt模板]
category: prompt-engineering
lang: zh_CN
---
```

- [ ] **Step 5: 迁移第 5 篇 — LLM工具与Agent概念**

读取 `docs/附录2-LLM工具使用与Agent相关概念笔记.md`，写入 `src/content/posts/prompt-engineering/appendix-2-llm-tools-and-agent-concepts.md`：

```yaml
---
title: "LLM 工具使用与 Agent 相关概念笔记"
published: 2025-02-15
description: "系统辨析 ReAct、Chain-of-Thought、Tool Use、Function Calling、MCP 等 Agent 相关概念。"
tags: [ReAct, Function Calling, MCP, Agent]
category: prompt-engineering
lang: zh_CN
---
```

- [ ] **Step 6: 验证文章在本地可见**

```bash
pnpm dev
```

在浏览器访问首页，确认 5 篇文章出现在文章列表中，标题和标签正确显示。

- [ ] **Step 7: 提交**

```bash
git add src/content/posts/prompt-engineering/
git commit -m "docs: 迁移提示词工程系列文章"
```

---

### Task 4: 迁移 learn-cc-blogs 文章（12 篇）

**Files:**
- Create: `src/content/posts/learn-cc-blogs/s01-agent-loop.md`
- Create: `src/content/posts/learn-cc-blogs/s02-tool-use.md`
- Create: `src/content/posts/learn-cc-blogs/s03-todo-write.md`
- Create: `src/content/posts/learn-cc-blogs/s04-subagent.md`
- Create: `src/content/posts/learn-cc-blogs/s05-skill-loading.md`
- Create: `src/content/posts/learn-cc-blogs/s06-context-compact.md`
- Create: `src/content/posts/learn-cc-blogs/s07-task-system.md`
- Create: `src/content/posts/learn-cc-blogs/s08-background-tasks.md`
- Create: `src/content/posts/learn-cc-blogs/s09-agent-teams.md`
- Create: `src/content/posts/learn-cc-blogs/s10-team-protocols.md`
- Create: `src/content/posts/learn-cc-blogs/s11-autonomous-agents.md`
- Create: `src/content/posts/learn-cc-blogs/s12-worktree-task-isolation.md`

每篇文章：读取原文 → 添加 frontmatter → 文件名改为英文 → 写入新路径。

- [ ] **Step 1: 迁移 s01-s04**

| 源文件 | 目标文件 | title | tags |
|--------|---------|-------|------|
| `docs/learn-cc-blogs/s01_agent_loop_学习记录.md` | `s01-agent-loop.md` | "s01 Agent Loop 学习记录" | Agent Loop, Anthropic API, tool_use, Python |
| `docs/learn-cc-blogs/s02_tool_use_学习记录.md` | `s02-tool-use.md` | "s02 Tool Use 学习记录" | Tool Use, 路径安全, 文件读取, Python |
| `docs/learn-cc-blogs/s03_todo_write_学习记录.md` | `s03-todo-write.md` | "s03 Todo Write 学习记录" | TodoManager, content block, API规范, 状态管理 |
| `docs/learn-cc-blogs/s04_subagent_学习记录.md` | `s04-subagent.md` | "s04 Subagent 学习记录" | SubAgent, 循环安全上限, 工具Schema, JSON日志 |

每篇 frontmatter 模板（以 s01 为例）：

```yaml
---
title: "s01 Agent Loop 学习记录"
published: 2025-03-01
description: "最小可运行的 AI Agent Loop 示例学习笔记，解析核心循环流程。"
tags: [Agent Loop, Anthropic API, tool_use, Python]
category: learn-cc-blogs
lang: zh_CN
---
```

s01 published: `2025-03-01`，后续每篇间隔约 2 天递增（s02: `2025-03-03`，s03: `2025-03-05`，s04: `2025-03-07`）。

- [ ] **Step 2: 迁移 s05-s08**

| 源文件 | 目标文件 | title | tags | published |
|--------|---------|-------|------|-----------|
| `s05_skill_loading_学习记录.md` | `s05-skill-loading.md` | "s05 Skill Loading 学习记录" | Skill加载, pathlib, front matter, 递归查找 | 2025-03-09 |
| `s06_context_compact_学习记录.md` | `s06-context-compact.md` | "s06 Context Compact 学习记录" | 上下文压缩, token控制, 长会话, 分层压缩 | 2025-03-11 |
| `s07_task_system_学习记录.md` | `s07-task-system.md` | "s07 Task System 学习记录" | 任务系统, JSON, 文件解析, 任务ID | 2025-03-13 |
| `s08_background_tasks_学习记录.md` | `s08-background-tasks.md` | "s08 Background Tasks 学习记录" | 后台任务, threading, 互斥锁, 通知队列 | 2025-03-15 |

- [ ] **Step 3: 迁移 s09-s12**

| 源文件 | 目标文件 | title | tags | published |
|--------|---------|-------|------|-----------|
| `s09_agent_teams_学习记录.md` | `s09-agent-teams.md` | "s09 Agent Teams 学习记录" | Agent团队, JSONL, 消息传递, 文件通信 | 2025-03-17 |
| `s10_team_protocols_学习记录.md` | `s10-team-protocols.md` | "s10 Team Protocols 学习记录" | 团队协议, shutdown, 状态确认, 消息总线 | 2025-03-19 |
| `s11_autonomous_agents_学习记录.md` | `s11-autonomous-agents.md` | "s11 Autonomous Agents 学习记录" | 自主代理, 生命周期, idle轮询, 任务恢复 | 2025-03-21 |
| `s12_worktree_task_isolation_学习记录.md` | `s12-worktree-task-isolation.md` | "s12 Worktree 任务隔离学习记录" | Worktree, Git, EventBus, 任务隔离 | 2025-03-23 |

- [ ] **Step 4: 验证全部文章**

```bash
pnpm dev
```

确认首页显示全部 17 篇文章（5 + 12），标签页和归档页正常工作。

- [ ] **Step 5: 提交**

```bash
git add src/content/posts/learn-cc-blogs/
git commit -m "docs: 迁移 Claude Code 学习记录系列文章"
```

---

### Task 5: 清理旧 Docsify 文件

**Files:**
- Delete: `docs/index.html`
- Delete: `docs/_sidebar.md`
- Delete: `docs/.nojekyll`
- Delete: `docs/README.md`
- Delete: `docs/favicon.svg`
- Delete: `docs/robots.txt`
- Delete: `docs/sitemap.xml`
- Delete: `docs/2.模型是什么.md`
- Delete: `docs/3.理解大模型.md`
- Delete: `docs/4-9.提示词工程-模型-技巧.md`
- Delete: `docs/附录1-通义AI完整提示词库.md`
- Delete: `docs/附录2-LLM工具使用与Agent相关概念笔记.md`
- Delete: `docs/learn-cc-blogs/` 整个目录

保留 `docs/superpowers/` 目录（设计文档和计划）。

- [ ] **Step 1: 删除旧 Docsify 文件和已迁移文章**

```bash
cd /Users/venus/Desktop/front-practice-samples
rm docs/index.html docs/_sidebar.md docs/.nojekyll docs/README.md docs/favicon.svg docs/robots.txt docs/sitemap.xml
rm docs/2.模型是什么.md docs/3.理解大模型.md docs/4-9.提示词工程-模型-技巧.md "docs/附录1-通义AI完整提示词库.md" "docs/附录2-LLM工具使用与Agent相关概念笔记.md"
rm -rf docs/learn-cc-blogs/
```

- [ ] **Step 2: 确认 `docs/superpowers/` 仍存在**

```bash
ls docs/superpowers/specs/ docs/superpowers/plans/
```

- [ ] **Step 3: 提交**

```bash
git add -A
git commit -m "chore: 清理旧 Docsify 文件"
```

---

### Task 6: 更新部署流程

**Files:**
- Modify: `.github/workflows/deploy.yml`

- [ ] **Step 1: 更新 deploy.yml**

将文件内容改为：

```yaml
name: Deploy to server

on:
  push:
    branches: [ "main" ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH (build on server)
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            set -e
            cd /home/starzn/front-practice-samples
            git fetch origin main
            git reset --hard origin/main
            npm install
            npm run build
```

注意：服务器上需要预装 Node.js 和 pnpm。如果服务器用 pnpm，将 `npm install` 改为 `pnpm install`，`npm run build` 改为 `pnpm build`。

- [ ] **Step 2: 提交**

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: 更新部署流程添加 npm build 步骤"
```

---

### Task 7: 更新 CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: 重写 CLAUDE.md**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

基于 Astro + Fuwari 主题的个人技术博客，内容为中文 (zh-CN)。部署在 `https://starzn.xyz/`。

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

推送到 `main` 分支触发 GitHub Actions，SSH 到服务器执行 `git fetch && npm install && npm run build`。Nginx 指向 `dist/` 目录。

## Conventions

- Commit messages 使用 conventional commit 前缀 + 中文描述
- 文章文件名使用英文短横线格式
- 内容语言为中文 (zh-CN)
- 包管理器为 pnpm
```

- [ ] **Step 2: 提交**

```bash
git add CLAUDE.md
git commit -m "docs: 更新 CLAUDE.md 为 Astro Fuwari 项目"
```

---

### Task 8: 本地验证并修复问题

- [ ] **Step 1: 完整构建测试**

```bash
pnpm build
```

确认构建成功无报错，`dist/` 目录生成。

- [ ] **Step 2: 预览构建结果**

```bash
pnpm preview
```

在浏览器中检查：
- 首页显示 17 篇文章
- 亮色/暗色/跟随系统切换正常
- 文章详情页内容正确渲染（中文、代码块、表格）
- 标签页和归档页正常
- 搜索功能正常
- 页面过渡动画流畅

- [ ] **Step 3: 修复发现的问题（如有）**

根据验证结果修复任何渲染或配置问题。

- [ ] **Step 4: 提交修复**

```bash
git add -A
git commit -m "fix: 修复迁移验证中发现的问题"
```

---

### Task 9: 最终提交

- [ ] **Step 1: 检查 git 状态**

```bash
git status
git log --oneline -10
```

确认所有变更已提交，无遗漏文件。

- [ ] **Step 2: 确认 `.gitignore` 覆盖 `dist/` 和 `node_modules/`**

现有 `.gitignore` 已包含 `node_modules/` 和 `dist/`，需确认无遗漏。如有需要，追加：

```
# Astro
.astro/
```

- [ ] **Step 3: 推送到远程（需用户确认）**

```bash
git push origin main
```
