---
title: "Kubernetes 可用性：HPA、滚动更新与 PDB"
published: 2026-08-16
description: "三个机制分别处理容量、发布和主动驱逐，不能互相替代。"
tags: [Kubernetes, HPA, PDB, RollingUpdate, 可用性]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes 可用性：HPA、滚动更新与 PDB

HPA、滚动更新和 PDB 都与副本数量有关，但它们控制的是三条不同路径。

| 机制 | 主要职责 | 关键配置 |
| --- | --- | --- |
| HPA | 根据指标调整副本数 | `minReplicas`、`maxReplicas`、目标指标 |
| RollingUpdate | 发布时替换新旧 Pod | `maxSurge`、`maxUnavailable` |
| PDB | 限制主动驱逐造成的不可用 | `minAvailable` 或 `maxUnavailable` |

## HPA 依赖指标链路

基于 CPU 或内存的 HPA 需要 Resource Metrics API，通常由 metrics-server 提供。指标不可用时，HPA 无法正常计算期望副本数；此外，CPU 利用率目标还依赖合理的资源 requests。

## PDB 不管理滚动发布

PDB 约束的是通过 Eviction API 发起的主动驱逐，例如节点维护时的 `kubectl drain`。Deployment 滚动更新不通过这条路径，它由自身的更新策略控制。

直接删除 Pod、节点突然宕机或容器 OOM，也不能指望 PDB 阻止。PDB 是维护保护边界，不是通用高可用开关。

## 一个容易卡住维护的配置

单副本服务设置 `minAvailable: 1`，会让受 PDB 约束的节点驱逐无法继续。配置前要同时考虑副本数、调度容量和维护流程。

实际可用性通常来自组合：多副本分散故障域，readiness 控制流量，滚动策略控制发布，HPA 处理负载变化，PDB 给节点维护留出安全边界。

参考：[Horizontal Pod Autoscaling](https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/)、[Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
