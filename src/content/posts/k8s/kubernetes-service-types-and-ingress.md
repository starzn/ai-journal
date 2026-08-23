---
title: "Kubernetes Service 类型与 Ingress"
published: 2026-06-28
description: "ClusterIP、NodePort、LoadBalancer、Headless Service 与 Ingress 各自解决什么问题。"
tags: [Kubernetes, Service, Ingress, 网络]
category: Kubernetes
draft: false
lang: zh_CN
---

# Kubernetes Service 类型与 Ingress

Service 为一组 Pod 提供稳定入口，但不同类型对应不同暴露范围。

| 类型 | 作用 |
| --- | --- |
| `ClusterIP` | 只在集群内部提供虚拟地址，默认类型 |
| `NodePort` | 在每个节点发布一个端口 |
| `LoadBalancer` | 请求基础设施提供外部负载均衡器 |
| Headless | `clusterIP: None`，DNS 直接返回后端地址 |

`LoadBalancer` 是否真正获得公网地址，取决于云控制器或本地负载均衡实现；在裸机集群里仅写类型并不会凭空创建云负载均衡器。

## Ingress 位于 Service 之前

Ingress 描述 HTTP/HTTPS 的域名和路径路由：

```text
客户端 → Ingress Controller → Service → Pod
```

只有创建 Ingress 资源而没有安装 Ingress Controller，不会产生实际转发。Controller 负责监听资源并配置 Nginx、Envoy 或云负载均衡器等数据面。

一般做法是：内部服务使用 ClusterIP；多个 HTTP 服务共享一个 Ingress/Gateway 入口；数据库等非 HTTP 服务不要勉强通过 Ingress 暴露。

排查访问问题时按链路逐层验证：Pod readiness、Service Endpoints、集群内 Service 请求、Controller 状态，最后才是外部 DNS 与防火墙。

参考：[Service](https://kubernetes.io/docs/concepts/services-networking/service/)、[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
