---
title: "Docker 磁盘清理：先看占用，再删资源"
published: 2026-07-30
description: "区分容器、镜像、卷和构建缓存，避免一条 prune 命令误删数据。"
tags: [Docker, 磁盘清理, Volume, 运维]
category: Docker
draft: false
lang: zh_CN
---

# Docker 磁盘清理：先看占用，再删资源

Docker 的磁盘占用通常来自四类对象：停止的容器、未使用镜像、volume 和构建缓存。

先查看，而不是直接 prune：

```bash
docker system df -v
docker ps -a
docker image ls
docker volume ls
docker builder prune --filter until=168h
```

## 风险从低到高

1. 已确认无用的停止容器；
2. 没有容器引用的镜像；
3. 可重新生成的构建缓存；
4. volume 中的持久数据。

volume 可能保存数据库、上传文件或队列数据。即使显示“未使用”，也可能只是当前没有容器挂载。删除前应检查名称、标签、挂载点、备份和恢复方式。

```bash
docker volume inspect <volume>
```

`docker system prune` 不应成为日常默认动作，带 `--volumes` 时风险更高。生产主机应按对象精确清理，并在删除前记录目标列表。

更好的长期策略是：镜像使用明确标签并设置保留规则、日志配置轮转、构建节点定期清理缓存、业务数据使用可备份的命名卷或外部存储。

参考：[Docker prune](https://docs.docker.com/engine/manage-resources/pruning/)
