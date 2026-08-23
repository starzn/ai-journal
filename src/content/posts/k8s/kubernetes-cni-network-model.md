---
title: "Kubernetes CNI：Pod 网络是怎样接通的"
published: 2026-06-14
description: "CNI 负责为 Pod 接入网络，Service 与 NetworkPolicy 则位于不同层次。"
tags: [Kubernetes, CNI, Pod 网络, NetworkPolicy]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes CNI：Pod 网络是怎样接通的

调度器只决定 Pod 放在哪个节点。Pod 创建时，kubelet 还需要通过容器运行时调用 CNI 插件，为 Pod 配置网络接口、地址和路由。

```text
Pod sandbox 创建
      ↓
运行时调用 CNI
      ↓
创建网卡、分配 IP、写入路由
      ↓
Pod 可以与集群网络通信
```

Kubernetes 网络模型希望每个 Pod 拥有独立 IP，并能在不额外做 NAT 的情况下与其他 Pod 通信。跨节点如何实现，由具体 CNI 决定：可能使用路由、隧道或底层网络能力。

## CNI 不等于 Service

- CNI 解决 Pod 如何接入网络；
- Service 为一组会变化的 Pod 提供稳定入口；
- kube-proxy 或相应数据面实现 Service 转发；
- DNS 把服务名解析为稳定地址；
- NetworkPolicy 描述允许哪些流量，但是否生效取决于网络插件支持。

Pod 长时间停在 `ContainerCreating` 且 Events 出现 sandbox、CNI 或 IP 分配错误时，应检查 CNI DaemonSet、节点网络状态和地址池，而不是先改应用镜像。

参考：[Cluster networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
