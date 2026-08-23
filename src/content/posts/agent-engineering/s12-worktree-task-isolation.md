---
title: "s12 Worktree 任务隔离"
published: 2025-03-23
description: "Git 仓库根目录检测、EventBus 事件日志与 Worktree 任务隔离。"
tags: [Worktree, Git, EventBus, 任务隔离]
category: Agent 工程实践
lang: zh_CN
---

# s12 Worktree 任务隔离

## 1. `detect_repo_root(cwd)` 函数作用

`detect_repo_root` 用来判断某个目录是否位于 Git 仓库中：

- 在 `cwd` 下执行 `git rev-parse --show-toplevel`
- 命令失败则返回 `None`
- 成功则读取仓库根目录路径并转为 `Path`
- 路径存在才返回该 `Path`，否则返回 `None`
- 任何异常（如超时、git 不可用）都统一返回 `None`

一句话：输入任意目录，输出该目录所属的 Git 仓库根目录；如果不在仓库内则返回空。

## 2. `EventBus` 代码段作用（L83-L120）

`EventBus` 是一个基于 JSONL 的轻量事件日志组件，核心目标是"可观测性"和"可追踪性"。

主要行为：

- 初始化时确保日志目录存在，不存在则创建空日志文件
- `emit(...)` 负责追加事件，每次写入一行 JSON
- 事件结构统一包含：
  - `event`（事件名）
  - `ts`（时间戳）
  - `task`（任务上下文，默认空对象）
  - `worktree`（工作树上下文，默认空对象）
  - `error`（可选，仅失败时写入）
- `list_recent(limit)` 读取最近 N 条日志（限制在 1~200）
- 单行解析失败时不会中断整体读取，而是产出 `parse_error` 占位项

一句话：`EventBus` 负责把任务/worktree 生命周期事件可靠地"追加记录并可回看"。

## 3. `WorktreeManager` 类作用（L238-L489）

`WorktreeManager` 是这个模块的核心编排器：负责 Git worktree 的创建、执行命令、状态查询、保留与移除，并和任务系统、事件系统打通。

它主要做了这些事：

- 管理 `.worktrees/index.json` 作为 worktree 元数据索引
- 校验当前是否处于 Git 仓库（`_is_git_repo`）
- 统一执行 git 子命令并处理失败（`_run_git`）
- 校验 worktree 名称格式（`_validate_name`）
- `create(...)`：创建 worktree + 分支，更新索引，可绑定任务，写 before/after/failed 事件
- `list_all()`：列出所有 worktree 概览
- `status(name)`：在指定 worktree 内执行 `git status --short --branch`
- `run(name, command)`：在指定 worktree 执行 shell 命令（带危险命令拦截与超时）
- `remove(...)`：移除 worktree，可选将绑定任务标记为完成，并写事件
- `keep(name)`：把 worktree 标记为 `kept`（保留）

一句话：它把"按任务隔离开发环境"的流程产品化了，便于并行开发和可审计收尾。

## 4. 关于 `worktree_remove` tool 是否删除 Git 分支

结论：**默认不会删除 Git 分支**。

原因：

- 该流程调用的是 `git worktree remove <path>`（可选 `--force`）
- 这会删除 worktree 工作目录，不等于删除分支
- `complete_task=true` 只影响任务状态，不会触发 `git branch -d/-D`

如果需要删除分支（例如 `wt/<name>`），要额外执行分支删除命令。

## 5. 示例（原样保留）

1. `Create tasks for backend auth and frontend login page, then list tasks.`
2. `Create worktree "auth-refactor" for task 1, then bind task 2 to a new worktree "ui-login".`
3. `Run "git status --short" in worktree "auth-refactor".`
4. `Keep worktree "ui-login", then list worktrees and inspect events.`
5. `Remove worktree "auth-refactor" with complete_task=true, then list tasks/worktrees/events.`
