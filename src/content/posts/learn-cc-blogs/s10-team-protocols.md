---
title: "s10 Team Protocols 学习记录"
published: 2025-03-19
description: "解析团队协议中的 shutdown 响应流程与双重确认机制。"
tags: [团队协议, shutdown, 状态确认, 消息总线]
category: learn-cc-blogs
lang: zh_CN
---

# s10 Team Protocols 学习记录

## 1. `shutdown_response` 在子代理侧做什么

- 子代理调用 `shutdown_response` 时，会读取 `request_id` 和 `approve`。
- 它会在 `shutdown_requests` 中更新该请求状态为 `approved` 或 `rejected`。
- 然后通过 `BUS.send(..., "shutdown_response", ...)` 把回执发给 `lead`。
- 最后返回一条结果文本，如 `Shutdown approved`。

## 2. `shutdown_requests` 的 `request_id` 是什么时候保存的

- 在 `lead` 发起 `shutdown_request` 时创建并保存。
- `handle_shutdown_request(teammate)` 会生成 `req_id`，并写入：
  `shutdown_requests[req_id] = {"target": teammate, "status": "pending"}`。
- 同时把这个 `request_id` 发给目标子代理，供后续回执关联。

## 3. 为什么"已经发消息给 lead"还要"查状态"

- 发消息是推送（push），查状态是拉取（pull），两者用途不同。
- 推送用于即时通知；拉取用于按 `request_id` 稳定确认当前状态。
- 即使消息晚到、漏读或重复处理，状态表仍可作为最终事实来源。

## 4. `shutdown_response` 命名歧义与改造

- 原问题：同名 `shutdown_response` 在两侧语义不同。
- 子代理侧：表示"提交 shutdown 决策"。
- lead 侧：实际是"查询 shutdown 状态"。
- 已优化：lead 侧改为 `shutdown_status`；并保留 `shutdown_response` 兼容别名。

## 5. `plan_approval` 命名歧义与改造

- 原问题：`plan_approval` 在两侧也重名不同义。
- 子代理侧原 `plan_approval` 是"提交计划"。
- lead 侧原 `plan_approval` 是"审批计划"。
- 已优化：
  - 子代理侧改名为 `plan_submit`。
  - lead 侧改名为 `plan_review`。
  - 两侧保留 `plan_approval` 兼容路径，避免旧调用中断。

## 6. 消息类型统一

- 为了和 `plan_review` 术语统一，新增消息类型 `plan_review_response`。
- 提交计划和审批回传都切到 `plan_review_response`。
- 保留 `plan_approval_response` 作为兼容类型，降低迁移风险。
- 顶部协议示意图也同步改成 `plan_review_response`。

## 7. 当前是否缺少"子代理自动唤醒机制"

- 结论：当前实现缺少完整自动唤醒。
- 原因：
  - 子代理线程主要在 `spawn()` 时启动。
  - `_teammate_loop` 是有限循环，并可能因 stop 条件退出到 `idle/shutdown`。
  - `BUS.send()` 只写 inbox，不会自动拉起 idle 子代理。
- 含义：当前有"收件箱 + 轮询处理"，但不是"消息到达即事件驱动唤醒"。

## 8. 示例

1. `Spawn alice as a coder. Then request her shutdown.`
2. `List teammates to see alice's status after shutdown approval`
3. `Spawn bob with a risky refactoring task. Review and reject his plan.`
4. `Spawn charlie, have him submit a plan, then approve it.`
5. 输入 `/team` 监控状态
