---
title: "kube-scheduler 与 Docker 的职责差异"
published: 2026-07-26
description: "Docker 在一台主机上运行容器，scheduler 则在集群节点之间选择 Pod 的落点。"
tags: [Kubernetes, kube-scheduler, Docker, 调度]
category: Kubernetes
draft: false
lang: zh_CN
---

# kube-scheduler 与 Docker 的职责差异

Docker Engine 接收“在这台主机运行容器”的请求；kube-scheduler 解决的是“这个尚未绑定节点的 Pod 应该放到集群中的哪台节点”。

```text
Pod 创建但没有 nodeName
          ↓
scheduler 过滤不可用节点
          ↓
对可用节点打分
          ↓
写入绑定结果
          ↓
目标节点 kubelet 启动 Pod
```

调度器不会直接创建容器。它只选择节点，之后由该节点的 kubelet 和容器运行时完成实际启动。

## 调度依据

- 容器的 CPU、内存 requests；
- nodeSelector、节点亲和性和反亲和性；
- taint 与 toleration；
- PV 的拓扑与节点亲和性；
- Pod 拓扑分布约束；
- 节点是否 Ready、是否可调度。

`Pending` 不一定表示镜像或应用有问题。如果 Events 中出现 `FailedScheduling`，应优先检查资源请求和约束。

Docker Compose 能在单机组织多个服务，但不提供 Kubernetes 这种跨节点调度与持续调谐。两者不是同一级别的“启动命令替代品”。

参考：[Kubernetes scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)
