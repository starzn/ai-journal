---
title: "Docker 容器日志与轮转"
published: 2026-07-23
description: "让应用输出到 stdout、stderr，并为长期运行的容器设置日志上限。"
tags: [Docker, 日志, Logging Driver, 运维]
category: Docker
draft: false
lang: zh_CN
---

# Docker 容器日志与轮转

容器化应用优先把日志写到 stdout 和 stderr，再由 Docker 日志驱动收集。这样 `docker logs`、监控代理和集中式日志平台都能使用同一入口。

```bash
docker logs --tail 100 <container>
docker logs --since 30m -f <container>
```

如果应用只写容器内的 `/var/log/app.log`，Docker 默认看不到这些内容；文件还会随容器可写层增长。

## 日志必须有上限

长期运行的高流量服务如果不轮转日志，最终可能耗尽宿主机磁盘。可以在 Compose 中为服务设置限制：

```yaml
services:
  api:
    image: example/api:1.0
    logging:
      driver: local
      options:
        max-size: "10m"
        max-file: "3"
```

也可以配置 Docker daemon 的默认日志驱动，但修改全局配置只影响之后创建的容器，且重启 daemon 会影响主机上的容器，应纳入维护流程。

日志轮转只解决磁盘边界，不等于日志检索、告警或长期归档。生产环境还需要根据合规与排障周期决定保留策略。

不要直接用文本工具修改 Docker 管理的底层日志文件；应通过日志驱动、容器重建或受控清理处理。

参考：[Configure logging drivers](https://docs.docker.com/engine/logging/configure/)
