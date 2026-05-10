---
title: "s07 Task System"
published: 2025-03-13
description: "解析任务系统中从文件名提取任务 ID、JSON 序列化等核心实现。"
tags: [任务系统, JSON, 文件解析, 任务ID]
category: learn-cc-blogs
lang: zh_CN
---

# s07_task_system

## 1) 从文件名提取任务 ID

代码：

```python
ids = [int(f.stem.split("_")[1]) for f in self.dir.glob("task_*.json")]
```

含义：
- `self.dir.glob("task_*.json")`：匹配目录下所有 `task_*.json` 文件
- `f.stem`：取不带后缀的文件名（例如 `task_12`）
- `split("_")[1]`：取 `_` 后面的部分（`"12"`）
- `int(...)`：转成整数 `12`

最终得到所有任务文件的 ID 列表，例如 `[1, 2, 12]`。

## 2) `json.dumps` 和 `json.loads`

- `json.dumps(obj)`：把 Python 对象转成 JSON 字符串
- `json.loads(s)`：把 JSON 字符串转回 Python 对象

补充：
- `dump/load` 常用于文件对象
- `dumps/loads` 常用于字符串

例如 `json.loads(path.read_text())` 的意思是：先读取文件文本，再把 JSON 文本解析成 Python 对象。

## 3) 为什么 `glob` 后常配合 `sorted`

代码：

```python
files = sorted(
    self.dir.glob("task_*.json"), key=lambda f: int(f.stem.split("_")[1])
)
```

原因：
- `glob()` 只保证"匹配到哪些文件"，不保证返回顺序稳定
- `sorted()` 让处理顺序固定，结果可重复
- 使用 `key=int(...)` 是按数字排序，避免字符串排序问题（如 `1, 10, 2`）

最终返回的是排好序的 `Path` 列表。

## 4) dict 取值：下标 vs `get`

- 下标：`d[key]`
  - key 不存在会抛出 `KeyError`
- `get`：`d.get(key)` / `d.get(key, default)`
  - key 不存在返回 `None` 或默认值，不会报错

在状态映射场景里，`get` 更适合做兜底。

## 5) 列表推导式过滤依赖

代码：

```python
x for x in task["blockedBy"] if x not in remove_blocked_by
```

含义：
- 遍历 `task["blockedBy"]`
- 只保留不在 `remove_blocked_by` 中的元素

作用：从依赖列表里移除指定阻塞项。

## 例子

1. `Create 3 tasks: "Setup project", "Write code", "Write tests". Make them depend on each other in order.`
2. `List all tasks and show the dependency graph`
3. `Complete task 1 and then list tasks to see task 2 unblocked`
4. `Create a task board for refactoring: parse -> transform -> emit -> test, where transform and emit can run in parallel after parse`
