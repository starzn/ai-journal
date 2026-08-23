---
title: "从镜像构建到 Registry 发布"
published: 2026-08-13
description: "用不可变标签、摘要和最小凭据建立可回滚的镜像发布流程。"
tags: [Docker, Registry, 镜像发布, CI/CD]
category: Docker
draft: false
lang: zh_CN
---

# 从镜像构建到 Registry 发布

镜像仓库解决的是镜像分发，不负责替你验证应用是否可用。一个最小发布链路通常是：

```text
构建 → 本地测试 → 标记 → 登录仓库 → 推送 → 目标环境按摘要拉取 → 健康验证
```

```bash
docker build -t registry.example.com/team/api:<git-sha> .
docker push registry.example.com/team/api:<git-sha>
```

## 标签与摘要

标签是可移动指针，同一个标签可以被重新推送。镜像摘要由内容决定，更适合精确确认部署对象。

实践中可以同时保留：

- 完整 Git SHA：定位源码版本；
- 语义版本：便于人阅读；
- 镜像摘要：部署与审计时确认内容。

`latest` 可以用于本地试验，但不适合作为唯一生产版本依据。

## 凭据与回滚

仓库凭据应使用最小权限、短期令牌或 CI 的专用身份，不能写入 Dockerfile、Compose 或部署日志。目标机器只需要拉取权限，不应持有推送权限。

回滚不是重新构建旧源码，而是重新部署已经验证过的旧镜像摘要。这样可以避免依赖源变化导致“同一源码、不同镜像”。

参考：[Build, tag and publish an image](https://docs.docker.com/get-started/docker-concepts/building-images/build-tag-and-publish-an-image/)
