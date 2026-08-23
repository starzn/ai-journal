---
title: "s03 Todo Write"
published: 2025-03-05
description: "解析 Messages API 中 content block 的字段规范及 TodoManager 状态管理。"
tags: [TodoManager, content block, API规范, 状态管理]
category: Agent 工程实践
lang: zh_CN
---

# s03_todo_write.py

## 本次内容概览

这次围绕 `agents/s03_todo_write.py` 做了结构化梳理，核心聚焦在两类能力：

- Messages API 中 `content block` 的字段规范（`type/text/content` 的层级差异）
- TodoManager 的状态管理与终端可读性优化（图标、截断提示、提醒注入）

---

## 1. `text` 和 `content` 的区别

- `content` 是 message 层字段，例如：`{"role": "user", "content": [...]}`。
- `text` 是 `type: "text"` 这个 block 的字段，例如：`{"type": "text", "text": "..."}`。
- `tool_result` block 则使用 `content` 承载工具结果，例如：`{"type": "tool_result", "content": "..."}`。

结论：字段不是随意命名，而是由 block 类型决定。

---

## 2. `type` 能有多少种

在当前环境 `anthropic==0.92.0` 下，`ContentBlockParam` 可用 `type` 一共 16 种（会随 SDK/API 版本演进）：

1. `text`
2. `image`
3. `document`
4. `search_result`
5. `thinking`
6. `redacted_thinking`
7. `tool_use`
8. `tool_result`
9. `server_tool_use`
10. `web_search_tool_result`
11. `web_fetch_tool_result`
12. `code_execution_tool_result`
13. `bash_code_execution_tool_result`
14. `text_editor_code_execution_tool_result`
15. `tool_search_tool_result`
16. `container_upload`

说明：本文件当前主要手动构造的是 `text` 与 `tool_result` 两种。

---

## 3. `item.get(...)` 是什么取值方式

`item.get("text", "")` / `item.get("status", "pending")` 是字典的安全取值方式：

- key 存在：返回对应值
- key 不存在：返回默认值（不抛 `KeyError`）

再配合：

- `str(...)` 做类型归一
- `.strip()` 去首尾空白
- `.lower()` 统一大小写

整体是"容错 + 规范化"的输入处理。

---

## 4. `render()` 函数在做什么

`render()` 负责把 `self.items`（结构化任务列表）渲染成可读文本：

1. 若无任务，返回 `No todos.`
2. 按 `status` 映射图标并逐条拼接
3. 统计 completed 数量
4. 追加汇总行 `(done/total completed)`
5. 用 `"\n".join(lines)` 返回最终展示文本

它不修改状态，只做展示层转换。

---

## 5. `sum(1 for t in self.items if t["status"] == "completed")`

这行用于统计已完成任务数，等价于：

- 遍历每个任务
- 若状态是 `completed` 就记 1
- 最后把所有 1 相加

可视为"计数型生成器表达式"。

---

## 6. 为什么终端里看起来不是 5 个 todo

根因是日志输出被截断，不是任务缺失：

- `items` 里实际可能已有 5 条
- 但打印时按长度预览，超出部分不显示

因此会出现"参数里有 5 条，屏幕上只看到前几条"的视觉差异。

---

## 7. 终端输出优化点

本次对可读性做了几项改进：

- 状态图标从 `[ ]/[>]/[x]` 优化为 `🕒/🔄/✅`
- 命令输出增加预览阈值（当前示例为 400）
- 超限时追加提示：`...（已省略 N 个字符）`
- 连续多轮未更新 todo 时，输出红色提醒并注入 `<reminder>Update your todos.</reminder>`

这样既保留关键信息，又避免终端刷屏。

---

## 8. 设计取舍：为什么要显式 Todo

- 仅靠模型内部规划（chain-of-thought）虽然可行，但不可见且易失。
- extended thinking 也不便于用户和下游工具直接检查。
- 显式 Todo 让计划"可见、可追踪、可恢复"。

因此工程上更推荐"把计划写成结构化状态"。

---

## 9. 为什么 Todo 上限是 20

- 不设上限：灵活，但常导致过度细分、清单膨胀。
- 动态上限：更智能，但实现和维护复杂。
- 固定上限 20：简单稳定、经验有效；大多数真实编码任务可在 5-15 步表达清楚。

这是一个"工程上够好"的经验启发式。

---

## 可用例子

1. `Refactor the file hello.py: add type hints, docstrings, and a main guard`
2. `Create a Python package with __init__.py, utils.py, and tests/test_utils.py`
3. `Review all Python files and fix any style issues`
