# 游戏名称：Shadows of the Andes

## 一、项目概述
本项目是一款单人策略类电子游戏，玩家将扮演图帕克·阿马鲁二世，在18世纪安第斯地区组织并领导起义，对抗西班牙殖民统治。游戏以节点式地图为基础，通过资源管理、人口动员和据点占领来模拟起义的发展过程。游戏旨在通过简化的策略系统，让玩家理解安第斯社会中“垂直群岛”资源结构以及殖民压迫对社会运作的影响。

## 二、核心玩法
游戏采用回合制结构。每一回合中，玩家可以进行有限数量的操作，主要包括军队调度、据点占领和人口招募。回合结束后，系统自动结算战斗结果、资源变化以及敌方行动。游戏整体操作仅需鼠标点击完成，以保证易上手和清晰表达。

**实现状态：** ✅ 部分完成
- ✅ 回合制管理系统
- ✅ 玩家操作阶段
- ✅ 自动流程阶段
- ⚠️ 单位移动（基础结构存在，UI交互未完成）
- ❌ 人口招募（设计存在，实现未完成）

## 三、地图与节点系统
游戏地图由若干节点构成，节点之间通过路径连接。节点分为两类：资源点和村落。所有节点初始处于殖民体系控制之下，玩家需要逐步将其转化为起义军控制。

**实现状态：** ✅ 主要完成

### 3.1 节点系统 ✅
- **VillageNode** (`Scripts/Nodes/VillageNode.gd`) - 村庄节点 ✅
  - 节点ID、名称、描述、位置
  - 资源管理（food, population, units）
  - 驻扎与敌方单位管理
  - 最大人口数量及招募速率
  - 动画精灵与标签UI及其外发光交互

### 3.2 地图管理
- **GameMap** (`Scripts/GameMap.gd`) - 地图控制器 ✅
  - 自动收集所有节点
  - 区分玩家/敌方控制的节点
  - 节点查询功能
  - 鼠标点击检测（已更新SubViewport坐标变换）
  - 单位分配到起始节点
  - 控制权管理

### 3.3 地图资源点
资源点根据海拔分为三种类型：

- **高地资源点** ✅
  - 提供土豆等基础食物
  - 提供羊驼等运输资源
  - 用于维持人口生存和提升行军效率

- **中地资源点** ✅
  - 主要产出玉米
  - 用于维持军队规模和战斗能力

- **低地资源点** ✅
  - 提供古柯等特殊资源
  - 用于提升士气或加快行动速度

## 四、资源系统
游戏中的资源并不以复杂数值呈现，而是通过有无状态影响系统运作。

**实现状态：** ✅ 主要完成

### 4.1 资源类型
- ✅ Food（食物）- 维持人口
- ✅ Population（人口）- 人力资源来源
- ✅ Units（军队）- 战斗力量
- ⚠️ Special Resources（特殊资源）- 框架存在，效果未完成

### 4.2 资源影响系统 ⚠️ 部分完成
- ✅ 资源生产系统（每轮自动生产）
- ✅ 资源存储容量限制
- ✅ 资源显示UI
- ❌ 高地资源不足时人口减少的逻辑
- ❌ 中地资源不足时军队规模下降的逻辑
- ❌ 低地资源不足时单位速度/效率降低的逻辑

### 4.3 已弃用的资源管理器
- **ResourceManager** (`Scripts/Systems/ResourceManager.gd`) - ⚠️ 已弃用
  - 功能已转移至VillageNode.gd
  - 保留向后兼容性

---

## 五、单位与战斗系统

**实现状态：** ⚠️ 部分完成

### 5.1 单位系统 ✅ 主要完成

- **Unit** (`Scripts/Units/Unit.gd`) - 玩家单位
  - unit_id, unit_name, unit_type
  - 生命值系统（max_health, current_health）
  - 饱食值系统（max_satiety, current_satiety）
  - 攻击力（attack_power = 30）
  - 单位状态枚举（IDLE, MOVING, ATTACKING, DEFENDING）
  - 库存系统（背包容量5个资源）
  - 移动到相邻节点
  - 伤害系统
  - 信号系统（移动、状态改变、受伤、死亡、库存改变等）
  - 节点分配方法

