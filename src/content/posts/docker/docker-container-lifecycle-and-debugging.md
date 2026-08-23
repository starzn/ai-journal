---
title: "Docker 容器生命周期与排查入口"
published: 2026-06-04
description: "分清 run、start、stop、pause，并用 inspect、stats 和 system df 快速定位问题。"
tags: [Docker, 容器, 排障, 运维]
category: Docker
draft: false
lang: zh_CN
---

# Docker 容器生命周期与排查入口

容器的常见状态包括 `Created`、`Running`、`Paused` 和 `Exited`。理解状态变化，比反复重建容器更有助于排障。

```text
docker run     创建并启动新容器
docker start   启动已有的已停止容器
docker stop    请求主进程优雅退出
docker pause   冻结容器进程，资源仍被占用
docker rm      删除已停止的容器
```

`run` 与 `start` 的区别尤其重要：前者创建新容器，后者沿用已有容器的名称、挂载、网络和端口配置。

## 四个排查入口

```bash
docker ps -a
docker inspect <container>
docker logs --tail 100 <container>
docker stats <container>
```

- `ps -a`：确认容器是否退出以及退出时间；
- `inspect`：查看退出码、重启策略、挂载和网络；
- `logs`：读取应用写入 stdout、stderr 的输出；
- `stats`：观察 CPU、内存、网络和磁盘 I/O。

磁盘问题可以先运行：

```bash
docker system df -v
```

不要把“容器处于 Running”直接等同于“服务可用”。进程存活、端口监听和业务健康是三个不同层次，需要结合日志、健康检查和实际请求判断。

参考：[Docker container CLI](https://docs.docker.com/reference/cli/docker/container/)
