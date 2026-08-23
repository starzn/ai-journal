---
title: "Docker Compose 中的网络与存储"
published: 2026-06-18
description: "用服务名通信，用合适的挂载保存数据：Compose 网络与存储的最小心智模型。"
tags: [Docker, Docker Compose, 网络, Volume]
category: Docker
draft: false
lang: zh_CN
---

# Docker Compose 中的网络与存储

多容器应用最常见的两个问题是：服务怎样找到彼此，数据怎样跨容器保存。

## 容器之间使用服务名

Compose 默认会为项目创建网络，服务可以通过服务名解析：

```yaml
services:
  api:
    build: ./api
    environment:
      REDIS_URL: redis://cache:6379
    depends_on:
      - cache

  cache:
    image: redis:7-alpine
```

`api` 应连接 `cache:6379`，而不是 `localhost:6379`。容器里的 `localhost` 只指向容器自己，也不应依赖会随重建变化的容器 IP。

只有需要被宿主机或外部访问的服务才发布端口。数据库、缓存等内部服务通常只需留在 Compose 网络中。

## 三种常见存储方式

| 方式 | 生命周期 | 适合场景 |
| --- | --- | --- |
| 容器可写层 | 随容器删除 | 临时数据 |
| Bind mount | 由宿主机路径决定 | 本地开发、直接编辑源码 |
| Named volume | 独立于容器 | 数据库、缓存持久化 |

数据库通常使用 named volume：

```yaml
services:
  db:
    image: postgres:17-alpine
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

`docker compose down` 不会默认删除 named volume；带 `-v` 才会删除，因此执行清理前要确认数据是否仍需要。

## 一个简单判断

- 源码需要在宿主机实时修改：bind mount；
- 应用数据需要独立保存：named volume；
- 数据不需要跨重建保留：容器可写层。

参考：[Docker networking](https://docs.docker.com/engine/network/)、[Docker storage](https://docs.docker.com/engine/storage/)
