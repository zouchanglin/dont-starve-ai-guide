# AI Realtime Guide

这是一个 Don't Starve Together 客户端 Mod 原型，用于做“AI 攻略实时指导”。

当前版本先实现本地规则指导，不直接连接 AI API。这样可以先验证游戏内状态采集、玩法目标配置和 UI 交互，后续再把建议生成部分替换为本地或云端 AI 服务。

## 功能

- 游戏内右侧攻略面板
- 快捷键开关，默认 `G`
- Mod 配置中选择核心玩法
  - New Player Survival
  - Winter Prep
  - Rush Science
  - Caves / Ruins
- 实时读取基础状态
  - 天数、季节、昼夜阶段
  - 生命、饥饿、理智、温度
  - 背包和装备中的部分物品
- 根据状态生成短攻略建议
- 可配置高优先级警告自动弹出

## 安装

把整个 `ai_realtime_guide` 目录复制到 DST 的本地 mods 目录，例如：

```text
Steam/steamapps/common/Don't Starve Together/mods/ai_realtime_guide
```

然后在游戏的 Mods 页面启用 `AI Realtime Guide`。

## 下一步

推荐路线：

1. 扩展状态采集：附近实体、基地建筑、科技等级、Boss/猎犬倒计时。
2. 增加策略配置：速远古、养牛、种田、女武神战斗、新手保姆等。
3. 做本地 AI Bridge：Python/Node 服务监听本地端口。
4. Mod 把结构化游戏状态发给 Bridge。
5. Bridge 调用 OpenAI 或本地模型，返回结构化 JSON 建议。
6. Mod 只展示短标题、优先级、步骤和警告。

## 设计原则

- Mod 内只做采集、展示和轻量规则。
- API key 不放进 Mod。
- AI 输出必须结构化，避免长文本刷屏。
- 客户端 Mod 优先，减少对服务器和联机房间的影响。
