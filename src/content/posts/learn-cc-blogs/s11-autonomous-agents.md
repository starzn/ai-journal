---
title: "s11 Autonomous Agents"
published: 2025-03-21
description: "解析自主代理的子代理生命周期管理与任务恢复机制。"
tags: [自主代理, 生命周期, idle轮询, 任务恢复]
category: learn-cc-blogs
lang: zh_CN
---

# s11 Autonomous Agents

## 1. 子代理生命周期（`_loop`）

- 子代理主循环是 `while True`，但不是永远不退出。
- `WORK PHASE`：读 inbox、调模型、执行工具。
- `IDLE PHASE`：轮询 inbox 和未认领任务，等待新工作。
- 退出条件主要有三类：
  - 收到 `shutdown_request`；
  - 模型调用异常并直接返回；
  - idle 超时后没有可恢复工作（`resume=False`）。

## 2. `idle_requested` 和 `resume` 的作用

- `idle_requested`：用于把"模型调用了 `idle` 工具"这个事实传递到外层流程，触发从工作态切到 idle 轮询。
- `resume`：用于判断 idle 轮询后是否找到继续工作的理由（有新消息或抢到任务）。
- `resume=True` -> 回到 `working`；`resume=False` -> `shutdown` 并退出线程。

## 3. 为什么会注入 assistant 消息

- 在自动认领任务后注入类似 `Claimed task #X. Working on it.` 的 assistant 消息，本质是给下一轮推理"续上上下文"。
- 这样可减少模型重复确认、重复决策，让它直接进入执行态。
- 这类注入是"对模型的行为引导"，不是给人看的 UI 文案。

## 4. `idle` 工具在 lead 与子代理上的差异

- 子代理侧：`idle` 有实际控制流作用，会触发进入 idle 轮询阶段。
- lead 侧：`idle` 通常只是占位/兼容（常见是返回固定文本），不进入同样的 idle 状态机。
- 这样做是为了避免 `Unknown tool`，同时保持工具集一致性。

## 5. 任务看板与状态约束

- 任务文件位于 `.tasks/`，通常为 `task_<id>.json`。
- `scan_unclaimed_tasks` 只会扫描可领取任务（典型是 `pending` 且无 owner 且未被阻塞）。
- 建议统一任务状态枚举为：
  - `pending`
  - `in_progress`
  - `completed`
- `done` 之所以出现，根因通常是缺少统一写入入口和强校验（靠通用写文件工具时容易写出非标准值）。

## 6. 任务创建/更新与职责边界

- 讨论结论：子代理更适合"执行与汇报"，lead 负责"任务编排与最终状态治理"。
- 推荐职责分工：
  - 子代理：认领任务、执行任务、汇报结果。
  - lead：创建任务、更新任务、审批完成态。
- 这样能避免并发写任务导致的状态冲突，也更容易审计与追踪。

## 7. 完工回传的推荐流程（协议思路）

- 子代理完成后向 lead 发送结构化消息（例如包含 `task_id` + `summary`）。
- lead 审核结果后将任务更新为 `completed`。
- 如需自动化，可加开关：
  - 自动完成模式：收到完工上报直接更新为 `completed`；
  - 审批模式：先生成 review 请求，再由 lead 明确 approve/reject。

## 8. 本次排查的经验点

- "能跑起来"优先于"功能堆叠"；权限和协议建议逐步增加。
- 任务状态必须有强约束（枚举 + 校验 +统一更新入口）。
- 子代理能力要最小化授权，避免越权直接改任务主数据。

## 9. 示例

1. `Create 3 tasks on the board, then spawn alice and bob. Watch them auto-claim.`
2. `Spawn a coder teammate and let it find work from the task board itself`
3. `Create tasks with dependencies. Watch teammates respect the blocked order.`
4. 输入 `/tasks` 查看带 owner 的任务看板
5. 输入 `/team` 监控谁在工作、谁在空闲
