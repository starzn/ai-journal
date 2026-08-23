---
title: "Docker 生产镜像的四个小原则"
published: 2026-07-16
description: "多阶段构建、环境配置、日志和 Compose 分层的生产化清单。"
tags: [Docker, 多阶段构建, 日志, Docker Compose]
category: Docker
draft: false
lang: zh_CN
---

# Docker 生产镜像的四个小原则

从“容器能运行”到“适合长期部署”，通常只差几条清晰的边界。

## 1. 构建工具不要进入运行镜像

静态前端可以用多阶段构建：

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

最终镜像只保留运行所需文件，减少体积和攻击面。

## 2. 配置在运行时注入

镜像应保持环境无关。普通配置使用环境变量；密码、令牌等敏感值使用部署平台的 Secret 机制，不写进 Dockerfile、镜像或 Git。

前端构建变量通常会固化到静态文件中，因此不能把秘密放入前端环境变量。

## 3. 日志写 stdout 和 stderr

容器日志应交给日志驱动收集，再通过 `docker logs` 或集中式系统查看。长期运行时要配置轮转上限，避免单个容器日志持续占满磁盘。

```yaml
logging:
  driver: local
  options:
    max-size: "10m"
    max-file: "3"
```

## 4. 开发与生产配置分层

共享配置放在基础 Compose 文件，开发环境添加源码挂载和调试端口，生产环境添加固定镜像、资源限制和重启策略。上线前先检查合并结果：

```bash
docker compose -f compose.yaml -f compose.prod.yaml config
```

不要只凭单个文件判断最终配置；列表字段、端口和挂载的合并尤其值得检查。

参考：[Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)、[Compose merge](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
