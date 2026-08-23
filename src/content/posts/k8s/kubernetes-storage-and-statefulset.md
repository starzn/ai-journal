---
title: "Kubernetes 存储：从 PVC 到 StatefulSet"
published: 2026-07-05
description: "分清 Volume、PV、PVC 与 StatefulSet，理解有状态应用为何需要稳定身份。"
tags: [Kubernetes, PVC, PV, StatefulSet, 存储]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes 存储：从 PVC 到 StatefulSet

Kubernetes 中，Pod 可以重建或迁移，因此不能把重要数据只放在容器文件系统里。

## 四个对象的关系

```text
Pod → PVC（存储申请）→ PV（存储资源）→ 实际存储
```

- Volume 描述 Pod 怎样挂载存储；
- PersistentVolume 是集群中的存储资源；
- PersistentVolumeClaim 是应用提出的容量和访问模式需求；
- StorageClass 可以按 PVC 动态创建 PV。

PVC 解耦了应用与具体磁盘，但不会自动解决备份、复制、故障切换和数据一致性。

## 为什么数据库常用 StatefulSet

Deployment 适合可互换的无状态副本；StatefulSet 为每个副本提供稳定序号、稳定网络身份和独立 PVC：

```text
db-0 → data-db-0
db-1 → data-db-1
db-2 → data-db-2
```

Pod 重建后 IP 和 UID 仍可能变化，但同一序号会继续使用对应的名字与 PVC。`volumeClaimTemplates` 用来为每个副本生成独立 PVC，避免多个数据库进程误写同一个数据目录。

StatefulSet 通常配合 Headless Service，让客户端通过类似 `db-0.db` 的稳定 DNS 访问特定副本。

## 删除时要更谨慎

缩容或删除 StatefulSet 时，PVC 往往会保留，以防误删数据。这是保护机制，也意味着需要明确的数据回收流程。删除 PVC 前应先确认备份、保留策略和底层卷状态。

参考：[Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)、[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
