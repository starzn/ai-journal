# s02_tool_use.py 学习记录

## 本次学习内容概览

这次主要围绕 `agents/s02_tool_use.py` 做了逐行理解与小幅可读性优化，重点包括：

- 工作目录 `WORKDIR` 的实际含义
- `safe_path` 的路径越界保护
- `run_read` 的读取与截断逻辑
- 工具调用日志输出的颜色高亮
- `TOOL_HANDLERS` 中 lambda 分发写法与 `**kw` 参数映射

---

## 1. `WORKDIR = Path.cwd()` 到底指哪里

代码位置：`L34`

- `Path.cwd()` 取的是“程序启动时的当前工作目录（CWD）”
- 它不是“当前 py 文件所在目录”
- 在当前环境下，默认工作目录是：
  - `/Users/venus/Desktop/learn-cc-0-1`
- 所以 `WORKDIR` 对应项目根目录，而不是 `/Users/venus/Desktop/learn-cc-0-1/agents`

补充对比：

- `Path.cwd()`：看你从哪里运行程序
- `Path(__file__).parent`：看文件本身所在目录

---

## 2. `if not path.is_relative_to(WORKDIR):` 的作用

代码位置：`L43`

这一行是路径安全检查，目的是防止访问工作区之外的文件。

流程是：

1. 先把用户给的相对路径拼到 `WORKDIR` 并 `resolve()`
2. 再判断该绝对路径是否仍位于 `WORKDIR` 下
3. 若不在，抛出异常：`Path escapes workspace`

这能阻止类似 `../../` 的路径穿越。

---

## 3. `run_read` 的核心逻辑（L69-L73）

代码片段作用可以概括为：**安全读取 + 按行限制 + 按字符限制**。

- `text = safe_path(path).read_text()`
  - 先通过 `safe_path` 校验路径，再读取文件
- `lines = text.splitlines()`
  - 将文本拆分为行列表
- `if limit and limit < len(lines): ...`
  - 如果设置了 `limit` 且小于总行数，只保留前 `limit` 行
  - 并追加一行 `... (N more lines)` 提示
- `return "\n".join(lines)[:50000]`
  - 最终返回时再做一次字符级截断，最多 50000 字符

---

## 4. 工具调用日志增加颜色（L172-L174）

已将三行工具日志输出加上 ANSI 颜色，提升终端可读性：

- 命令名称：紫色（`35`）
- 命令参数：黄色（`33`）
- 命令输出：绿色（`32`）

示意：

```python
print(f"\033[35m>命令名称：\033[0m {block.name}")
print(f"\033[33m>命令参数：\033[0m {block.input}")
print(f"\033[32m>命令输出：\033[0m {output[:200]}")
```

---

## 5. `TOOL_HANDLERS` 的 lambda 分发写法（L102-L111）

当前分发表把“工具名”映射到“处理函数”：

- `bash` -> `run_bash(kw["command"])`
- `read_file` -> `run_read(kw["path"], kw.get("limit"))`
- `write_file` -> `run_write(kw["path"], kw["content"])`
- `edit_file` -> `run_edit(kw["path"], kw["old_text"], kw["new_text"])`

这里的 `**kw` 表示把关键字参数收集成字典：

- key 是参数名
- value 是参数值

例如调用 `bash` 工具时，输入可能是 `{"command": "ls -la"}`，lambda 内就通过 `kw["command"]` 取值。

---

## 小结

`s02_tool_use.py` 在 `s01` 的基础上引入了多工具分发与文件操作能力。  
本次学习的关键收获是：目录安全边界（`WORKDIR + safe_path`）和输出可读性（颜色高亮）同样重要，它们分别提升了系统的安全性与可调试性。

## 可用例子
1.Read the file requirements.txt
2.Create a file called greet.py with a greet(name) function
3.Edit greet.py to add a docstring to the function
4.Read greet.py to verify the edit worked
