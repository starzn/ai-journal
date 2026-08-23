---
title: "Kubernetes 为什么需要容器运行时"
published: 2026-06-07
description: "分清 kubelet、CRI、containerd 与低层运行时在容器启动链路中的职责。"
tags: [Kubernetes, containerd, CRI, 容器运行时]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes 为什么需要容器运行时

Kubernetes 负责声明和编排工作负载，但不会亲自创建 Linux 容器。节点上的 kubelet 通过 CRI 与容器运行时通信。

```text
kube-apiserver → kubelet → CRI → containerd → OCI runtime → Linux 容器
```

- kubelet：让节点上的 Pod 状态向期望状态收敛；
- CRI：Kubernetes 与运行时之间的标准接口；
- containerd、CRI-O：实现 CRI 的常见高层运行时；
- OCI runtime：最终创建 namespace、cgroup 和容器进程。

早期 Kubernetes 曾通过 dockershim 适配 Docker Engine，后来移除了内置 dockershim。移除的是 kubelet 对 Docker Engine 的特殊适配层，不是“容器镜像不能再用 Docker 构建”。符合 OCI 规范的镜像仍可由 containerd 等运行时执行。

## 排障工具边界

```bash
kubectl describe pod <pod>
kubectl logs <pod>
crictl ps -a
crictl inspect <container-id>
```

优先从 Kubernetes API 和 Events 排查；只有问题落到节点运行时、镜像或 sandbox 层时，才进入节点使用 `crictl`。直接操作运行时创建的容器不会改变声明状态，kubelet 仍可能重新调谐它们。

参考：[Container runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
