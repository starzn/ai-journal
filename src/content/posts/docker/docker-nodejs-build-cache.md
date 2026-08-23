---
title: "Node.js Dockerfile 如何用好构建缓存"
published: 2026-06-11
description: "通过依赖文件分层、锁文件和非 root 用户，让 Node.js 镜像更快、更稳。"
tags: [Docker, Node.js, Dockerfile, 构建缓存]
category: Docker
draft: false
lang: zh_CN
---

# Node.js Dockerfile 如何用好构建缓存

Docker 会按指令生成镜像层。某一层输入变化后，这一层及其后续层都需要重新执行。因此，变化少的文件应先复制。

```dockerfile
FROM node:22-alpine
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

如果先 `COPY . .`，修改一行源码也会让安装依赖层失效。先复制依赖清单，只有清单或锁文件变化时才重新安装。

## `RUN` 与 `CMD`

- `RUN` 在构建镜像时执行，例如安装依赖、编译代码；
- `CMD` 在容器启动时提供默认命令；
- `EXPOSE` 只声明监听端口，不会发布宿主机端口。

应用必须监听 `0.0.0.0`，只监听 `127.0.0.1` 时，即使配置 `-p`，容器外也无法访问。

## 别忘了 `.dockerignore`

```text
node_modules
.git
coverage
*.log
.env*
```

宿主机的 `node_modules` 既会放大构建上下文，也可能包含与容器平台不兼容的原生二进制。依赖应在镜像内按锁文件重新安装。

参考：[Optimize cache usage](https://docs.docker.com/build/cache/optimize/)
