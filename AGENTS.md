# AGENTS.md

本文件是仓库级 AI 协作规范，也是项目工作方式的唯一事实来源。Codex 会直接读取本文件；`CLAUDE.md` 通过导入本文件让 Claude Code 使用同一套规范。如果仓库位于四工程工作区且上级总文档存在，跨项目任务同时参考上级目录的 `ARCHITECTURE.md`、`DEVELOPMENT.md` 和 `DEPLOYMENT.md`。

## 项目概览

- 这是一个基于 Astro 5 和 Fuwari 主题的中文个人技术博客，线上地址为 <https://starzn.xyz/>。
- 站点采用静态生成，交互组件使用 Svelte 5，样式使用 Tailwind CSS、PostCSS 和 Stylus。
- 搜索由 Pagefind 在生产构建后生成，包管理器固定为 pnpm。
- 内容和沟通默认使用简体中文；代码标识符、文件名沿用项目现有英文风格。

## 常用命令

```bash
pnpm install             # 安装依赖
pnpm dev                 # 启动开发服务器：http://localhost:4321
pnpm check               # Astro 诊断
pnpm type-check          # TypeScript 类型检查
pnpm exec biome check src # 只检查，不自动写入
pnpm build               # 生产构建，并生成 Pagefind 索引
pnpm preview             # 预览生产构建
pnpm new-post -- <slug>  # 创建文章脚手架
pnpm format              # 格式化整个 src，会写入文件
pnpm lint                # 检查并修复整个 src，会写入文件
```

`pnpm lint` 和 `pnpm format` 都会修改文件。验证时优先使用不写入的 `pnpm exec biome check <files>`，不要为了检查而改动无关文件。

## 目录与关键入口

```text
src/
  config.ts                 站点、导航、个人信息与许可配置
  content/config.ts         Content Collection schema
  content/posts/            Markdown/MDX 博客文章
  content/spec/about.md     关于页面
  pages/                    Astro 文件路由
  layouts/                  页面布局
  components/               Astro 与 Svelte 组件
  plugins/                  Remark/Rehype 与 Expressive Code 插件
  styles/                   全局、Markdown、过渡与组件样式
  i18n/languages/zh_CN.ts   中文 UI 文案
public/                     原样发布的静态资源
scripts/new-post.js         新文章脚手架
astro.config.mjs            Astro 集成与 Markdown 管线
```

路径别名定义在 `tsconfig.json`，优先使用已有的 `@components/*`、`@assets/*`、`@constants/*`、`@utils/*`、`@i18n/*`、`@layouts/*` 和 `@/*`。

## 工作流程

1. 开始前阅读任务相关文件并检查 `git status`。工作区可能有用户尚未提交的改动，必须保留，不覆盖、不清理。
2. 先确认现有实现、配置和相邻代码的惯例，再做范围最小且完整的修改。不要顺手重构无关区域。
3. 使用 pnpm；不要生成 npm 或 Yarn 锁文件。除非任务确有需要，不新增依赖；新增生产依赖前先说明理由。
4. 修改后先检查变更差异，再按风险运行验证：
   - 仅文案或文章：检查 frontmatter、内部链接和资源路径，通常运行 `pnpm build`。
   - TypeScript、Astro 或 Svelte：对改动文件运行 Biome 检查，再运行 `pnpm check` 或 `pnpm type-check`；涉及构建管线、路由或集成时再运行 `pnpm build`。
   - 样式或界面：除构建检查外，在可用时检查桌面端和移动端的亮色、暗色表现。
5. 交付时用中文简要说明改动、验证结果和仍存在的风险。不要声称没有实际运行过的检查已通过。

## 项目边界

- 本仓库只负责博客内容、静态站点、搜索和自身不可变 Web 镜像。
- 统一域名、TLS 和 Nginx upstream 属于 `starzn-platform`；只有路由契约变化时才需要联动平台仓库。
- 生产不连接 PostgreSQL，不要为了博客功能引入共享数据库依赖。

## 内容规范

- 新文章放在 `src/content/posts/`，文件名使用英文小写短横线格式；优先用 `pnpm new-post -- <slug>` 创建。
- 正文使用简体中文，保持技术术语、命令和 API 名称准确；不要在没有来源的情况下编造版本、性能数据或引用。
- frontmatter 以 `src/content/config.ts` 为准。常用格式：

```yaml
---
title: 文章标题
published: 2026-04-22
description: "简短描述"
image: ""
tags: [标签1, 标签2]
category: 分类名
draft: false
lang: zh_CN
---
```

- `published` 和可选的 `updated` 使用 `YYYY-MM-DD`；发布内容默认 `draft: false`、`lang: zh_CN`。
- 文章资源优先放在项目现有资源目录，并沿用相邻文章的引用方式。修改 slug 或路径前检查站内链接、图片和上下篇导航影响。

## 代码约定

- 遵循 `biome.json`：默认使用 Tab 缩进、双引号，并保持导入有序。Astro、Svelte、Stylus 和 CSS 文件优先遵循相邻代码风格。
- 保持 Astro 负责静态结构、Svelte 只承担必要客户端交互的现有边界，避免无意义地增加客户端 JavaScript。
- 站点关键配置集中在 `src/config.ts`；文章 schema 修改集中在 `src/content/config.ts`；Markdown 管线修改集中在 `astro.config.mjs`。
- 保持无障碍与响应式行为：交互元素应可键盘操作，有合适的标签，并兼顾移动端与深色模式。
- 不直接编辑生成物或依赖目录，包括 `node_modules/`、`dist/`、`.astro/`、`.next/`、`out/` 和 `*.tsbuildinfo`。

## 部署与版本控制

- 生产服务器不再从源码构建。`deploy/build-and-push.sh` 在本机干净 worktree 中构建 `linux/amd64` 镜像，推送完整 Git SHA 到 ACR，再推送 `deploy-ai-journal-<SHA>` 标签。
- `.github/workflows/deploy.yml` 只由部署标签或手动 release SHA 触发；它使用固定 Host Key 和受限 SSH Key 调用 `deploy-ai-journal <SHA>`。
- 服务器运行 `/srv/apps/ai-journal/server-deploy.sh`，验证镜像架构、容器健康和 TLS 路由；失败恢复上一镜像，成功后保留当前版本和最近 2 个成功历史版本。
- 发布脚本会推送 ACR 镜像和 Git 标签，只有用户明确授权部署时才能执行。
- 除非用户明确要求，不执行提交、推送、部署、历史重写或破坏性 Git 操作。
- 提交信息使用 Conventional Commits 前缀加中文描述，例如 `docs: 补充 Codex 协作规范`。
- 不提交密钥、令牌、`.env*` 或服务器凭据；日志和示例中也不得暴露敏感信息。

## 已知注意事项

- `src/styles/markdown.css` 中原有的 `@apply link` 已展开为内联样式，因为 Tailwind CSS 3.4.19 跨文件 `@apply` 自定义类会导致构建失败。不要恢复该写法。
