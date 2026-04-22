---
title: "s01 Agent Loop 学习记录"
published: 2025-03-01
description: "最小可运行的 AI Agent Loop 示例学习笔记，解析核心循环流程。"
tags: [Agent Loop, Anthropic API, tool_use, Python]
category: learn-cc-blogs
lang: zh_CN
---

# s01_agent_loop.py 学习记录

## 文件定位

- 该文件是一个最小可运行的 AI Agent Loop 示例。
- 核心模式是：模型请求工具 -> 执行工具 -> 回传 `tool_result` -> 继续下一轮，直到模型不再请求工具。
- 关键循环在 `agent_loop(messages)` 中。

## 核心流程

1. 用户在终端输入问题。
2. 程序调用 Anthropic Messages API。
3. 如果返回 `tool_use`，就执行对应的 bash 命令。
4. 把执行结果作为 `tool_result` 追加到消息历史。
5. 再次调用模型，直到 `stop_reason != "tool_use"`。

## 导入包说明

- `os`：读取环境变量、获取当前目录、处理环境配置。
- `subprocess`：执行 shell 命令并获取输出。
- `readline`：增强终端输入体验；在 macOS 下通常会经过 libedit。
- `anthropic.Anthropic`：Anthropic 官方 Python SDK 客户端。
- `dotenv.load_dotenv`：从 `.env` 加载环境变量。

## libedit 是什么

- `libedit`（EditLine）是命令行行编辑库，功能类似 GNU readline。
- 它负责终端输入时的光标移动、历史记录、退格等行为。
- 在 macOS 上，Python 的 `readline` 常常实际连接到 libedit，所以会看到兼容性设置。

## 关键代码讲解

### 1) 工具定义 `TOOLS`

- 这里只注册了一个工具 `bash`。
- 输入 schema 要求一个字段：`command: string`。

### 2) `run_bash` 的执行逻辑

- 先做简单危险命令拦截，命中后直接返回错误文本。
- `subprocess.run(..., shell=True, capture_output=True, text=True, timeout=120)`：
  - `shell=True` 支持管道和重定向等 shell 语法；
  - `capture_output=True` 捕获 stdout/stderr；
  - `text=True` 返回字符串；
  - `timeout=120` 控制超时。
- `out = (r.stdout + r.stderr).strip()` 合并标准输出与错误输出。
- `return out[:50000] if out else "(no output)"` 限制输出长度并处理空输出。

### 3) 为什么要遍历 `response.content`

- `response.content` 是内容块列表，不是单一字符串。
- 列表里可能混合 `text` 块和 `tool_use` 块。
- 一次响应可能包含多个 `tool_use`，所以必须循环处理并逐个返回 `tool_result`。

### 4) 输入提示符这一行

- `query = input("\033[36ms01 >> \033[0m")`
- 作用是显示青色提示符 `s01 >>` 并读取用户输入。
- `\033[36m` 设置颜色，`\033[0m` 重置颜色。

### 5) `L114-L120` 代码作用

- 先调用 `agent_loop(history)` 完成一轮代理循环。
- 取最后一条消息 `history[-1]["content"]`。
- 若内容是列表，则遍历并打印有 `text` 属性的块。
- 末尾 `print()` 仅用于输出换行，提高终端可读性。

## block list 示例

```text
assistant response
└── content (list)
    ├── block[0]: { type: "text", text: "我先查看目录" }
    ├── block[1]: { type: "tool_use", id: "toolu_01", name: "bash", input: { command: "pwd" } }
    ├── block[2]: { type: "tool_use", id: "toolu_02", name: "bash", input: { command: "ls -la" } }
    └── block[3]: { type: "text", text: "拿到输出后继续分析" }
```

对应回传：

```json
[
  { "type": "tool_result", "tool_use_id": "toolu_01", "content": "/path" },
  { "type": "tool_result", "tool_use_id": "toolu_02", "content": "total ..." }
]
```

## 如何运行程序（Mac）

```bash
cd /Users/venus/Desktop/learn-cc-0-1
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export ANTHROPIC_API_KEY="你的key"
export MODEL_ID="可用模型ID"
python agents/s01_agent_loop.py
```

可选代理配置：

```bash
export ANTHROPIC_BASE_URL="你的base_url"
```

退出方式：输入 `q` / `exit` / 空行，或按 `Ctrl+C`、`Ctrl+D`。

## 一段真实交互的输入输出分析

示例：

```text
s01 >> Create a file called hello.py that prints "Hello, World!"
$ echo 'print("Hello, World!")' > /Users/venus/Desktop/learn-cc-0-1/hello.py
(no output)
The file `hello.py` has been created with `print("Hello, World!")`.
```

逐行解释：

- 第一行是用户输入提示符与任务文本。
- 第二行是模型触发的 `tool_use` 命令，代理将命令打印到终端。
- 第三行 `(no output)` 来自 `run_bash`：重定向写文件通常没有 stdout/stderr，所以会显示该占位文本。
- 第四行是模型在接收到工具结果后给出的自然语言总结。