- **EnemyUnit** (`Scripts/Units/EnemyUnit.gd`) - 敌方单位 ✅
  - 敌方特定属性
  - 攻击力（attack_power = 25）
  - 分组管理（"enemy_units"组）

- **RebelArmy** (`Scripts/Units/RebelArmy.gd`) - 叛军 ✅
  - 叛军特定属性
  - 攻击力（attack_power = 30）

- **FemaleCorps** (`Scripts/Units/FemaleCorps.gd`) - 妇女部队 ✅
  - 特殊部队属性

### 5.2 单位管理器
- **UnitManager** (`Scripts/Systems/UnitManager.gd`) - 单位管理 ✅
  - 收集所有单位到数组
  - 区分玩家单位/敌方单位
  - 单位选择功能
  - 获取指定节点的单位
  - 信号系统（选择/取消选择）

### 5.3 战斗系统 ⚠️ 部分完成
- **CombatSystem** (`Scripts/Systems/CombatSystem.gd`) - 战斗管理器
- ✅ attack_power 属性定义
- ✅ ATTACKING 单位状态
- ✅ 单位受伤/死亡机制框架
- ⚠️ 自动战斗结算逻辑
- ⚠️ 进攻方与防守方的对比计算
- ❌ 节点控制权的自动转换
- ❌ 战斗结果的UI反馈

---

## 六、回合管理系统

**实现状态：** ✅ 主要完成

### 6.1 TurnManager (`Scripts/Systems/TurnManager.gd`) ✅
- 当前回合号跟踪
- 玩家操作阶段 vs 自动阶段切换
- 回合信号系统
  - turn_started
  - turn_ended
  - player_phase_started / player_phase_ended
  - auto_phase_started / auto_phase_ended
- 玩家阶段管理
- 自动流程执行（资源生产等）
- UI更新（回合数显示、按钮状态）
- "结束回合"按钮集成

---

## 七、摄像机与镜头系统

**实现状态：** ✅ 主要完成

### 7.1 CameraManager (`Scripts/Systems/CameraManager.gd`) ✅
- 4个固定镜头视点
  - "tinta" - 起始点（732, 960）
  - "andahuaylillas" - 西南（547, 633）
  - "marcapata" - 东南（1027, 574）
  - "jungle" - 北部（670, 230）
- 镜头连接关系定义（可切换的镜头列表）
- 镜头切换方法（循环、直接设置）
- 当前镜头跟踪
- 能否切换到目标镜头的检查

### 7.2 箭头UI控制 ✅ 主要完成
- **CameraArrowManager** (`Scripts/UI/CameraArrowManager.gd`)
  - 管理4个方向箭头按钮
  - 基于当前镜头更新箭头可见性
  - 箭头点击处理
  - 箭头动画播放

- **ArrowButton** (`Scripts/UI/ArrowButton.gd`)
  - 方向标识（up/down/left/right）
  - 动画帧系统（2fps，0.5秒/帧）
  - 与CameraManager集成

### 7.3 SubViewport架构 ✅ 最新实现
- **GameViewport** (SubViewport, 480x300) - 游戏内容渲染
  - Map节点父级
  - Camera2D 父级
- **GameDisplay** (TextureRect) - 游戏显示
  - 位置：(120, 100) 到 (600, 400) 在游戏坐标
  - 显示GameViewport纹理
  - 3x3像素缩放（游戏像素 → 显示像素）
- 输入坐标变换健全

---

## 八、UI系统

**实现状态：** ✅ 主要完成

### 8.1 主要UI管理器

- **UIManager** (`Scripts/Systems/UIManager.gd`) ✅
  - 信息面板管理
  - 节点信息显示（RichTextLabel格式）
  - 海拔图标映射
  - 鼠标悬停/锁定节点显示
  - 节点信息格式化输出

- **VillageUIManager** (`Scripts/Systems/VillageUIManager.gd`) ✅
  - 村庄UI引用收集
  - 从Prefab中提取UI元素

