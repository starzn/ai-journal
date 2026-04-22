---
title: "s06 Context Compact 学习记录"
published: 2025-03-11
description: "解析 Agent 在长会话中的三层上下文压缩机制。"
tags: [上下文压缩, token控制, 长会话, 分层压缩]
category: learn-cc-blogs
lang: zh_CN
---

# s06_context_compact 学习记录

## 一、整体目标

`s06_context_compact.py` 的核心是让 Agent 在长会话里"可持续工作"：

- 通过分层压缩减少上下文长度
- 在保留连续性的同时控制 token
- 必要时把历史写盘，避免关键信息彻底丢失

文件开头也明确了三层流程（micro_compact / auto_compact / compact tool）。

---

## 二、三层压缩机制

### 1) Layer 1: micro_compact（每轮静默执行）

位置：`micro_compact(messages)`

核心行为：

- 扫描 `messages` 中的 `tool_result`
- 保留最近 `KEEP_RECENT` 条（当前是 3 条）
- 对更早的长结果（`content` 为字符串且长度 > 100）做占位替换：
  - `"[Previous: used {tool_name}]"`
- `read_file` 工具结果默认保留（`PRESERVE_RESULT_TOOLS = {"read_file"}`）

关键点：

- 它是"原地修改"传入的 `messages` 内容
- 返回的仍是同一个列表对象（只是元素内容可能被改了）

---

### 2) Layer 2: auto_compact（自动触发）

触发条件：

- `estimate_tokens(messages) > THRESHOLD`（阈值 50000）

执行步骤：

1. 先把完整会话写入 `.transcripts/transcript_xxx.jsonl`
2. 把 `messages` 序列化后截取尾部 `[-80000:]`（偏向最近上下文）
3. 调用模型做总结
4. 返回只包含 1 条摘要消息的新列表

关键点：

- `jsonl` = 每行一个 JSON 对象，方便增量写入和大文件处理
- `json.dumps` 是把 Python 对象转成 JSON 字符串（`default=str` 用来兜底不可序列化对象）
- 只截尾部意味着优先保留"最近状态"，不是最早历史

---

### 3) Layer 3: compact tool（手动触发）

机制：

- 当模型调用 `compact` 工具时，打标记 `manual_compact = True`
- 在本轮工具处理结束后执行：
  - `messages[:] = auto_compact(messages)`
  - `return` 直接结束当前 `agent_loop`

为什么手动路径直接 `return`：

- 避免同一轮内"工具输出 + 压缩后继续跑"导致状态混乱
- 让压缩成为明确边界，下一轮从摘要上下文重新开始

---

## 三、你重点问到的语法与行为

### 1) `to_clear = tool_results[:-KEEP_RECENT]`

- 含义：取"除最后 KEEP_RECENT 个元素之外"的前面所有元素
- 常用于"保留最近 N 条，其余处理"

### 2) `enumerate` 与"直接解包"

- `for msg_idx, msg in enumerate(messages)`：因为需要索引 `msg_idx`
- `for _, _, result in to_clear`：因为 `to_clear` 每个元素本身就是三元组，可直接解包
- 不是"list 必须 enumerate / tuple 才能直接迭代"，本质是是否需要索引、元素结构是否可解包

### 3) `exist_ok=True`

- 目录已存在时不报错
- 常用于"确保目录存在"的写法

### 4) `next((...), "")`

- 取生成器中的第一个匹配项
- 找不到时返回默认值 `""`，避免异常

### 5) `messages[:] = auto_compact(messages)` vs `messages = auto_compact(messages)`

- `messages[:] = ...`：原地替换列表内容，不改对象引用；外部持有者能看到变化
- `messages = ...`：仅局部变量重新绑定；外部原列表不变

这和 JS 里"改数组内容" vs "让形参指向新数组"的区别很接近。

---

## 四、关于"丢失的 token"

当会话很长（例如估算 70000 token）时：

- 总结输入只取尾部一段（大约最近上下文）
- 没被截入总结输入的早期内容不会进入本轮摘要
- 但完整历史已经写进 transcript 文件，可回溯
- 内存里的 `messages` 会被摘要列表整体替换

---

## 五、工具输出情况（本文件实现）

已注册工具：`bash / read_file / write_file / edit_file / compact`

- 都会形成工具输出文本（成功、失败、或固定提示）
- `compact` 在当前实现里会走特殊分支显示 `"Compressing..."`，随后触发手动压缩
- 若本轮模型没有 `tool_use`，则不会有工具输出

---

## 六、实践例子（按你的要求补充）

1. `Read every Python file in the agents/ directory one by one`（观察 micro-compact 替换旧结果）
2. `Keep reading files until compression triggers automatically`
3. `Use the compact tool to manually compress the conversation`