为什么 `(no output)` 依然可能成功：

- `echo ... > 文件` 的成功标志通常是没有报错，而不是有输出。
- 该命令的主要效果是写入文件内容，不是向终端打印内容。

可手动验证：

```bash
cat /Users/venus/Desktop/learn-cc-0-1/hello.py
python3 /Users/venus/Desktop/learn-cc-0-1/hello.py
```

## ANSI 转义序列说明（`\033[33m`）

- `\033[33m` 是 ANSI 控制序列，用于设置终端文字样式。
- `\033` 是 ESC（转义字符），`[33m` 表示把前景色设为黄色。
- `\033[0m` 用于重置样式，避免影响后续输出。

在本文件中的用途：

- `print(f"\033[33m$ {block.input['command']}\033[0m")`：把将要执行的命令高亮为黄色。
- `input("\033[36ms01 >> \033[0m")`：把输入提示符显示为青色（`36`）。

常见颜色码：

- `31` 红色
- `32` 绿色
- `33` 黄色
- `34` 蓝色
- `36` 青色
- `0` 重置

## Terminal#194-210 对话 history 与解析

原始会话：

```text
s01 >> Create a file called hello.py that prints "Hello, World!"
$ echo 'print("Hello, World!")' > /Users/venus/Desktop/learn-cc-0-1/hello.py
(no output)
The file `hello.py` has been created with `print("Hello, World!")`.

s01 >> List all Python files in this directory
$ find /Users/venus/Desktop/learn-cc-0-1 -maxdepth 1 -name "*.py" -type f
/Users/venus/Desktop/learn-cc-0-1/hello.py
There is one Python file in the directory:

- `hello.py`

s01 >> What is the current git branch?
$ cd /Users/venus/Desktop/learn-cc-0-1 && git branch --show-current
main
The current git branch is `main`.
```

按 `history` 的角色可拆成三轮：

1) 第 1 轮（创建文件）
- user：创建 `hello.py` 并打印 "Hello, World!"
- assistant(tool_use)：执行 `echo ... > hello.py`
- user(tool_result)：`(no output)`
- assistant(text)：确认文件已创建

2) 第 2 轮（列出 Python 文件）
- user：列出目录下所有 Python 文件
- assistant(tool_use)：执行 `find ... -name "*.py" -type f`
- user(tool_result)：返回 `/Users/venus/Desktop/learn-cc-0-1/hello.py`
- assistant(text)：总结当前只有 `hello.py`

3) 第 3 轮（查询 git 分支）
- user：询问当前 git branch
- assistant(tool_use)：执行 `git branch --show-current`
- user(tool_result)：返回 `main`
- assistant(text)：总结当前分支是 `main`

适当解析：

- 这是同一个 `history` 贯穿多轮问答的典型模式，每轮都会在历史里追加新的 user/assistant 消息块。
- 命令输出会先由代理打印一份摘要（如 `(no output)` 或前若干字符），再以 `tool_result` 返回给模型。
- 模型最后给出的自然语言结论，本质上是对 `tool_result` 的解释与归纳。
- 这三轮分别覆盖了"写文件""查文件""查仓库状态"，展示了 bash 工具在代理中的基础能力闭环。

### 原始核心 history 列表（还原版）

下面是根据 Terminal 按 `messages/history` 结构还原的核心列表（示意，`tool_use_id` 为示例）：