### 8.2 暂停菜单
- **PauseMenuController** (`Scripts/UI/PauseMenuController.gd`) ✅
  - ESC键暂停/恢复
  - 暂停菜单面板
  - 按钮集成
    - ✅ 恢复按钮
    - ✅ 设置按钮（框架，TODO）
    - ✅ 返回菜单按钮
    - ✅ 退出游戏按钮
  - 游戏流程控制（暂停树）
  - 信号系统（game_paused, game_resumed）

### 8.3 其他UI元素
- ✅ 信息面板（左侧）- 显示选中节点的详细信息
- ✅ 回合信息面板（顶部中央）- 显示当前回合号
- ✅ "结束回合"按钮（顶部中央）
- ✅ 暂停按钮（顶部右角）
- ✅ 方向箭头（上下左右）- 摄像机控制

### 8.4 UI字体系统 ✅
- 统一字体：ClearFont.ttf（像素字体）
- 统一字体大小：16pt
- 禁用抗锯齿：gui/theme/default_font_antialiased=false

---

## 九、控制器与主系统

**实现状态：** ✅ 主要完成

### 9.1 GameController (`Scripts/GameController.gd`) ✅
- 游戏流程总控制器
- 系统引用管理
  - GameMap
  - TurnManager
  - PauseMenuController
  - CameraManager
  - 游戏设置数据
- 回合信号连接
- 镜头切换方法（供UI调用）
  - camera_next / camera_prev
  - camera_to_north / south / east / west
- 游戏状态检查
- 胜利条件检查（占领Cusco）

### 9.2 SettingsAndData 类 ✅
- 游戏设置存储

---

## 十、已弃用系统

### 10.1 已弃用的系统管理器
- **MapSystem** (`Scripts/Systems/MapSystem.gd`) - ⚠️ 已弃用
  - 功能已转移至CameraManager.gd
  - 保留向后兼容性

---

## 十一、未完成的系统

### 11.1 殖民干扰系统 ❌ 未实现
- 周期性触发干扰事件
- 随机减少资源点产出
- 削弱村落人口
- 敌方进攻玩家控制节点
- 事件通知UI

### 11.2 敌方AI系统 ❌ 未实现
- 敌方回合管理
- 单位移动决策
- 攻击目标选择
- 占领策略
- 资源管理

### 11.3 完整战斗系统 ⚠️ 框架存在，逻辑未完成
- 进攻方vs防守方数值对比
- 伤害计算公式
- 战斗胜负判定
- 节点控制权自动转换
- 战斗动画或反馈

### 11.4 音乐与音效系统 ❌ 未实现
- Musics/ 文件夹存在，内容为空
- SoundEffects/ 文件夹存在，内容为空
- 背景音乐播放
- 操作音效
- UI反馈音效

### 11.5 设置菜单 ⚠️ 框架存在，功能未实现
- 暂停菜单中"设置"按钮标记为TODO
- 需要实现音量控制
- 难度选项
- 画质设置
- 控制绑定

### 11.6 主菜单 ❌ 未实现
- 需要实现Scenes/MainMenu.tscn
- 需要游戏开始、设置、关于、退出选项
- 难度选择
- 游戏说明

### 11.7 游戏结束界面 ⚠️ 逻辑存在，UI未实现
- 胜利条件逻辑存在（occupyAllNodes）
- 失败条件逻辑存在（资源崩溃）
- GameController发出game_over信号
- 结束界面UI未实现
- 重新开始/返回菜单选项未实现

### 11.8 存档系统 ❌ 未实现
- 游戏进度保存
- 存档读取
- 存档管理UI

### 11.9 难度系统 ❌ 未实现
- 难度选择
- 难度相关的参数调整
- 敌方AI强度

### 11.10 教程系统 ❌ 未实现
- 新手指引
- 游戏规则说明UI
- 交互提示

### 11.11 完整人口招募系统 ⚠️ 框架存在，UI交互未完成
- VillageNode有recruitment_rate
- 需要UI操作来招募
- 资源消耗计算
- 招募动画或反馈

### 11.12 单位移动UI交互 ⚠️ 框架存在，UI操作未完成
- Unit.move_to_node() 方法存在
- 需要点击路径或其他UI来移动
- 移动成本计算
- 移动动画

---

## 十二、开发进度

