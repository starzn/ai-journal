---
title: "Kubernetes Pod 排障：先判断失败阶段"
published: 2026-07-19
description: "从 Pod 状态定位调度、拉取镜像、配置、启动和运行阶段的问题。"
tags: [Kubernetes, kubectl, 排障, Pod]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes Pod 排障：先判断失败阶段

Pod 异常时，不要先猜解决方案。状态通常已经提示了失败发生在哪个阶段：

| 状态 | 主要失败阶段 | 常见方向 |
| --- | --- | --- |
| `Pending` | 调度 | 资源、节点约束、PVC |
| `ImagePullBackOff` | 拉取镜像 | 名称、标签、认证、网络 |
| `CreateContainerConfigError` | 创建容器 | ConfigMap、Secret、字段引用 |
| `CrashLoopBackOff` | 启动后崩溃 | 启动命令、应用错误、依赖 |
| `OOMKilled` | 运行 | 内存限制或泄漏 |
| `Running` 但反复重启 | 运行或探针 | 上次日志、liveness |

## 固定的第一轮检查

```bash
kubectl get pod <pod-name> -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> --all-containers
kubectl logs <pod-name> --previous
kubectl get events --sort-by=.metadata.creationTimestamp
```

重点不是把所有输出都看一遍，而是建立证据链：

1. `get` 确认当前状态、重启次数和所在节点；
2. `describe` 查看 Conditions 与末尾 Events；
3. `logs` 查看当前进程输出；
4. 反复崩溃时用 `--previous` 获取上一个容器实例的日志。

## 两个快速判断

`Pending` 且 `PodScheduled=False`，优先看 scheduler 的 `FailedScheduling`；已经分配节点但镜像失败，则优先看 kubelet 的拉取事件。

`CrashLoopBackOff` 不是根因，只表示 Kubernetes 正在退避重启。真正的原因通常在容器退出码、应用日志、启动命令或探针配置中。

先定位失败阶段，再缩小排查范围，通常比反复删除 Pod 更快。

参考：[Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)、[Application troubleshooting](https://kubernetes.io/docs/tasks/debug/debug-application/)
