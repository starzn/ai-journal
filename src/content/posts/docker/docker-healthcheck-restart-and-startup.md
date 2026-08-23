---
title: "Docker 健康检查、重启策略与启动顺序"
published: 2026-07-09
description: "分清 healthcheck、restart 与 depends_on，避免把进程存活误当成服务可用。"
tags: [Docker, Docker Compose, Healthcheck, 可用性]
category: Docker
draft: false
lang: zh_CN
---

# Docker 健康检查、重启策略与启动顺序

这三个机制经常一起出现，但解决的是不同问题：

| 机制 | 回答的问题 |
| --- | --- |
| `healthcheck` | 服务现在能否正常响应？ |
| `restart` | 容器进程退出后是否重启？ |
| `depends_on` | 依赖服务达到什么状态后再启动？ |

## 一个完整的 Compose 片段

```yaml
services:
  api:
    image: example/api:1.0
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:17-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 20s
```

数组里的 `CMD-SHELL` 会经过 shell；`$$` 用于把美元符号留给容器内执行。若不需要 shell 展开，可以使用 `CMD` 数组形式。

## 两个常见误区

第一，容器变成 `unhealthy` 时，Docker 不会仅因为健康检查失败就自动重启它。重启策略主要处理主进程退出。如果希望自愈，应用可在不可恢复时退出，或交给编排系统处理。

第二，普通 `depends_on` 只表达启动依赖，不保证依赖已经可用。需要等待就绪时，应为依赖配置健康检查，并使用 `condition: service_healthy`；应用自身仍应实现重试和超时，因为运行过程中依赖也可能再次不可用。

好的健康检查应快速、稳定、低成本，并真正覆盖服务对外提供能力所必需的路径。

参考：[Compose healthcheck](https://docs.docker.com/reference/compose-file/services/#healthcheck)、[Startup order](https://docs.docker.com/compose/how-tos/startup-order/)
