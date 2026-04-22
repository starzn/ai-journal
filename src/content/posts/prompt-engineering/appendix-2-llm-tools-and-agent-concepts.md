---
title: "LLM 工具使用与 Agent 相关概念笔记"
published: 2025-02-15
description: "系统辨析 ReAct、Chain-of-Thought、Tool Use、Function Calling、MCP 等 Agent 相关概念。"
tags: [ReAct, Function Calling, MCP, Agent]
category: prompt-engineering
lang: zh_CN
---
# LLM 工具使用与 Agent 相关概念笔记

## 目录
- [1. ReAct 和 Chain-of-Thought 的区别](#1-react-和-chain-of-thought-的区别)
- [2. ReAct 和 Agent 的关系](#2-react-和-agent-的关系)
- [3. ReAct、Tool Use、Function Calling 三者的区别](#3-reacttool-usefunction-calling-三者的区别)
- [4. MCP 和 Tool Use 的关系](#4-mcp-和-tool-use-的关系)
- [5. Function Calling 是不是模型自己生成代码并调用](#5-function-calling-是不是模型自己生成代码并调用)
- [6. Function Calling 和 MCP 的具体关系](#6-function-calling-和-mcp-的具体关系)
- [7. 在 MCP 协议出来之前，是怎么调用工具的](#7-在-mcp-协议出来之前是怎么调用工具的)
- [8. 总结：这些概念的层级关系](#8-总结这些概念的层级关系)
- 自动写提示词的agent：https://github.com/langgptai/LangGPT/blob/main/Docs/HowToWritestructuredPrompts.md

---

## 1. ReAct 和 Chain-of-Thought 的区别

### 1.1 核心差异
- **Chain-of-Thought（CoT）**：强调**逐步推理**
- **ReAct**：强调**推理 + 行动 + 观察反馈**

一句话：

> CoT 是“把思考过程写出来”，ReAct 是“把思考过程和行动过程交替写出来”。

---

### 1.2 结构区别

#### Chain-of-Thought
典型结构：

```text
Question -> Thought -> Thought -> Answer
```

特点：
- 主要依赖模型内部知识
- 通常不访问外部环境
- 更像“坐着想”

---

#### ReAct
典型结构：

```text
Question -> Thought -> Action -> Observation -> Thought -> Answer
```

特点：
- 可以调用工具、搜索、查询环境
- 根据外部反馈调整后续推理
- 更像“边想边查边做”

---

### 1.3 适用场景

#### CoT 更适合
- 数学题
- 逻辑题
- 已知信息足够的文本推理任务

#### ReAct 更适合
- 开放域问答
- 事实验证
- 多步检索
- 交互式任务
- Agent 场景

---

### 1.4 错误模式差异
#### CoT
- 可能在错误前提上推得很顺
- 容易产生幻觉
- 错一步可能后面全错

#### ReAct
- 可能选错工具或查偏
- 但更容易通过外部反馈纠正
- 可解释性更强

---

## 2. ReAct 和 Agent 的关系

### 2.1 一句话定义
> **ReAct 是 Agent 常用的一种推理-行动循环框架，Agent 是更完整的智能体系统。**

---

### 2.2 什么是 Agent
Agent 一般包含：

- **目标**：要完成什么
- **感知**：接收用户输入、环境反馈、工具结果
- **推理/规划**：决定下一步
- **行动**：调用工具、执行操作
- **记忆**：保存上下文与历史
- **反馈循环**：根据结果调整策略

所以：

> Agent 是一个完整系统概念。

---

### 2.3 什么是 ReAct
ReAct 是一种让模型按以下方式工作的框架：

```text
Thought -> Action -> Observation -> Thought -> ...
```

它更像：
- Agent 的决策模式
- 一种轨迹格式
- 一种 prompting / control pattern

---

### 2.4 两者关系
- **Agent = 系统**
- **ReAct = Agent 内部常用的工作方式**

可以理解为：
- Agent 是“机器人”
- ReAct 是“机器人思考和行动的方法”

---

### 2.5 ReAct 对 Agent 的价值
ReAct 帮 Agent：
- 显式地表达为什么调用某个工具
- 把行动组织得更结构化
- 把工具结果纳入推理循环
- 降低幻觉
- 提升可解释性

---

### 2.6 ReAct 不是完整 Agent
完整 Agent 往往还包括：
- 长期记忆
- 任务分解
- 多工具路由
- 反思（reflection）
- 计划器（planner）
- 安全与权限控制
- 多 Agent 协作

所以：

> ReAct 可以是 Agent 的核心循环，但 Agent 通常比 ReAct 更复杂。

---

## 3. ReAct、Tool Use、Function Calling 三者的区别

### 3.1 一句话总结
- **ReAct**：一种**推理 + 行动**的工作范式
- **Tool Use**：一种**使用外部工具的能力/行为**
- **Function Calling**：一种**结构化调用工具的接口机制**

---

### 3.2 ReAct
关注的是：

> 模型应该怎么思考、什么时候调用工具、如何根据结果继续思考。

结构：

```text
Thought -> Action -> Observation
```

它是**策略层 / 轨迹层**概念。

---

### 3.3 Tool Use
关注的是：

> 模型能不能借助外部能力完成任务。

典型工具包括：
- 搜索
- 计算器
- 数据库
- 浏览器
- 文件系统
- 代码执行环境

它是**能力层 / 行为层**概念。

---

### 3.4 Function Calling
关注的是：

> 模型如何用结构化格式表达对某个工具的调用。

典型形式：

```json
{
  "name": "get_weather",
  "arguments": {
    "city": "Shanghai"
  }
}
```

它是**接口层 / 实现层**概念。

---

### 3.5 三者的层级关系
可以记成：

- **ReAct 管流程**
- **Tool Use 管能力**
- **Function Calling 管接口**

---

### 3.6 它们如何协作
一个系统里可能这样配合：

1. 用户提出任务
2. 模型分析需求
3. 模型决定是否需要工具
4. 如果需要，发起 Function Calling
5. 系统执行工具
6. 把结果返回给模型
7. 模型继续推理并回答

对应：
- 步骤 2、3、6、7：偏 **ReAct**
- 步骤 4、5：偏 **Function Calling**
- 整个借助外部工具的过程：属于 **Tool Use**

---

## 4. MCP 和 Tool Use 的关系

### 4.1 一句话总结
> **Tool Use 是“模型会不会用工具”，MCP 是“工具如何标准化地提供给模型使用”。**

---

### 4.2 Tool Use 是什么
Tool Use 指模型借助外部工具完成任务，比如：
- 搜索网页
- 查询数据库
- 调天气 API
- 执行代码
- 读取文件

本质是：

> 使用外部能力。

---

### 4.3 MCP 是什么
MCP 通常指 **Model Context Protocol**。

它的目标是：

> 用统一协议把工具、资源、上下文标准化地暴露给模型或 Agent。

它更像：
- 工具接入标准
- 上下文交换协议
- 标准化能力层

---

### 4.4 两者的区别
- **Tool Use** 关注：模型是否在“使用工具”
- **MCP** 关注：工具如何“被标准化接入”

所以：
- Tool Use 是行为能力
- MCP 是基础设施协议

---

### 4.5 它们的关系
> **MCP 是实现 Tool Use 的一种标准化方式。**

没有 MCP 也能 Tool Use。  
有了 MCP，Tool Use 更统一、更可扩展、更容易复用。

---

## 5. Function Calling 是不是模型自己生成代码并调用

### 5.1 结论
> **不是。**

Function Calling 通常不是“模型自己写代码并执行”，而是：

> 模型以结构化格式表达“我要调用哪个函数、参数是什么”，真正执行的是外部系统。

---

### 5.2 Function Calling 的本质
模型输出这样的结构：

```json
{
  "name": "get_weather",
  "arguments": {
    "city": "Shanghai"
  }
}
```

然后由宿主程序：
1. 读取函数名和参数
2. 调用真实函数
3. 获取结果
4. 把结果再交还给模型

---

### 5.3 和“代码生成执行”的区别

#### Function Calling
输出的是：
- 函数名
- 参数
- 结构化请求

优点：
- 安全性高
- 可控
- 参数清晰
- 便于权限管理

---

#### 代码生成执行
输出的是一段代码，例如 Python：

```python
result = get_weather("Shanghai")
print(result)
```

然后系统执行这段代码。

特点：
- 更灵活
- 但风险更高
- 更难约束

---

### 5.4 更准确的说法
> Function Calling 是模型生成结构化调用请求，而不是亲自运行函数代码。

---

## 6. Function Calling 和 MCP 的具体关系

### 6.1 一句话总结
> **MCP 负责把工具标准化提供出来，Function Calling 负责让模型在运行时调用具体工具。**

---

### 6.2 各自解决的问题

#### Function Calling 解决
> “模型已经决定要调用工具了，那么这次调用如何表达？”

它解决的是**单次调用表达问题**。

---

#### MCP 解决
> “系统里有哪些工具和资源？它们如何被统一接入并发现？”

它解决的是**工具生态接入和描述问题**。

---

### 6.3 协作方式
一个典型流程：

1. **MCP Server** 暴露工具和资源
2. **客户端 / Agent Runtime** 发现这些能力
3. 客户端将工具描述整理后提供给模型
4. 模型通过 **Function Calling** 发起具体调用
5. 客户端执行对应 MCP tool
6. 结果返回模型
7. 模型继续输出答案

---

### 6.4 层次关系
可以这样看：

#### 资源/工具提供层
- MCP 起作用

#### 调用表达层
- Function Calling 起作用

#### 推理决策层
- ReAct / Agent loop 起作用

---

### 6.5 一个关键点
MCP 不一定只包含工具，还可能包括：
- `tools`
- `resources`
- `prompts`
- 其他上下文交换能力

所以：
- **Function Calling 更窄**
- **MCP 更广**

---

## 7. 在 MCP 协议出来之前，是怎么调用工具的

### 7.1 一句话总结
> 在 MCP 出现之前，工具照样能调用，只是通常没有统一的跨平台标准，更多依赖手工适配、平台私有协议、框架自定义接口等方式。

---

### 7.2 常见做法

#### 方式一：手工定义函数并让模型调用
开发者自己定义工具：

```python
def get_weather(city: str): ...
def search_docs(query: str): ...
```

然后把这些工具的描述提供给模型。  
模型输出函数名和参数，系统再去执行。

---

#### 方式二：文本命令解析
例如让模型输出：

```text
Action: Search[上海天气]
```

或者：

```text
TOOL: weather
ARGS: {"city": "Shanghai"}
```

程序再解析这些文本并执行工具。

这是早期 ReAct-style agent 的常见方式。

---

#### 方式三：插件系统 / 平台私有协议
不同平台会提供：
- 插件 manifest
- API 描述
- 调用规范
- 鉴权机制

这些也能支持工具调用，但通常不通用。

---

#### 方式四：Agent 框架自带 Tool 抽象
很多 Agent 框架会定义自己的 Tool 类或接口，例如：
- `name`
- `description`
- `input_schema`
- `run()`

这解决了框架内部的一致性问题，但框架之间不互通。

---

#### 方式五：直接硬编码业务逻辑
有些系统甚至不让模型自由选择工具，而是程序直接写死流程：

1. 识别用户意图
2. 如果是天气问题，就直接调用天气 API
3. 把结果交给模型润色

这也是 Tool Use，只是模型不主导调用。

---

### 7.3 MCP 出现前的主要问题
不是“不能调用工具”，而是“没有统一标准”，具体包括：

- 工具描述格式不统一
- 框架之间不互通
- 工具发现机制弱
- 资源与工具往往混杂
- 重复造轮子严重

---

### 7.4 MCP 带来的变化
MCP 的价值不是发明 Tool Use，而是让它更加：
- 标准化
- 可发现
- 可复用
- 可扩展
- 跨平台

---

## 8. 总结：这些概念的层级关系

### 8.1 一张总图

```text
用户任务
   ↓
Agent / ReAct 决策循环
   ↓
模型决定是否调用工具
   ↓
Function Calling 表达具体调用
   ↓
客户端 / Runtime 执行调用
   ↓
工具 / 资源来源（可通过 MCP 标准化暴露）
   ↓
结果返回模型
   ↓
模型继续推理并输出答案
```

---

### 8.2 最简层级记忆法

#### ReAct
- 是一种**推理-行动流程**
- 关注“什么时候想、什么时候做”

#### Agent
- 是一种**完整智能体系统**
- 关注“如何完成目标任务”

#### Tool Use
- 是一种**使用外部能力的行为**
- 关注“模型能做什么”

#### Function Calling
- 是一种**结构化调用机制**
- 关注“如何调用”

#### MCP
- 是一种**标准化接入协议**
- 关注“能力如何统一暴露和发现”

---

### 8.3 记忆口诀
> **ReAct 管流程，Agent 管系统，Tool Use 管能力，Function Calling 管调用，MCP 管接入。**

---

## 9. 最终一句话总结

> 在现代 LLM 系统中，Agent 负责整体任务完成，ReAct 常作为其推理-行动循环；Tool Use 表示模型具备借助外部能力的能力；Function Calling 让模型用结构化方式发起具体调用；MCP 则进一步把这些工具和资源以统一标准接入系统。

