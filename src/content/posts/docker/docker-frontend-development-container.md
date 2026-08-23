---
title: "用 Docker Compose 搭建前端开发容器"
published: 2026-07-02
description: "源码挂载、依赖隔离和 HMR，是前端开发容器的三个关键点。"
tags: [Docker, Docker Compose, Vite, HMR]
category: Docker
draft: false
lang: zh_CN
---

# 用 Docker Compose 搭建前端开发容器

开发镜像与生产镜像目标不同：开发环境追求源码实时同步和热更新，不必把源码固化进镜像。

```yaml
services:
  web:
    build: .
    ports:
      - "5173:5173"
    volumes:
      - .:/app
      - /app/node_modules
    command: npm run dev -- --host 0.0.0.0
```

这里有三层作用：

1. bind mount 把宿主机源码映射到 `/app`；
2. `/app/node_modules` 使用独立卷，避免宿主机依赖覆盖容器内依赖；
3. 开发服务器监听 `0.0.0.0`，端口映射才能访问。

宿主机和 Linux 容器可能使用不同平台的原生依赖。直接共享 `node_modules` 容易出现 esbuild、sharp 等二进制不兼容问题。

## 什么时候需要重建

- 只改业务源码：通常由 HMR 处理；
- 修改依赖清单或 Dockerfile：重新 build；
- 修改开发服务器配置：通常需要重启进程；
- 怀疑匿名卷里依赖过旧：明确确认后再重建依赖卷。

生产环境不应继续运行开发服务器，而应构建静态产物，再交给精简的 Web Server 镜像托管。

参考：[Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/)、[Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