```json
[
  { "role": "user", "content": "Create a file called hello.py that prints \"Hello, World!\"" },
  {
    "role": "assistant",
    "content": [
      {
        "type": "tool_use",
        "id": "toolu_create_1",
        "name": "bash",
        "input": {
          "command": "echo 'print(\"Hello, World!\")' > /Users/venus/Desktop/learn-cc-0-1/hello.py"
        }
      }
    ]
  },
  {
    "role": "user",
    "content": [
      {
        "type": "tool_result",
        "tool_use_id": "toolu_create_1",
        "content": "(no output)"
      }
    ]
  },
  {
    "role": "assistant",
    "content": [
      {
        "type": "text",
        "text": "The file `hello.py` has been created with `print(\"Hello, World!\")`."
      }
    ]
  },

  { "role": "user", "content": "List all Python files in this directory" },
  {
    "role": "assistant",
    "content": [
      {
        "type": "tool_use",
        "id": "toolu_list_1",
        "name": "bash",
        "input": {
          "command": "find /Users/venus/Desktop/learn-cc-0-1 -maxdepth 1 -name \"*.py\" -type f"
        }
      }
    ]
  },
  {
    "role": "user",
    "content": [
      {
        "type": "tool_result",
        "tool_use_id": "toolu_list_1",
        "content": "/Users/venus/Desktop/learn-cc-0-1/hello.py"
      }
    ]
  },
  {
    "role": "assistant",
    "content": [
      {
        "type": "text",
        "text": "There is one Python file in the directory:\n\n- `hello.py`"
      }
    ]
  },

  { "role": "user", "content": "What is the current git branch?" },
  {
    "role": "assistant",
    "content": [
      {
        "type": "tool_use",
        "id": "toolu_git_1",
        "name": "bash",
        "input": {
          "command": "cd /Users/venus/Desktop/learn-cc-0-1 && git branch --show-current"
        }
      }
    ]
  },
  {
    "role": "user",
    "content": [
      {
        "type": "tool_result",
        "tool_use_id": "toolu_git_1",
        "content": "main"
      }
    ]
  },
  {
    "role": "assistant",
    "content": [
      {
        "type": "text",
        "text": "The current git branch is `main`."
      }
    ]
  }
]
```

说明：

- 该结构对应代码中的 `history.append(...)` 与 `messages.append(...)` 逻辑。
- 真正运行时 `id/tool_use_id` 由模型实时生成，不会固定为上面的示例值。
- 你在终端看到的 `$ 命令` 和简短输出，是代理的打印行为；history 里保存的是结构化内容块。

### history 与源码行号对照

为了把"终端现象"和"代码行为"对上，可以按下面对应关系看：

- 用户输入进入 `history`：`history.append({"role": "user", "content": query})`（`s01_agent_loop.py` 第 120 行）
- 发送模型请求：`client.messages.create(...)`（第 86-89 行）
- assistant 原始内容块入历史：`messages.append({"role": "assistant", "content": response.content})`（第 91 行）
- 发现工具调用：`for block in response.content` + `if block.type == "tool_use"`（第 99-100 行）
- 终端打印 `$ 命令`：`print(f"\033[33m$ ...")`（第 101 行）
- 执行命令并拿输出：`output = run_bash(...)`（第 102 行）
- 终端打印输出摘要：`print(output[:200])`（第 104 行）
- 工具结果回写历史：`results.append({"type":"tool_result", ...})`（第 105-106 行）
- 把 `tool_result` 作为 user 消息喂回模型：`messages.append({"role":"user","content":results})`（第 107 行）
- 无工具调用则结束循环：`if response.stop_reason != "tool_use": return`（第 93-94 行）
- 打印最终文本回答：遍历最后一条 `response_content` 的 text block 并 `print(block.text)`（第 123-127 行）

### 一轮最小生命周期（对应 history 增长）

每次你输入一个任务，`history` 至少会增长 2 条，常见会增长 4 条：

1. `user`：自然语言任务
2. `assistant`：包含 `tool_use` 的内容块（若需要工具）
3. `user`：`tool_result` 内容块（由程序自动追加）
4. `assistant`：最终文本答复

如果该任务不需要工具，则通常只有：

1. `user`
2. `assistant(text)`

## 子代理委派（进程级 vs 框架级）总结

### 1) 进程级子代理是什么

当父代理执行 `python v0.py "subtask"` 时，本质是启动一个新进程。这个新进程会：

- 拥有独立内存空间与运行时状态；
- 重新初始化自己的 system prompt、messages 与任务上下文；
- 独立完成该子任务后，通过 stdout 把结果返回父进程。

这就是最原始的"子代理委派"：不依赖专门框架能力，仅依赖 Unix 进程语义。

### 2) 为什么说"天然隔离关注点"

- 子进程默认看不到父进程的对话历史与临时状态；
- 父子之间只交换显式输入输出（参数/stdin 与 stdout）；
- 因此子任务不会被父任务上下文噪声污染，更专注当前目标。

这类隔离是操作系统提供的，不需要额外实现共享内存隔离策略。

### 3) "no shared memory, no message passing, just stdin/stdout" 的含义

这句话强调的是最小通信面：

- 不使用进程内共享内存；
- 不引入复杂 IPC/RPC 编排；
- 只把子代理当作命令行程序：输入任务，读取输出，检查退出码。

它的教学意义在于：先理解子代理的最小可行形态，再考虑工程化增强。

### 4) 与框架级子代理（如 Task tool）对比

进程级（v0）优势：

- 实现简单，几乎零依赖；
- 隔离强，默认边界清晰；
- 适合演示代理委派的底层本质。

进程级（v0）局限：

- 工具权限控制粒度较粗；
- 结果结构化与可观测性较弱；
- 多子任务编排与容错逻辑需要手写。

框架级（如 v3 Task）优势：

- 可细粒度限制子代理可用工具与资源；
- 返回结构更规范，便于自动消费；
- 生命周期、审计、重试、追踪等能力更完善。

一句话：v0 展示"能工作"的最小原理，框架级方案解决"可控、可管、可扩展"的工程问题。

## 可用例子
1. `Create a file called hello.py that prints "Hello, World!"`
2. `List all Python files in this directory`
3. `What is the current git branch?`
4. `Create a directory called test_output and write 3 files in it`
