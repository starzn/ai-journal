---
title: "Kubernetes 服务入口、配置与探针"
published: 2026-06-21
description: "把流量入口、配置注入和健康判断放回各自的职责边界。"
tags: [Kubernetes, Service, ConfigMap, Secret, Probe]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes 服务入口、配置与探针

Pod 会被替换，IP 也会变化。稳定访问依赖 Service，运行配置依赖 ConfigMap 与 Secret，流量是否进入某个 Pod 则由探针决定。

## Service 提供稳定入口

Service 通过 selector 找到一组 Pod，并提供稳定的虚拟地址和 DNS 名称：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 3000
```

集群内部访问 `api:80`，不应记住某个 Pod IP。需要 HTTP 路由或 TLS 终止时，再由 Ingress 或 Gateway 把外部流量转给 Service。

## ConfigMap 与 Secret 只负责分离配置

两者都可以通过环境变量或挂载文件注入。ConfigMap 放非敏感配置；Secret 放敏感数据，但 Secret 的编码并不等于加密。仍需限制 RBAC 权限、避免提交明文，并根据环境启用静态加密或外部密钥系统。

## 三种探针不要混用

| 探针 | 失败后的效果 |
| --- | --- |
| `startupProbe` | 启动未完成时，暂不执行其他探针 |
| `readinessProbe` | 从 Service 后端摘除，不重启容器 |
| `livenessProbe` | 触发容器重启 |

启动慢的应用可以先用 `startupProbe` 给出窗口；暂时无法服务时让 readiness 失败；只有进程确实进入不可恢复状态时才让 liveness 失败。

探针过严会制造重启风暴，过松又会把故障实例留在流量中。先明确失败后希望 Kubernetes 做什么，再选择探针。

参考：[Services](https://kubernetes.io/docs/concepts/services-networking/service/)、[Configure probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
