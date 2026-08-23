---
title: "Docker 镜像、容器与构建上下文"
published: 2026-05-28
description: "用一条构建链路分清镜像、容器、Dockerfile 和构建上下文。"
tags: [Docker, Dockerfile, BuildKit, 容器]
category: Docker
draft: false
lang: zh_CN
---

# Docker 镜像、容器与构建上下文

理解 Docker，可以先记住一条链路：

```text
Dockerfile + 构建上下文 → 镜像 → 容器
```

- Dockerfile 描述怎样构建；
- 镜像是只读模板；
- 容器是镜像的运行实例，并额外拥有一个可写层；
- Registry 负责保存和分发镜像。

## 构建上下文不是 Dockerfile 所在目录

`docker build` 最后的路径才是构建上下文：

```bash
docker build -t demo-app:1.0 -f docker/Dockerfile .
#                                                   ↑ 当前目录是上下文
```

Dockerfile 中 `COPY` 的源文件必须位于这个范围内：

```dockerfile
FROM nginx:alpine
COPY public/index.html /usr/share/nginx/html/index.html
```

即使写宿主机绝对路径，`COPY` 也不能越出上下文。遇到 `not found` 时，应先检查构建命令最后的路径，而不是只检查文件是否存在。

## `.dockerignore` 是构建边界的一部分

构建上下文过大，会拖慢传输并增加误带敏感文件的风险：

```text
node_modules
.git
*.log
.env*
```

被排除的文件同样无法被 `COPY`。因此，合理做法是把上下文缩到项目所需范围，并明确排除凭据、缓存和依赖目录。

## 最后记住两点

1. `EXPOSE 80` 只是声明端口，不会把端口发布到宿主机；运行时仍需 `-p` 或 Compose 的 `ports`。
2. 标签是可移动的名字，`latest` 也不等于“永远最新”。需要可复现部署时，应使用明确版本或镜像摘要。

参考：[Docker Build context](https://docs.docker.com/build/concepts/context/)、[Dockerfile overview](https://docs.docker.com/build/concepts/dockerfile/)
