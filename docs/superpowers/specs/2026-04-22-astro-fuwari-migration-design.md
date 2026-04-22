# Astro Fuwari 博客迁移设计

## 背景

将现有 Docsify 基础的知识库站点迁移到 Astro + Fuwari 主题，获得主题切换、适度动效和更好的博客体验。

## 技术选型

- **框架**: Astro（静态站点生成器）
- **主题**: [Fuwari](https://github.com/saicaca/fuwari)（GitHub 4,462 stars）
- **组件**: Svelte + Astro
- **样式**: TailwindCSS
- **动效**: Swup 页面过渡、滚动渐入、hover 微交互

选择 Fuwari 的原因：内置中文 UI、三模式主题切换（亮色/暗色/跟随系统）、适度动效、迁移成本低。

## 站点配置

```typescript
// src/config.ts
export const siteConfig = {
  title: "starzn-学习笔记",
  subtitle: "技术碎碎念",
  lang: "zh_CN",
  themeColor: {
    hue: 210,         // 蓝色系
    fixed: false,     // 允许访客自选主题色
  },
  toc: {
    enable: true,
    depth: 2,
  },
  banner: { enable: false },
};
```

## 目录结构

```
src/content/posts/
├── prompt-engineering/
│   ├── 2-模型是什么.md
│   ├── 3-理解大模型.md
│   ├── 4-9-提示词工程.md
│   ├── 附录1-通义AI提示词库.md
│   └── 附录2-LLM工具与Agent.md
└── learn-cc-blogs/
    ├── s01-agent-loop.md
    ├── s02-tool-use.md
    ├── s03-todo-write.md
    ├── s04-subagent.md
    ├── s05-skill-loading.md
    ├── s06-context-compact.md
    ├── s07-task-system.md
    ├── s08-background-tasks.md
    ├── s09-agent-teams.md
    ├── s10-team-protocols.md
    ├── s11-autonomous-agents.md
    └── s12-worktree-task-isolation.md
```

## 文章 Frontmatter

每篇迁移文章添加如下 frontmatter（具体 title/published/description/tags 各不相同）：

```yaml
---
title: 模型是什么
published: 2025-01-15
description: "从 Agent 视角理解模型的本质"
tags: [LLM, 模型]
category: prompt-engineering
lang: zh_CN
---
```

- `category` 值：`prompt-engineering` 或 `learn-cc-blogs`
- `lang` 统一为 `zh_CN`
- 文件名从中文改为英文短横线格式

## 部署改造

`.github/workflows/deploy.yml` 从纯 `git pull` 改为构建流程：

```bash
cd /home/starzn/front-practice-samples
git fetch origin main
git reset --hard origin/main
npm install
npm run build
```

服务器 nginx 指向 `dist/` 目录提供静态文件服务。

## 迁移步骤

1. 从 Fuwari 模板初始化新项目结构
2. 配置 `src/config.ts`（中文、标题、主题色）
3. 迁移 17 篇文章，添加 frontmatter，文件名改为英文
4. 清理旧 Docsify 文件（`docs/index.html`、`_sidebar.md`、`.nojekyll` 等）
5. 更新 `.github/workflows/deploy.yml`
6. 更新 `CLAUDE.md`
