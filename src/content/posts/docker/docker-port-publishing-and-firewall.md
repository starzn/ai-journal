---
title: "Docker 端口发布与防火墙边界"
published: 2026-08-06
description: "理解 EXPOSE、ports、宿主机监听地址和防火墙之间的关系。"
tags: [Docker, 网络, 防火墙, 端口]
category: Docker
draft: false
lang: zh_CN
---

# Docker 端口发布与防火墙边界

容器端口是否能被外部访问，取决于多层配置：应用监听地址、Docker 端口发布、宿主机防火墙以及云网络策略。

```text
客户端 → 云防火墙/安全组 → 宿主机端口 → Docker 转发 → 容器端口
```

`EXPOSE 3000` 只是镜像文档，不会建立转发。真正发布端口的是：

```bash
docker run -p 127.0.0.1:3000:3000 example/api:1.0
```

绑定 `127.0.0.1` 时，只有宿主机本地可访问，适合由同机反向代理转发。写成 `3000:3000` 通常会监听所有宿主机接口，是否公网可达还取决于防火墙和网络入口。

## 最小暴露原则

- 数据库和缓存只加入内部 Docker 网络，不发布宿主机端口；
- Web 服务优先只暴露给反向代理；
- 管理端口限制来源地址；
- 同时检查 IPv4 与 IPv6 监听情况；
- 不把“主机防火墙已拒绝”当作唯一安全边界。

Docker 会管理主机上的网络转发规则，不同防火墙后端和 Docker 版本的行为可能不同。生产环境应实际检查监听端口和规则，而不是只阅读 Compose 文件。

参考：[Port publishing](https://docs.docker.com/engine/network/port-publishing/)
