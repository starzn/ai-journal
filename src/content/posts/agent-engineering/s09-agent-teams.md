---
title: "s09 Agent Teams"
published: 2025-03-17
description: "多 Agent 团队协作中的消息传递与 JSONL 文件通信机制。"
tags: [Agent团队, JSONL, 消息传递, 文件通信]
category: Agent 工程实践
lang: zh_CN
---

# s09 Agent Teams

## 1. `msg.update(extra)` 的作用

- `msg` 是基础消息字典，包含 `type`、`from`、`content`、`timestamp`。
- `msg.update(extra)` 会把 `extra` 字典中的键值对合并到 `msg`。
- 如果 `extra` 里有同名键，会覆盖原值（例如覆盖 `type`）。
- 代码里有 `if extra:` 判断，只有传了非空 `extra` 才会执行。

## 2. `read_text().strip().splitlines()` 这串调用在做什么

- `read_text()`：读取整个 inbox 文件文本。
- `strip()`：去掉首尾空白（包括首尾换行）。
- `splitlines()`：按行切成列表，供 `for line in ...` 遍历。
- 后续 `if line:` 用于过滤空行，`json.loads(line)` 把每行 JSON 解析为字典对象。

## 3. 每行内容里有 `\n` 会不会把 JSONL 读坏

- 正常不会。
- 写入使用 `json.dumps(msg) + "\n"`，消息中的真实换行会被 JSON 转义为 `\\n`，仍然是文件中的单行 JSON。
- 读取时 `json.loads` 会还原为真实换行。
- 只有文件被手工破坏（非完整 JSON 行）时才会解析失败。

## 4. `status` 相关判断含义

- `if member["status"] not in ("idle", "shutdown")` 表示：除 `idle` 和 `shutdown` 外，都不允许重新 `spawn`。
- `idle`：空闲，可重新分配任务。
- `shutdown`：已关闭，也允许重新拉起。
- 目的是避免同一个 teammate 在 `working` 状态时被重复启动。

## 5. `"\n".join(lines)` 是否会在最前面加换行

- 不会。
- `sep.join(list)` 只在元素之间插入分隔符，不会在最前或最后附加。
- 例如：`"\n".join(["A","B","C"])` 结果是 `A\nB\nC`。

## 6. `/inbox` 的消费风险与优化

### 原风险

- 之前 `/inbox` 直接调用 `read_inbox("lead")`，而 `read_inbox` 是"读完即清空"。
- 所以手动输入 `/inbox` 会把 lead 的收件箱消费掉。

### 已优化方案

- `/inbox` 改为调用 `peek_inbox("lead")`：只查看，不清空。
- 新增 `/inbox_drain`：显式执行"读取并清空"。
- 这样把"观察"和"消费"分离，降低误操作风险。

## 7. bob 线程一直轮询的原因与优化

### 原因

- teammate 循环中会持续检查 inbox。
- 无等待机制时会形成高频空轮询，并产生大量日志。

### 优化

- 增加 `needs_followup` 状态：
  - 有新消息或 tool 链需要续跑时才调用模型。
  - 否则进入短暂 `sleep` 等待，避免空转。
- 同时把 `read_inbox` 日志调整为仅在确实读到消息时打印，减少噪音。

### 为什么把 `break` 改成 `needs_followup = False; continue`

- `break` 会直接结束线程（下线）。
- 改成 `continue` 是让 persistent teammate 进入待机态，后续有新消息还能继续处理。
- 这符合"长期存在、可反复接活"的 Agent Team 设计目标。

## 8. `lead.jsonl` 是怎么生成的

- `.team/inbox` 目录在 `MessageBus` 初始化时创建。
- 具体 `lead.jsonl` 文件是懒创建：首次有人 `send_message` 到 `to="lead"` 时，通过 `open(..., "a")` 自动创建。
- `read_inbox("lead")` 不会创建文件；文件不存在时只返回空列表。

## 9. alice / bob 什么时候会启动

- 不会随程序启动自动拉起。
- 只有触发 `spawn_teammate`（最终调用 `TEAM.spawn(...)`）时才会创建并启动线程。
- 即使配置里已有成员，也需要再次 `spawn` 才会真正运行。

## 10. 示例

1. `Spawn alice (coder) and bob (tester). Have alice send bob a message.`
2. `Broadcast "status update: phase 1 complete" to all teammates`
3. `Check the lead inbox for any messages`
4. 输入 `/team` 查看团队名册和状态
5. 输入 `/inbox` 手动检查领导的收件箱
