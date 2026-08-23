---
title: "Docker 环境变量：ARG、ENV 与 Secret 边界"
published: 2026-06-25
description: "分清构建参数、运行配置和真正的秘密，避免把凭据写进镜像。"
tags: [Docker, 环境变量, Secret, Docker Compose]
category: Docker
draft: false
lang: zh_CN
---

# Docker 环境变量：ARG、ENV 与 Secret 边界

环境变量是进程配置机制，不是秘密保险箱。Docker 只是把键值传给容器主进程。

| 方式 | 生效阶段 | 典型用途 |
| --- | --- | --- |
| Dockerfile `ARG` | 构建时 | 构建选项 |
| Dockerfile `ENV` | 构建后与运行时 | 镜像默认配置 |
| Compose `environment` | 运行时 | 明确的环境配置 |
| Compose `env_file` | 运行时 | 批量加载本地配置 |

```yaml
services:
  api:
    image: example/api:1.0
    environment:
      APP_ENV: production
    env_file:
      - runtime.env
```

Compose 项目中的 `.env` 还可以用于 YAML 变量插值，但变量被插值不代表会自动进入容器；是否注入仍由 `environment` 或 `env_file` 决定。

## 凭据不要经过镜像层

不要把密码、令牌写入 `ARG`、`ENV`、Dockerfile 或构建命令。它们可能出现在镜像配置、构建历史、日志或缓存里。

开发环境可以使用不提交 Git 的本地配置文件；生产环境应使用部署平台的 Secret 管理能力，并控制读取权限。前端构建变量最终会进入浏览器下载的静态文件，永远不能承载秘密。

提交前可以检查最终配置，但不要把包含敏感值的输出保存到日志：

```bash
docker compose config
```

参考：[Compose environment variables](https://docs.docker.com/compose/how-tos/environment-variables/)
