# 项目上下文（代号：小厨生 / 尖塔饭）

> 这份文档给「新开一个同项目对话」用：把这一份读完再动手，能省掉重新摸索目录和踩坑的时间。
> 最后更新：2026-09-25

## 0. 一分钟速览

| 项 | 内容 |
| --- | --- |
| 引擎 | Godot 4.7.2（mono 编辑器 `D:\app\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe`；非 mono 的 4.7.1 / 4.6.2 也在 `D:\app`） |
| 玩法 | 类杀戮尖塔卡牌爬塔 + 宝可梦敌怪 + 随从 + 料理合成 + 掉落物 |
| 工程根 | `mygame`（**旧目录 `deck_builder_tutorial-main` 已废弃**，改动都已搬到 mygame，别再改旧目录） |
| 主场景 | `res://scenes/ui/main_menu.tscn`（启动先进主菜单） |
| 画面 | 设计视口 800×450，窗口默认 1280×720，`window/stretch/mode=viewport` + `scale_mode=integer`（等比例整数放大，横屏） |
| 语言 | 界面 / 卡牌 / 怪物名全中文；中文字体在 `字体/[未知]indienova Bitmap Chinese/indienova Bitmap Chinese 12px.ttf`（字体目录被 .gitignore 忽略，不入库） |
| Git | 仓库在 `D:\cangku\.git`，`mygame/.git` 只是指针文件；提交信息风格 `【存档】……`，当前分支 `master`（远端 `origin/main`） |

## 1. 目录职责

| 目录 | 放什么 | 数量 |
| --- | --- | --- |
| `monsters/` | 一只怪一个 `.tres`：血量、招式、掉落、立绘、定位 | 37 |
| `ingredients/` | 食材，一个一份 | 43 |
| `dishes/` | 料理（菜），一道一份 | 29 |
| `statuses/` | 状态（增益 / 减益），`.tres` 是数值、同名 `.gd` 是结算逻辑 | 13 |
| `powers/` | 能力牌对应的状态牌模板 | 7 |
| `relics/` | 遗物 | 9 |
| `minions/` | 随从池 `minion_pool.tres` + `cards/` 里的随从卡 | — |
| `common_cards/` | 通用卡（毒素、燃烧等） | 5 |
| `characters/{warrior,wizard,assassin}/` | 角色数值 + 起始牌组 + 可抽卡池 | 3 角色 |
| `battles/` | 手写战斗场景 + 数值（教程三只怪的固定编队） | 8 个 `.tscn` |
| `scenes/` | 各界面：`battle`、`map`、`shop`、`campfire`、`treasure`、`event_rooms`、`cooking_pot`、`card_selector`、`card_ui`、`ui`、`win_screen`、`minion`、`status_handler`、`relic_handler` | — |
| `effects/` | 卡牌效果：`damage`、`block`、`card_draw`、`status`、`exhaust_random`、`select_cards` | 6 |
| `custom_resources/` | 数据结构 + 读取入口（下面单列） | — |
| `art/` | 美术与音频：`宝可梦图片/`、`掉落物图片/`、`th06_04.wav`、`th06_05.wav`、`雨爱.mp3`、`死亡音效.wav`、`程序退出.wav` | — |
| `global/` | 全局单例：`events.gd`、`game_settings.gd`、`music_player.tscn`、`sfx_player.tscn`、`rng.gd`、`shaker.gd` | — |
| `_cn_tools/` | 一次性探针脚本（本地临时目录，.gitignore 忽略） | — |

## 2. 关键数据文件（都在 Godot 检查器里改，不用碰代码）

- `enemy_config.tres` —— **敌怪数值总开关**：全局生命 / 伤害 / 格挡 / 回血 / 金币倍率。
  当前存的是默认 1.0（名册的数值已经按「名册 0.3、弱怪 0.5、精英 1.0」的意图烘焙进每只怪的 `.tres` 里）。
  想整体调强弱改这里；想调单只怪去 `monsters/<id>.tres`。**单怪倍率已废除。**
