---
title: "kubeadm 多节点集群的组成"
published: 2026-08-23
description: "从控制平面、工作节点、容器运行时和 CNI 理解 kubeadm 集群，而不是照抄安装命令。"
tags: [Kubernetes, kubeadm, 控制平面, 集群架构]
category: Kubernetes
draft: false
lang: zh_CN
---

# kubeadm 多节点集群的组成

kubeadm 帮助初始化符合 Kubernetes 约定的集群，但它不是完整的基础设施管理器，也不会替你长期维护操作系统、网络、证书和高可用入口。

```text
控制平面：kube-apiserver、etcd、scheduler、controller-manager
工作节点：kubelet、容器运行时、网络组件
所有节点：系统配置、时间同步、内核网络能力
```

典型初始化链路是：准备节点 → 配置容器运行时 → 初始化控制平面 → 安装 CNI → 加入工作节点 → 验证系统组件。

## 安装命令为什么不能永久照抄

Kubernetes 软件源、支持版本、运行时配置、CNI 参数和系统要求都会变化。历史实验最有价值的是理解依赖关系，不是保存一条永不过期的命令。

搭建前应重新核对：

- 目标版本仍受支持，控制平面与节点版本兼容；
- containerd 与 kubelet 使用一致的 cgroup 驱动；
- Pod 网段不与节点、VPN 或宿主网络冲突；
- API Server 和节点端口遵守最小开放原则；
- etcd、证书和 kubeconfig 有备份及恢复方案；
- 单控制平面实验不被误认为生产高可用架构。

`kubeadm join` 中的令牌和证书哈希属于敏感集群接入信息，不应写入博客、Git 或公共日志。

参考：[Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
