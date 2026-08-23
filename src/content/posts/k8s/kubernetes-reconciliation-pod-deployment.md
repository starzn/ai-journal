---
title: "从 Pod 到 Deployment：理解 Kubernetes 调谐循环"
published: 2026-05-31
description: "Kubernetes 的核心不是执行一次命令，而是持续把实际状态拉回期望状态。"
tags: [Kubernetes, Pod, Deployment, Controller]
category: Kubernetes
draft: false
lang: zh_CN
---

# 从 Pod 到 Deployment：理解 Kubernetes 调谐循环

Kubernetes 最重要的心智模型不是“启动容器”，而是“持续调谐状态”。

```text
声明期望状态 → 控制器观察实际状态 → 计算差异 → 执行动作 → 再观察
```

例如，Deployment 声明 `replicas: 3`。某个 Pod 消失后，控制器发现实际副本只剩 2 个，就会创建新的 Pod。它不是保证原来的 Pod 永远不坏，而是持续恢复期望数量。

## Pod 为什么不适合单独管理

Pod 是 Kubernetes 的最小调度单位，可以包含一个或多个共享网络和存储的容器。但 Pod 本身是可替换对象：重建后 UID 和 IP 都可能变化。

因此，无状态应用通常交给 Deployment：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.27-alpine
```

Deployment 管理 ReplicaSet，ReplicaSet 再维护 Pod 数量。排查时可以沿着所有权关系查看，而不是只盯着最后一个 Pod。

## 声明式系统的使用方式

- 修改 YAML 表达“想要什么”，不要手工维护某个 Pod；
- 用标签和 selector 建立控制器、Service 与 Pod 的关系；
- 把 Pod 当作可替换实例，把持久数据放到独立存储；
- 观察 `status` 和 Events，判断实际状态为何没有收敛。

理解调谐循环后，自愈、滚动更新和扩缩容都会变成同一个模型的不同应用。

参考：[Kubernetes controllers](https://kubernetes.io/docs/concepts/architecture/controller/)、[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
