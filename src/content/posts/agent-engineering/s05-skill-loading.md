---
title: "s05 Skill Loading"
published: 2025-03-09
description: "梳理路径拼接、递归文件查找、正则解析 front matter 等核心知识点。"
tags: [Skill加载, pathlib, front matter, 递归查找]
category: Agent 工程实践
lang: zh_CN
---

# s05_skill_loading.py

## 本次内容概览

这次围绕 `agents/s05_skill_loading.py` 梳理了路径拼接、递归查找、正则解析 front matter、以及 Python 返回值 tuple 语法四个核心点，并完成了当前内容的一次提交。

---

## 1. `SKILLS_DIR = WORKDIR / "skills"` 是什么含义

这行是在使用 `pathlib.Path` 拼接目录路径，表示 `WORKDIR` 下的 `skills` 子目录。

- `WORKDIR / "skills"` 等价于 `WORKDIR.joinpath("skills")`
- `/` 在这里是 `Path` 重载后的运算符，不是普通字符串里的斜杠
- 两边保留空格是 Python 风格规范（PEP 8）中对二元运算符的推荐写法

---

## 2. `for f in sorted(self.skills_dir.rglob("SKILL.md")):` 在做什么

这行表示：从 `self.skills_dir` 开始递归搜索所有名为 `SKILL.md` 的文件，然后按排序后的稳定顺序逐个遍历。

- `rglob("SKILL.md")`：递归搜索匹配文件名
- `sorted(...)`：保证遍历顺序固定，避免不同环境下顺序不一致
- `for f in ...`：每次循环拿到一个技能文件路径

---

## 3. `re.match(r"^---\n(.*?)\n---\n(.*)", text, re.DOTALL)` 的作用

这行用于把文档文本按"front matter + 正文"结构拆分。

- `^---\n`：要求文本从 `---` 开始
- `(.*?)`：非贪婪捕获 front matter 内容
- `\n---\n`：匹配分隔结束线
- `(.*)`：捕获后续全部正文
- `re.DOTALL`：让 `.` 可以跨行匹配

若匹配成功：

- `match.group(1)` 是 front matter
- `match.group(2)` 是正文

若匹配失败，`match` 为 `None`。

---

## 4. `return {}, text` 没有括号为什么也是 tuple

在 Python 中，tuple 的关键是逗号，不是括号。

- `return {}, text` 会返回二元组
- `return ({}, text)` 与上面语义一致
- 单元素 tuple 必须写成 `(x,)`

在该函数中，`return {}, text` 和 `return meta, match.group(2).strip()` 都是返回二元组。

---

## 5. 本次提交记录

已完成提交，提交信息如下：

- commit: `b5f3a1f`
- message: `feat(agents): 添加技能加载示例与skills目录`
- 状态：工作区干净

---

## 可用例子

1. `Use a subtask to find what testing framework this project uses`
2. `Delegate: read all .py files and summarize what each one does`
3. `Use a task to create a new module, then verify it from here`