### 12.1 已完成的核心系统 ✅
- 节点和地图系统
- 回合制管理
- 摄像机系统
- UI基础框架
- 单位基础系统
- 暂停菜单

### 12.2 进行中的工作 🔄
- SubViewport架构重构（最近完成）
- 输入坐标变换修复（最近完成）

### 12.3 待实现的系统 ❌
- 敌方AI
- 战斗系统逻辑
- 音乐音效
- 存档系统
- 完整UI交互（移动、招募、攻击）

---

## 十三、文件结构

```
Scripts/
├── GameController.gd          ✅
├── GameMap.gd                 ✅
├── Nodes/
│   └── VillageNode.gd         ✅
├── Units/
│   ├── Unit.gd                ✅
│   ├── EnemyUnit.gd           ✅
│   ├── RebelArmy.gd           ✅
│   └── FemaleCorps.gd         ✅
├── Systems/
│   ├── TurnManager.gd         ✅
│   ├── CameraManager.gd       ✅
│   ├── UIManager.gd           ✅
│   ├── VillageUIManager.gd    ✅
│   ├── UnitManager.gd         ✅
│   ├── CombatSystem.gd        ✅
│   ├── SettingsAndData.gd     ✅
│   ├── ResourceManager.gd     ⚠️ (已弃用)
│   └── MapSystem.gd           ⚠️ (已弃用)
└── UI/
    ├── PauseMenuController.gd ✅
    ├── CameraArrowManager.gd  ✅
    ├── ArrowButton.gd         ✅
    ├── CameraUIController.gd  ✅
    └── UIFollowCamera.gd      ✅

Scenes/
├── main.tscn                  ✅ (SubViewport架构)
├── arrow.tscn                 ✅
├── UnitSystemTest.tscn        ✅
├── Prefabs/
│   └── VillageNodePrefab.tscn ✅

Sprites/
├── village*.png/aseprite      ✅
├── potato.*                   ✅
├── llama.*                    ✅
├── map.png                    ✅
├── mappixel.png               ✅
├── arrow.*                    ✅
├── altitude.*                 ✅
├── high/middle/low.*          ✅
└── unit.*                     ✅

Shaders/
└── lighten_map.gdshader       ✅

Fonts/
└── ClearFont.ttf              ✅
```

---

## 十四、设计目标

本游戏的设计重点在于将历史概念转化为可操作的游戏机制。通过资源依赖关系和节点控制，玩家可以直观理解安第斯地区的生态结构及其对社会组织的影响。同时，游戏通过模拟殖民干扰与资源压力，使玩家体验起义在现实中的困难与限制。

---

## 十五、开发范围与实现策略

本项目为单人开发，开发周期约为一个月。设计上优先保证核心玩法的完整性与可运行性，避免复杂系统。

### 15.1 已实现的MVP（最小可实现版本）
- ✅ 基础地图与节点系统
- ✅ 回合制管理
- ✅ UI基础框架
- ✅ 摄像机系统
- ⚠️ 节点占领（框架存在）

### 15.2 需要实现以完整MVP
- ❌ 战斗系统完整逻辑
- ❌ 敌方AI与敌方回合
- ❌ 资源影响的完整实现

### 15.3 后续完善
- ⚠️ UI交互优化（移动、招募、攻击指令）
- ❌ 音乐音效系统
- ❌ 教程与说明UI
- ❌ 存档系统
- ⚠️ 游戏结束界面

---

## 十六、已知问题与技术债

### 16.1 当前修复 🔧
- ✅ SubViewport架构重构完成
- ✅ 输入坐标变换实现

### 16.2 待修复问题
- ⚠️ CameraUIController中Camera2D路径可能需要更新为GameViewport/Camera2D
- ⚠️ 一些其他脚本中的Camera2D引用可能需要路径更新验证

---

## 说明

本文档记录了游戏的完整系统架构、实现状态和待开发内容。使用以下符号标记进度：
- ✅ **完成** - 功能已实现且正常工作
- ⚠️ **部分完成** - 框架存在但功能不完整，或已弃用
- 🔄 **进行中** - 正在开发中
- ❌ **未实现** - 尚未开始实现