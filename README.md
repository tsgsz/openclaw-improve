# Openclaw 增强形态

这是一个用于作为全面的个人助手的 Openclaw 的增强形态。

## 增强 Spawn 过程 与 监控

监听 subagent_spawning 事件，强制选择 project, 以及 ETA。
除了 原生的 run.json, 增加一个 runtime.json, 在里面持久化存 task, 记录状态（运行中，完成，失败），延长次数，当前ETA

1. 状态：对比原生的run.json, runtime.json会持久化记录更多的任务，已经在run.json中不存在的任务，应该要么变成完成，要么变成失败，当前运行时间已经超过ETA的任务，应该交给 watchdog 去检查。
2. 当前ETA：在每次任务开始之前，会指定 Timeout值 和 ETA 值，如果执行超过 ETA，但是没有到 Timeout, 会由 watchdog 重新预估 ETA，并且写入当前ETA，每改一次都要在延长次数+1.
3. 状态通知：当 watchdog 发现任务任务已经完成或者延长或者失败，都要主动通知原渠道，告知相应情况（用session_send)，并且让 orch 自己决定要不要告诉main，还是打算重试。

由此可见， 需要有 HOOKS 进行 SPAWNING 进行监听， 以及有一个系统脚本来轮询监听 runtime.json 来决定要不要 启动 watchdog 进行特定 session 的检查，以及 watchdog 来明确检测逻辑。

## WorkingDir 选择

当 Spawn 的时候，需要显示的指定 WorkingDir，用于子Agent 来写执行写文件操作（子Agent只允许在 WorkingDir的范围内 和 自己的workspace/sessionid/ 下写，但是整个电脑都可以随便读）。

WorkingDir的选择有如下原则，应该通过skill+脚本落地，通过skill来触发（或者做成Plugin的tools)。

WorkingDir本质上是项目管理，因此要有一个脚本进行：项目创建/项目注册，项目查询，项目删除，项目数.

项目分为永久项目和临时项目，临时项目应该在外部有脚本定期清理。

当创建项目的时候，Agent应该要主动问用户这是一个临时项目还是一个永久项目。并在 ~/.openclaw/workspace/projects/project.json 中记录。永久项目的名字要找用户确认。

project.json 中应该记录：项目名字，是否用户显示创建，创建时间，是否永久，项目路径，简要描述。

project 的选择原则如下：

1. 用户显示指定（名字，路径，尽可能匹配，如果不确定要问用户确定，优先永久项目）
2. 用户未指定，语义上可能属于某个永久项目，如果不确定则找用户确认
3. 用户未指定，语义上可能属于某个临时项目，一天内的直接匹配，超过一天新建新的临时项目

永久项目自动目录算法：~/workspace/<project-name)
临时项目自动目录算法：~/.openclaw/workspace/projects/tmp-projects/<project-name>

所有的项目创建后如果没有 git 应该 git init. 

其中永久项目应该同步至 github.

orch应该在任务完成后总结，更新 README.md, 并执行git commit.

此处也需要 有HOOKS 进行 message_preprocessed的监听，为message加上<project: project-name|no-project|project-unsure>的的标签供 main 处理。

## Agent 设计

### 规范

Agent 应该分为 functional 和 domain 两种类型。各自的 workspace 应放在 ~/.openclaw/workspace/functional-workspace|domain-workspace/<agent-name>下。

#### functional Agent

功能性 agent 主要用于将大段的，功能内聚的context进行接管和探索，最终输出可用结果，用于上一层 agent 的 context 压缩。
都可以 session-send 用于确认信息。

##### orchestrator (claude opus4.6 或者 gpt4)

用于承接 main 给过来的具体工作。main只可以调用它。

当 main 拿到任何不能通过自己的LLM直接回答，而是超过2轮工具调用的任务时，会 spawn一个 orchestrator 来应对。

orchestrator 会自己根据parentSessionKey 来看 main发出的session的上下文来获取相应信息。

1. 特有工具、技能：获取当前任务之前的main的上下文的工具。获取main的memory的工具。发布脚本技能。发布markdown,图片等技能。
2. 特有流程：
    a. 查看相关的上下文和 Memory -> 使用技能 using-superpowers 和 planing-with-files -> 循环进行，直到任务结束 -> 总结，commit，announce.
    b. 复杂流程：查看相关的上下文和 Memory -> 使用技能 using-superpowers 和 planing-with-files -> 循环执行，直到任务结束 -> review -> 重复执行（若无意见则通过，若不通过则任务重复，轮次增加最多三轮），再三选1）-> 总结，commit， 

##### professor（k2p5 或者 minimax)

用于承载 研究，网络搜索相关的任务。

1. 特有习惯：更偏好高置信度网站。不计一切代价完成目标，当 web-search 限流或者是 webfetch失败的时候，会使用agentreach, 浏览器尝试，换个类似的网址等等各种手段尝试。如果实在完成不了，会把问题抛给 orchestrator.

##### systemhelper（k2p5 或者 gpt4)

用于承载系统的搜索和尝试，调试等任务。

在 Agent的执行过程中，涉及到Grep，ls等可能的大段内容的匹配查看，或者是需要对某个工具进行调试（比如需要登录，或者是报错），orchestrator会交给他。他会给出最终结果或者是调试好。

1. 特有习惯：在调试时默认只读工作， 当只读工作都尝试过了且不成功时，可以找 orchestrator 申请权限。除非 orchestrator 明确告知任务需要进行改动。

##### scriptproducer（gptcodex5.3 或者 minimax2.5）

用于编写和管理脚本。当 orchestrator 需要编写某些脚本来完成任务时，会交给他来做，他会先去~/.openclaw/workspace/scripts, skills 以及 ~/.openclaw/scirpts/ 下去看看是否有可以复用的。

如果没有就编写一个新的。他写脚本会更愿意把参数抽象出来从外面传入。

他回复给 orchestrator 的时候要给出在当前任务场景下的完整使用方法。

##### reviewer(gemini3）

当 orchestrator 认为任务比较困难的时候，会引入 reviewer 来进行 review，orchestrator 会指定 reviewer 要从哪些方面来进行 review.

##### watchdog(minimax2.1)

watchdog用来跟进跟openclaw自身相关的状态等问题。例如 session_list 等应该交给 watchdog 来搜索.

1. 特有技能：session监控：用于监控特定session_id 或者 session_key 的状态，做出判断，`详见 增强 Spawn 过程 与 监控` 一节。

##### acp(opencode)

opencode 会用来进行严肃任务的迭代。


#### domain agent

用于专业领域的事情，由 skill 触发。

##### ops(minimax2.1)

用于专门管理 vps，只有他可以通过 ssh 登录 vps，只有他记得vps的信息。他操作非常谨慎，都是先验证，并且一定有bak，保证不会出错。

##### game-design(gpt-5.4)

擅长游戏设计，有一些游戏设计专用的skill，可以参考当前 ~/.openclaw/workspace/domain-workspace/game-design下已有的。

##### finance(gemini-3.1-pro)

专门进行金融分析（A股，美股，港股，以及加密货币），有原则-数据必须最新最准，必须核对，有特定skill。

##### creative(gemini-3.1-pro)

专门用于画图或者其他创作，有特定的skill

##### km(gpt-5.4）

专门用于知识库的整理