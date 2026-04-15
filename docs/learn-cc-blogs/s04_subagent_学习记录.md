# s04_subagent.py 学习记录

## 本次学习内容概览

这次围绕 `agents/s04_subagent.py` 重点梳理了子智能体循环、作用域、工具参数 schema，以及日志输出格式化四个点，并完成了一处代码改造（将 task 日志改为 JSON 输出）。

---

## 1. 为什么这里是 `for _ in range(30)`

`run_subagent()` 里这段循环是一个安全上限（safety limit）：

- 当模型持续返回 `tool_use` 时，会不断进入“调用工具 -> 回填结果 -> 再请求模型”的链路
- 如果没有上限，可能出现长时间循环、token 消耗失控或异常卡住
- `30` 是工程经验值，不是语义硬要求，可按任务复杂度调整

结论：`30` 的目标是“防失控”，不是“必须精确 30 轮”。

---

## 2. 循环变量外面能不能拿到

这里要区分两类变量：

- 普通 `for` 循环中的变量（如 `response`）：在 Python 函数作用域内，循环后仍可访问
- 生成器/推导式内部变量（如 `"".join(... for b in ... )` 里的 `b`）：只在表达式内部可见，外部不可访问

所以 `return` 里使用 `response.content` 是合法的，它拿到的是最后一轮循环的 `response`。

---

## 3. `input_schema` 里 `"type": "string"` 看起来重复吗

不是重复，而是两个不同字段各自声明类型：

- `prompt` 的类型是 `string`
- `description` 的类型也是 `string`

同时，`description` 这个字段名本身和其内部的人类说明键 `"description": "Short description of the task"` 处于不同层级，语义也不同。

---

## 可用例子

1. `Use a subtask to find what testing framework this project uses`
2. `Delegate: read all .py files and summarize what each one does`
3. `Use a task to create a new module, then verify it from here`
