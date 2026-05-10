# starzn-博客

基于 Astro + Fuwari 主题的个人技术博客，部署在 [starzn.xyz](https://starzn.xyz/)。

## 技术栈

| 类别 | 技术 | 说明 |
|------|------|------|
| 框架 | Astro 5 (SSG) | 静态站点生成，文件路由 |
| 主题 | starzn | 内置中文 UI、oklch 色彩系统 |
| 交互组件 | Svelte 5 | 搜索、归档面板、主题切换、显示设置 |
| 样式 | Tailwind CSS 3.4 + PostCSS + Stylus | class 切换暗色模式 |
| 页面过渡 | Swup | SPA 级导航动画 + 缓存 |
| 搜索 | Pagefind | 构建后生成静态搜索索引 |
| 代码高亮 | Expressive Code | github-dark 主题，自定义复制按钮和语言标签 |
| 数学公式 | KaTeX (remark-math + rehype-katex) | LaTeX 渲染 |
| 图片灯箱 | PhotoSwipe | 点击放大 |
| 滚动条 | OverlayScrollbars | 自定义滚动条样式 |
| 图标 | astro-icon | FontAwesome 6 + Material Symbols |
| 格式化/检查 | Biome | 统一代码风格 |
| 包管理 | pnpm | |
| 部署 | GitHub Actions → SSH → 阿里云 | 推送 main 分支自动构建 |

## 目录结构

```
front-practice-samples/
├── .github/workflows/deploy.yml   # CI/CD：推送 main → SSH 构建部署
├── astro.config.mjs               # Astro 主配置（集成、Markdown 管线、站点信息）
├── tailwind.config.cjs            # Tailwind 配置（darkMode: class）
├── postcss.config.mjs             # PostCSS（import + nesting + tailwind）
├── svelte.config.js               # Svelte vitePreprocess
├── tsconfig.json                  # TypeScript 路径别名（@components, @utils 等）
├── biome.json                     # Biome 格式化/检查规则
├── pagefind.yml                   # Pagefind 搜索索引配置
├── frontmatter.json               # VS Code Front Matter CMS 扩展配置
├── package.json
└── src/
    ├── config.ts                  # 站点配置入口
    ├── content/
    │   ├── config.ts              # Content Collection Zod schema
    │   ├── posts/                 # 博客文章
    │   │   ├── prompt-engineering/  # 提示词工程系列（5 篇）
    │   │   └── learn-cc-blogs/      # Claude Code（12 篇）
    │   └── spec/
    │       └── about.md           # 关于页面内容
    ├── pages/                     # 文件路由
    │   ├── [...page].astro        # 首页（分页，每页 8 篇）
    │   ├── posts/[...slug].astro  # 文章详情页（含 JSON-LD、上下篇导航）
    │   ├── about.astro            # 关于页
    │   ├── archive.astro          # 归档页（Svelte 时间线）
    │   ├── rss.xml.ts             # RSS 订阅源
    │   └── robots.txt.ts          # 搜索引擎爬虫规则
    ├── layouts/
    │   ├── Layout.astro           # 根布局（HTML shell、meta、主题初始化、Swup/PhotoSwipe/OverlayScrollbars 初始化）
    │   └── MainGridLayout.astro   # 主网格布局（Navbar + Sidebar + Content + TOC + Footer）
    ├── components/
    │   ├── Navbar.astro           # 顶部导航栏
    │   ├── Footer.astro           # 页脚
    │   ├── PostCard.astro         # 文章卡片
    │   ├── PostMeta.astro         # 文章元信息（日期、标签、分类）
    │   ├── PostPage.astro         # 文章列表容器（含分页）
    │   ├── ConfigCarrier.astro    # 配置数据传递到客户端
    │   ├── ArchivePanel.svelte    # 归档时间线面板
    │   ├── Search.svelte          # Pagefind 搜索组件
    │   ├── LightDarkSwitch.svelte # 主题切换按钮
    │   ├── control/               # 控件：分页、返回顶部、按钮
    │   ├── widget/                # 侧边栏组件：Profile、Categories、Tags、TOC、DisplaySettings
    │   └── misc/                  # 工具组件：ImageWrapper、Markdown、License
    ├── plugins/                   # Markdown 处理插件
    │   ├── expressive-code/       # Expressive Code 自定义插件（复制按钮、语言标签）
    │   ├── remark-reading-time.mjs    # 计算阅读时长和字数
    │   ├── remark-excerpt.js          # 提取文章摘要
    │   ├── remark-directive-rehype.js # 自定义指令转换
    │   ├── rehype-component-admonition.mjs  # 提示块（note/tip/warning 等）
    │   └── rehype-component-github-card.mjs # GitHub 仓库卡片嵌入
    ├── styles/
    │   ├── main.css               # 核心样式（.card-base、.link、.btn-*、浮动面板等）
    │   ├── markdown.css            # Markdown 内容样式
    │   ├── markdown-extend.styl   # Markdown 扩展样式（提示块、GitHub 卡片）
    │   ├── variables.styl         # Stylus 变量（颜色、滚动条）
    │   ├── transition.css          # Swup 页面过渡动画
    │   ├── scrollbar.css           # OverlayScrollbars 自定义样式
    │   ├── photoswipe.css          # 图片灯箱样式
    │   └── expressive-code.css     # 代码块样式覆盖
    ├── i18n/                      # 国际化（10 种语言，站点使用 zh_CN）
    ├── constants/                 # 常量（图标定义、链接预设、通用常量）
    ├── utils/                     # 工具函数（内容、日期、设置、URL）
    ├── types/config.ts            # TypeScript 配置类型定义
    ├── assets/images/             # 静态图片（头像、banner）
    ├── global.d.ts                # 全局类型声明
    └── env.d.ts                   # Astro 环境类型
├── public/
│   └── favicon/                  # 亮色/暗色双 favicon（32/128/180/192px）
└── scripts/
    └── new-post.js               # 新文章脚手架脚本
```

## 核心架构说明

### 站点配置

所有关键配置集中在 `src/config.ts`，导出四个配置对象：

- **siteConfig** — 站点标题、副标题、语言（zh_CN）、主题色（hue:210，可变）、banner（关闭）、TOC（开启，深度 2）
- **navBarConfig** — 导航栏链接：首页、归档、关于
- **profileConfig** — 侧边栏个人信息：头像、昵称、简介
- **licenseConfig** — 文章许可声明（已关闭）

### Markdown 处理管线

Astro 的 Markdown 管线在 `astro.config.mjs` 中配置，按顺序处理：

```
Markdown 源文件
  → remark-math          （数学公式语法解析）
  → remark-reading-time  （计算阅读时长）
  → remark-excerpt       （提取摘要）
  → remark-directive     （自定义指令支持）
  → remark-sectionize    （按标题分段）
  → rehype-katex         （LaTeX → HTML 渲染）
  → rehype-slug          （标题生成 id）
  → rehype-components    （GitHub 卡片、提示块组件）
  → rehype-autolink-headings （标题自动锚链接）
  → Expressive Code      （代码块高亮）
→ HTML 输出
```

### 布局体系

```
Layout.astro（根布局）
  └── MainGridLayout.astro（网格布局）
        ├── Navbar
        │   ├── Search (Pagefind)
        │   ├── LightDarkSwitch
        │   ├── NavMenuPanel（移动端菜单）
        │   └── DisplaySettings
        ├── SideBar
        │   ├── Profile
        │   ├── Categories
        │   └── Tags
        ├── 主内容区（文章列表 / 文章详情 / 关于页）
        ├── TOC（目录，仅文章详情页显示）
        ├── BackToTop
        └── Footer
```

### 主题系统

- 使用 oklch 色彩空间，通过 `hue` 值（默认 210 = 蓝色）动态生成整站配色
- 暗色模式通过 `class="dark"` 切换，配合 Tailwind `darkMode: 'class'`
- 防闪烁：`Layout.astro` 中内联脚本在页面渲染前从 `localStorage` 读取主题设置

### 部署流程

```
git push origin main
  → GitHub Actions 触发
  → SSH 连接阿里云服务器
  → git fetch + git reset --hard
  → pnpm install + pnpm build
  → Nginx 指向 dist/ 提供静态文件服务
```

## 常用命令

```bash
pnpm dev          # 启动开发服务器 (localhost:4321)
pnpm build        # 构建生产版本（含 Pagefind 搜索索引）
pnpm preview      # 预览构建结果
pnpm new-post     # 创建新文章脚手架
pnpm lint         # Biome 代码检查
pnpm format       # Biome 格式化
pnpm type-check   # TypeScript 类型检查
```

## 添加新文章

在 `src/content/posts/` 下创建 `.md` 文件：

```yaml
---
title: 文章标题
published: 2026-04-27
description: "简短描述"
tags: [标签1, 标签2]
category: 分类名
lang: zh_CN
---
```

文件名使用英文短横线格式（如 `my-new-post.md`）。
