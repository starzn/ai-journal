---
title: "Helm 与 Kustomize 应该怎么选"
published: 2026-08-02
description: "Helm 管理可参数化发布，Kustomize 叠加原生 YAML，两者解决的问题并不完全相同。"
tags: [Kubernetes, Helm, Kustomize, 配置管理]
category: Kubernetes
draft: false
lang: zh_CN
---

# Helm 与 Kustomize 应该怎么选

Helm 和 Kustomize 都能减少多环境 YAML 重复，但抽象方式不同。

| 维度 | Helm | Kustomize |
| --- | --- | --- |
| 核心模型 | 模板 + values | base + overlay |
| 输出 | 渲染后的 Kubernetes YAML | 变换后的 Kubernetes YAML |
| 生命周期 | release、升级、历史、回滚 | 通常由 Git 与 apply 工具管理 |
| 适合 | 可复用应用包、参数较多 | 环境差异较小、希望保留原生 YAML |

Helm Chart 适合把应用作为一个可安装单元交付；Kustomize 更像对一组基础资源打补丁。

## 不要跳过渲染检查

```bash
helm template demo ./chart -f values-prod.yaml
kubectl kustomize overlays/prod
```

模板语法正确不代表渲染后的对象正确。CI 中还应对最终 YAML 做 API 校验、策略检查和差异审查。

两者可以组合，但要明确所有权。例如，用 Helm 管第三方组件，用 Kustomize 管自有工作负载；或先渲染 Chart，再由 GitOps 工具部署。避免让两套工具同时修改同一字段，否则难以判断最终来源。

版本敏感的模板函数、字段和 CLI 行为应以实际安装版本的官方文档为准。

参考：[Helm documentation](https://helm.sh/docs/)、[Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
