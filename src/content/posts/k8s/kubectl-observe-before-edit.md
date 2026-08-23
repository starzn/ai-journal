---
title: "kubectl 排障原则：先观察，再修改"
published: 2026-07-12
description: "用 get、describe、logs、events 和 diff 建立证据链，避免盲目重建资源。"
tags: [Kubernetes, kubectl, 排障, 运维]
category: Kubernetes
draft: false
lang: zh_CN
---

# kubectl 排障原则：先观察，再修改

`kubectl` 不只是部署工具，更重要的是读取 Kubernetes API 中的状态和事件。

## 第一轮只读检查

```bash
kubectl get pods -A -o wide
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --all-containers
kubectl logs <pod> -n <namespace> --previous
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp
```

这组命令分别回答：对象当前是什么状态、控制面和 kubelet 记录了什么、应用输出了什么、上一次崩溃前发生了什么。

## 修改前查看差异

```bash
kubectl diff -f manifests/
kubectl apply --server-side --dry-run=server -f manifests/
```

`dry-run=server` 会让 API Server 参与默认值、字段校验和准入流程，但不会持久化对象。它比只在本地解析 YAML 更接近真实提交。

避免把 `kubectl delete pod` 当成通用修复：控制器通常会创建新 Pod，但根因仍在镜像、配置、资源或探针中。删除还可能清除最直接的现场，只剩 Events 和外部日志。

多集群环境下，执行写操作前先确认：

```bash
kubectl config current-context
kubectl config view --minify
```

参考：[kubectl overview](https://kubernetes.io/docs/reference/kubectl/)