- `custom_resources/monster_book.gd` —— 名册的「规则」：威胁等级权重 `MINION_THREAT_WEIGHTS`、同场上限 `MAX_GROUP_BY_THREAT`、谁算精英、谁能当随从、谁能进遭遇。
- `encounter_config.tres` —— 遭遇名单，两部分：
  - `tiers`：通用档 `t1_single`（单只）/ `t2_pair`（两只）/ `t3_trio`（三只）/ `elite_single`（精英房）/ `boss_single`（Boss）。每档写 count、站位 `positions`、`battle_tier`、`weight`、金币区间；**没写死是哪只怪**，够格的怪自动平摊档位权重。
  - `mixed`：手写混编组合（怪物组合、数量、权重、金币），例如「绿毛虫 + 掘掘兔」「怪力 + 大葱鸭」。
- `battles/*.tres` + `*.tscn` —— 手写战斗（教程三只怪：蝙蝠 / 螃蟹 / 毒幽灵）。
- `minions/minion_pool.tres` —— 随从池：固定三只（蝙蝠 / 螃蟹 / 毒幽灵）+ `monster_ids` 里的名册随从池。
- `custom_resources/battle_stats_pool.gd` —— 把「手写战斗 + 通用 tier + 混编」拼成候选池并加权抽取。

## 3. 一局游戏怎么跑起来

主菜单 → 选角色（战士 / 法师 / 刺客）→ 地图（6 层左右，房间类型：普通战斗 / 精英房 / 宝箱 / 篝火 / 商店 / 事件 / Boss）→
房间 →（战斗 → 奖励界面）→ 回地图 → 打完 **Boss 房**才结算胜利画面。

- 房间调度：`scenes/run/run.gd`；地图生成：`scenes/map/map_generator.gd`。
- 战斗入口：`run.gd::_on_battle_room_entered()` → `res://scenes/battle/battle.tscn`，`battle_stats` 由房间携带。
- 通关判定：`run.gd::_cleared_boss_room()` —— **只认 Boss 房**，精英房打完回地图（以前那条「层数到顶也算通关」的兜底已删除，开发者模式多进几间房会误判通关）。

## 4. 已实现的系统（改之前先看一眼）

1. **随从**：战斗结束后不选卡牌奖励也会随机得一只友好敌怪当随从；随从在玩家周围生成、贴图镜像翻转，玩家回合结束后**早于敌怪**随机攻击一个敌怪，也能被玩家当卡牌施放目标。随从有随机意图（攻击 / 防御等非攻击意图的目标改为玩家，例如随从防御 → 玩家获得格挡）。
2. **随从卡**：0 费，卡面是召唤出来的随从，描述「召唤 XX」，用掉后本场战斗删除并生成临时随从；精英战结束额外掉二选一随从卡。遗物「永恒的伙伴」= 永久螃蟹随从（`relics/eternal_companion.gd`）。
3. **料理 / 烹饪锅**：战斗场景里有烹饪锅区域，掉落物卡指向锅 = 放材料，点「烹饪」出菜；有对应食谱就出那道，没有就**同等级随机料理**（找不到同级时自动向下兼容）。
4. **掉落物卡**：击杀敌人/随从会在手牌加入对应掉落，手牌满则进弃牌堆；属于临时卡，战斗结束不进卡组。
5. **选牌**：`effects/select_cards_effect.gd` + `scenes/ui/card_selector/`，从手牌之类的指定位置选指定张数，点「选择」关闭界面并结算（已有卡 `warrior_angry_anvil`、新卡「精炼」都在用；精炼已进战士初始牌组）。
6. **状态衰减时机**：减益只在**玩家回合结束后**减一层（寄生种子那类不再在回合开始掉层）。
7. **精英随从奖励 / 涅槃**：精英战结束额外给随从卡；怪有涅槃时先判涅槃复活再判胜利。
8. **手牌**：上限 15（`scenes/ui/hand.gd` 的 `MAX_CARDS`），卡牌互相重叠，右侧压在左侧上方。
9. **音频**：普通战斗 `th06_04.wav`；Boss 战 `th06_05.wav` 放完一遍接 `雨爱.mp3` 循环；生物死亡 `死亡音效.wav`；主菜单退出 `程序退出.wav`（不掐断 BGM）；音乐全局播放（离开战斗继续放）。
10. **开发者模式**：设置里可开，开启后地图任意节点可走、战斗不掉血、可秒杀怪。**默认关闭，且不写进存档**。
11. **宝箱**：点击前不可见，点中区域才播动画。
12. **设置**：主菜单和暂停界面都能进，可调分辨率与音量。

