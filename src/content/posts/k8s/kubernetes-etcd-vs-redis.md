---
title: "etcd 与 Redis：相似的 KV，不同的目标"
published: 2026-08-09
description: "etcd 是 Kubernetes 状态后端，Redis 的类比只能帮助入门，不能替代一致性模型。"
tags: [Kubernetes, etcd, Redis, Raft]
category: Kubernetes
draft: false
lang: zh_CN
---

# etcd 与 Redis：相似的 KV，不同的目标

etcd 和 Redis 都能以键值形式存储数据，但设计目标不同。Kubernetes 使用 etcd 持久化 API 对象状态，控制器、调度器和客户端通过 kube-apiserver 使用这些状态。

```text
kubectl / controller / scheduler
              ↓
        kube-apiserver
              ↓
      watch cache / etcd
```

客户端不应直接访问 etcd。部分读取可能由 API Server 的 watch cache 提供，因此也不能简单理解为每次 `kubectl get` 都直接查询磁盘上的 etcd。

## 为什么不是普通缓存

etcd 使用 Raft 复制日志，写入需要多数成员确认后才能提交。它优先保证一致的集群状态。Redis 有丰富的数据结构和多种持久化、复制模式，常用于缓存、队列和快速数据服务；其可靠性取决于具体部署与配置。

因此，“etcd 是更可靠的 Redis”只能作为入门类比，不能据此互换两者。

## 运维含义

- etcd 失去多数成员时，集群控制面会失去正常写入能力；
- API 对象和 Secret 都可能存于 etcd，备份必须受保护；
- 快照只有经过恢复演练才算可靠备份；
- 业务数据库数据不保存在 Kubernetes 的 etcd 中。

参考：[Kubernetes API concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/)、[etcd learning](https://etcd.io/docs/)