## 5. 导出注意（本次修复的坑，千万别改回去）

Godot 导出时会把 `.tres` 转成二进制资源，**导出的 pck 里目录条目名变成了 `xxx.tres.remap`**（实测：37 只怪、43 食材、29 料理全是 `.tres.remap`）。

所以：

- **任何「扫目录 + 只认 `.tres`」的写法，在导出版都会读到 0 个文件**。症状就是「导出的 exe 只出现教程三怪」「食材和料理全空」。
- 统一改用 `custom_resources/resource_dir.gd` 的 `ResourceFiles.list_resource_paths()`：`.tres` 与 `.tres.remap` 都认，去掉 `.remap` 后缀后返回可直接 `load()` 的 `res://` 路径。
- 自检探针：`_cn_tools/roster_probe.tscn`（配 `roster_probe_node.gd`），正常应打印
  `MonsterBook: 名册载入 37 只怪` / `CookingData: 载入 43 种食材、29 道料理`。
- 导出版同样会打印这两行（在 `尖塔饭.console.exe` 里看得到），可以一眼确认资源有没有读到。

## 6. 这次对话（上一轮至今）完成的主要改动

| 提交 | 内容 |
| --- | --- |
| `24637c9` | 并入远端 README 与 `_cn_tools` |
| `3bb7d5a` | 精英随从奖励、涅槃复活、Boss 二段战斗曲、退出与死亡音效 |
| `17fde3f` | 战斗 BGM 播完自动重播、开发者模式、Boss 奖励后胜利结算、修复 Boss 掉落卡提示框报错 |
| `ca4a3f2` | 离开战斗后接回全局 BGM |
| `fcecf7c` | 战斗 BGM 按层级切换、广告占位、游戏改名「代号：小厨生」 |
| 更早 | 状态牌 / 能力牌 / 料理 / 掉落物 / 烹饪锅 / 怪物攻击模式、敌人数值配置、通用 tier、名册进遭遇池、随从系统、遗物「永恒的伙伴」、奖励跳过后选卡按钮不消失、横屏与整数缩放 等 |
| **本次（未提交）** | **修复导出后只认 `.tres` 导致名册为空的 bug**：新增 `custom_resources/resource_dir.gd`，`monster_book.gd` 与 `cooking_data.gd` 改用它加载；两处加了载入数量日志 |

## 7. 已知问题 / 注意

- 导出时会警告 `art/掉落物图片/龙翅.png 无效的图标文件`。实测该文件是合法 PNG（120×120 RGBA），只是警告，不影响游戏。
- `battles/` 下有历史遗留的近重复文件（`tier_0_bats_2` 与 `tier_0_bats2`、`tier_1_bats_3` 与 `tier_1_bats3`），可用，别贸然删。
- `字体/`、`_cn_tools/`、`export_presets.cfg`、`pokemon名单_含种族值.xlsx`、`尖塔饭.zip` 都在 `.gitignore` 里，属于本机临时文件，不要往提交里塞。

## 8. 常用操作

```powershell
$godot = 'D:\app\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe'
$proj  = 'D:\wokao\新建文件夹 (2)\godot-demo-projects-4.3\godot-demo-projects-4.3\mygame'

# 打开编辑器
& $godot --path $proj -e

# 资源自检（应打印 37 / 43 / 29）
& $godot --headless --path $proj res://_cn_tools/roster_probe.tscn

# 导出自检版到别处（注意：导出时 Godot 要写自己的 editor_data 临时目录）
& $godot --headless --path $proj --export-release "Windows Desktop" "$env:TEMP\check\game.exe"

# 仓库状态
git -c safe.directory=* -C $proj status --short
```

正式导出预设（`export_presets.cfg`，本地未入库）输出到 `../../../新建文件夹/尖塔饭.exe`，且 `embed_pck=false` —— **exe 和 pck 必须放一起、同名**。

## 9. 约定

- 代码里的注释、文档、提交信息都用中文；提交信息用 `【存档】……` 概括这一版做了什么。
- 改完尽量用上面的自检探针验一遍；涉及加载资源目录的改动，务必按第 5 节检查导出行为。
- 美术资源在 `art/` 对应位置；缺图先用 `art/占位符.png`，所有图片使用时都要调到合适大小。
