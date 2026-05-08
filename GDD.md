# 游戏名称：Shadows of the Andes - 完整设计文档 (GDD)

## 项目概述
本项目是一款单人策略类回合制电子游戏，玩家扮演图帕克·阿马鲁二世，在18世纪安第斯地区领导起义，对抗西班牙殖民统治。游戏通过节点式地图、资源管理、人口动员和战斗系统来模拟起义的发展。

## 核心玩法
游戏采用**回合制结构**，分为两个阶段：
1. **玩家操作阶段**：玩家可自由调度军队、占领村落、招募人员
2. **自动结算阶段**：系统自动执行资源生产、消耗、战斗结算

玩家操作仅需鼠标拖放完成，易上手。目标是逐步扩大势力范围，最终占领所有关键据点。

---

# 第一部分：游戏系统

## 1. 回合系统 [✓ 已实现]

### 功能：回合流转与自动结算
**管理脚本**：`TurnManager.gd`

**回合流程**：
1. 开始新回合 (turn ++)
2. 玩家操作阶段：玩家调度军队、占领村落、招募单位
3. 玩家点击"结束回合"按钮后进入自动结算阶段：
   - 推进所有单位移动进度
   - 结算所有活跃战斗（每个战斗1回合伤害）
   - 所有村落执行资源消耗
   - 所有村落执行资源生产
4. 开始下一回合

**信号**：
- `turn_started(turn_number)`：新回合开始
- `player_phase_started`：玩家操作阶段开始
- `player_phase_ended`：玩家操作结束
- `auto_phase_started`：自动结算阶段开始
- `auto_phase_ended`：自动结算阶段结束



## 2. 地图与节点系统 [✓ 已实现]

### 功能：村落管理与地图结构
**管理脚本**：`GameMap.gd`、`VillageNode.gd`

### 2.1 村落基础属性

每个村落（VillageNode）拥有以下属性：

| 属性 | 说明 |
|-----|------|
| `node_id` | 唯一标识（如 "tinta"） |
| `location_name` | 显示名称（如 "Tinta") |
| `altitude` | 海拔类型：high / medium / low |
| `control_by_player` | 是否被玩家控制 |
| `population` | 当前人口数 |
| `resources` | 资源库存 {资源类型: 数量} |
| `stationed_units` | 驻扎的友方单位列表 |
| `enemy_units` | 驻扎的敌方单位列表 |
| `produced_resource_types` | 生产的资源种类数组 |

### 2.2 全地图村落列表（13个村落）

| 村落 | 镜头 | 海拔 | 初始人口 | 初始敌军 | 资源 |
|-----|------|------|---------|---------|------|
| **Tinta** | Tinta | HIGH | 150 | 0 | Potato, Llama |
| **Tungasuca** | Tinta | HIGH | 120 | 2 | Potato, Llama |
| **Pampamarca** | Tinta | HIGH | 80 | 1 | Potato |
| **Sicuani** | Tinta | HIGH | 95 | 1 | Llama |
| **Andahuaylillas** | Andahuaylillas | MEDIUM | 130 | 2 | Corn, Quinoa |
| **Urcos** | Andahuaylillas | MEDIUM | 110 | 2 | Corn |
| **Quiquijana** | Andahuaylillas | MEDIUM | 100 | 2 | Quinoa |
| **Ocongate** | Andahuaylillas | HIGH | 85 | 1 | Potato |
| **Cusco** | Andahuaylillas | MEDIUM | 300 | 4 | Corn, Quinoa |
| **Marcapata** | Marcapata | LOW | 70 | 1 | Coca |
| **Paucartambo** | Jungle | LOW | 75 | 1 | Coca |
| **Pilcopata** | Jungle | LOW | 60 | 1 | Coca |
| **Challabamba** | Jungle | LOW | 65 | 1 | Coca |

### 2.3 镜头分组与连接

游戏分为 4 个镜头区域（Camera2D），每个镜头可见 1-5 个村落。镜头间通过导航箭头可相互切换（或通过代码接口）。

**镜头拓扑**：
```
        Tinta
          |
  Andahuaylillas --- Marcapata
       |
      Jungle
```

**连接规则**：
- Tinta ↔ Andahuaylillas
- Andahuaylillas ↔ Tinta, Marcapata, Jungle
- Marcapata ↔ Andahuaylillas
- Jungle ↔ Andahuaylillas

### 2.4 节点控制与占领

**初始状态**：
- Tinta 由玩家控制
- 其他 12 个村落由敌方（殖民政权）控制

**占领规则**：
- 当玩家军队到达敌方村落且击败所有敌方单位后，该村落立即变为玩家控制
- 玩家控制的村落可生产资源、招募单位
- 敌方如果攻陷玩家村落（消灭所有驻守单位），该村落变为敌方控制

### 2.5 初始游戏状态

- **玩家起始位置**：Tinta
- **初始军队**：1 个 Rebel Army + 1 个 Female Corps（部署在 Tinta）
- **初始资源**：根据各村落配置

---

## 3. 资源系统 [✓ 已实现]

### 功能：资源种类、生产、消耗与运输
**管理脚本**：`SettingsAndData.gd`、`VillageNode.gd`

### 3.1 资源种类与效果

**高地资源** (HIGH)：
- **Potato（土豆）**
  - 产地：高地村落
  - 生产速度倍数：×2.0
  - 消耗用途：村落食物消耗（优先级1）
  - 单位效果：补充饱腹值 +50

- **Llama（羊驼）**
  - 产地：高地村落
  - 生产速度倍数：×0.5（生长慢）
  - 消耗用途：无（不消耗）
  - 单位效果：运输速度倍数 ×2.0（当单位携带时）

**中地资源** (MEDIUM)：
- **Corn（玉米）**
  - 产地：中地村落
  - 生产速度倍数：×1.0
  - 消耗用途：村落食物消耗（优先级2）
  - 单位效果：补充饱腹值 +30，战斗力 ×1.2

- **Quinoa（藜麦）**
  - 产地：中地村落
  - 生产速度倍数：×1.0
  - 消耗用途：村落食物消耗（优先级3）
  - 单位效果：补充饱腹值 +20，治疗 +20，移速 ×1.2（持续 3 回合）

**低地资源** (LOW)：
- **Coca（古柯）**
  - 产地：低地村落
  - 生产速度倍数：×1.0
  - 消耗用途：无（不消耗）
  - 单位效果：治疗单位 +50

### 3.2 资源生产系统

**生产速率计算**：
```
基础生产率 = 村落人口 ÷ 100
资源生产速率 = 基础生产率 × 资源类型倍数 × 饥饿状态倍数

其中：
- 资源类型倍数（参见3.1）
- 饥饿状态倍数 = 1.0（正常）或 0.2（饥饿）
```

**示例**：
- Tinta（人口150）生产土豆：150/100 × 2.0 × 1.0 = 3.0 土豆/回合（正常）
- Tinta 饥饿时：150/100 × 2.0 × 0.2 = 0.6 土豆/回合

**累积与转化**：
- 生产的小数值进行累积（浮点）
- 当累积值 ≥ 1.0 时，转化为整数资源并加入库存

### 3.3 资源存储限制

**村落存储**：
- 每个村落对其原生产资源的存储限制为 **10 个**
- 示例：生产 Potato + Llama 的村落可存储：10 Potato + 10 Llama + 10 Corn + 10 Quinoa + 10 Coca
- 超过限制的生产自动停止（不丢弃）

**单位背包**：
- 每个单位的总容量为 **5 个资源**（任意资源类型混合计数）
- 超过容量时，额外获取的资源无法添加

### 3.4 资源消耗系统 [详细流程]

**适用范围**：仅玩家控制的村落执行资源消耗

**可消耗资源**：
- Potato（土豆）
- Corn（玉米）
- Quinoa（藜麦）
- （Llama 和 Coca 不消耗）

**消耗流程**（每回合自动执行）：

**第一步：计算消耗值**
```
累积消耗值 += 村落人口 × 0.01
```

**第二步：检查饥饿状态**
```
if 累积消耗值 >= 1.0:
  设置 hunger_status = true（饥饿）
  生产倍数 = 0.2
else:
  if 村落有可消耗食物:
    设置 hunger_status = false（非饥饿）
    生产倍数 = 1.0
```

**第三步：消耗食物循环**（仅当 hunger_status = true）
```
while 累积消耗值 >= 1.0 AND 村落有可消耗食物:
  按优先度消耗一个食物单位：
    1. 首选土豆（Potato）
    2. 次选玉米（Corn）
    3. 最后藜麦（Quinoa）
  累积消耗值 -= 1.0
```

**第四步：更新饥饿状态**
```
if 消耗后 没有可消耗的食物:
  设置 hunger_status = true
  生产倍数 = 0.2
else:
  设置 hunger_status = false
  生产倍数 = 1.0
```

**示例场景**：
```
Tinta（人口150）：
初始：2 Potato, 累积消耗值 0.2, 饥饿=false

第1回合：
1. 消耗值 += 150×0.01 = 1.7
2. 1.7 >= 1.0 → 饥饿 = true, 倍数 = 0.2
3. 消耗循环：消耗 1 Potato → 消耗值 = 0.7
4. 0.7 < 1.0，且仍有食物 → 饥饿 = false, 倍数 = 1.0

结果：Potato = 1, 累积消耗值 = 0.7, 饥饿 = false
```

### 3.5 资源运输时间

当单位在两个村落间移动时，移动时间由两个村落所属的镜头决定：

**运输时间规则**：
```
if 起始镜头 == 目标镜头:
  运输时间 = 2 回合
else:
  运输时间 = 2 + (镜头间最短路径距离 × 4) 回合
```

**示例**：
- Tinta → Tungasuca（同镜头 Tinta）：2 回合
- Tinta → Urcos（不同镜头，Tinta → Andahuaylillas）：2 + 1×4 = 6 回合
- Tinta → Marcapata（最短路 Tinta → Andahuaylillas → Marcapata）：2 + 2×4 = 10 回合

---

## 4. 单位系统 [✓ 已实现]

### 功能：单位类型、属性、状态与生命周期
**管理脚本**：`Unit.gd`、`RebelArmy.gd`、`FemaleCorps.gd`、`EnemyUnit.gd`

### 4.1 玩家可操控单位类型

**Rebel Army（起义军）** [RebelArmy.gd]：
```
生命值：100
饱腹值：100
基础攻击力：30
消耗（非移动）：每回合 -10 饱腹值
消耗（移动中）：每回合 -15 饱腹值
驻扎时攻击力倍数：×1（无倍数）
```

**Female Corps（女性营）** [FemaleCorps.gd]：
```
生命值：80
饱腹值：100
基础攻击力：20
消耗（非移动）：每回合 -10 饱腹值
消耗（移动中）：每回合 -15 饱腹值
驻扎时攻击力倍数：×2（驻扎时攻击力 = 20 × 2 = 40）
```

### 4.2 敌方单位

**Enemy Unit** [EnemyUnit.gd]：
```
生命值：80
攻击力：25（固定，无状态变化）
特点：无饱腹值消耗，被玩家AI驱动
```

### 4.3 单位属性与多倍数系统

每个单位维护以下倍数属性（默认 1.0）：
- `combat_multiplier`：战斗力倍数（装备 Corn 时 ×1.2）
- `movement_speed_multiplier`：移动速度倍数（装备 Quinoa 时 ×1.2）
- `transport_speed_multiplier`：运输速度倍数（装备 Llama 时 ×2.0）

这些倍数可能在未来版本中应用于战斗、移动时间等。

### 4.4 单位状态机

单位有三种状态：`MOVING`、`STATIONED`、`ATTACKING`

**Stationed（驻扎）** ✓ IMPLEMENTED
- 定义：单位在玩家控制的村落中，不移动
- 饱腹值消耗：-10/回合
- 战斗参与：默认不参与（除非村落被入侵）
- Female Corps 特性：驻扎时攻击力倍数 ×2

**Moving（移动中）** ✓ IMPLEMENTED
- 定义：单位正在移动到目标村落
- 饱腹值消耗：-15/回合
- 战斗参与：不参与（锁定状态）
- 移动进度：每回合 -1（当进度变为 0 时，单位抵达目标）
- 到达后状态自动转换为 Stationed 或 Attacking（取决于目标村落控制权）

**Attacking（进攻）** ✓ IMPLEMENTED
- 定义：单位在敌方控制的村落中，或者玩家村落被入侵时
- 饱腹值消耗：-15/回合
- 战斗参与：自动参与该村落的战斗
- 控制权变更：当村落从玩家控制变为敌方控制时，所有驻扎单位立即转为 Attacking

**状态转换规则**：
```
当单位不在 Moving 状态时：
  if 当前村落.control_by_player == true:
    状态 = Stationed
  else:
    状态 = Attacking

当单位完成移动时：
  根据目标村落控制权自动转换为 Stationed 或 Attacking
```

### 4.5 单位饱腹值与生命值机制

**第一阶段：饱腹值消耗**
- 每回合根据状态扣除饱腹值（-10 或 -15）
- 当饱腹值 > 0 时，仅扣除饱腹值

**第二阶段：饥饿生命值消耗**
- 当饱腹值 <= 0 时，开始直接扣除生命值
- 每回合扣除的生命值 = 该状态下的饱腹值消耗量（-10 或 -15）

**低饱腹值战斗削弱** ✗ NOT IMPLEMENTED
- 当饱腹值 < 20 时，单位攻击力变为原先的一半（向下取整）
  - 例：Rebel Army 30 → 15
  - 例：Female Corps 驻扎时 40 → 20
- **注意**：代码中未实现此削弱效果；`get_current_attack_power()` 未检查饱腹值

**死亡条件**：
- 生命值 <= 0 时死亡
- 死亡后从村落的 stationed_units 和 enemy_units 中移除

### 4.6 单位移动系统 [详细流程]

**移动初始化**：
```gdscript
unit.start_movement(target_node: VillageNode) -> bool
```
- 计算 target_node 所需的移动时间（见3.5）
- 设置 `movement_time_remaining = 计算结果`
- 设置 `is_locked = true`（锁定，禁止重新分配）
- 状态 → Moving
- 发出信号 `movement_started(target, duration)`

**移动进度**：
```gdscript
unit.progress_movement()  # 每回合自动调用（由 TurnManager）
```
- `movement_time_remaining -= 1`
- 当 movement_time_remaining <= 0 时，调用 `complete_movement()`

**移动完成**：
```gdscript
unit.complete_movement()
```
- 更新 `current_node = target_node`
- 状态 → Stationed（默认）或 Attacking（若村落被敌方控制）
- 调用 `_handle_arrival_state_and_combat()`（处理抵达时的战斗）

**抵达时战斗处理** ✓ IMPLEMENTED
- 如果目标村落有敌方单位：立即启动战斗或加入现有战斗
- 如果目标村落无敌方单位且可占领：立即占领（村落控制权变为玩家）

### 4.7 单位库存系统

**背包容量**：每个单位 5 个资源位

**操作**：
```gdscript
unit.add_to_inventory(resource_type: String, amount: int) -> int  # 返回实际添加数量
unit.remove_from_inventory(resource_type: String, amount: int) -> bool
unit.get_inventory_count() -> int
unit.can_add_to_inventory(amount: int) -> bool
```

**库存变更信号**：
- `inventory_changed(new_inventory: Dictionary)`

---

## 5. 战斗系统 [✓ 已实现]

### 功能：多单位对战、伤害计算、战斗流程
**管理脚本**：`CombatSystem.gd`

### 5.1 战斗场景

战斗发生在以下情况：
1. 玩家单位到达敌方村落（带有敌方单位）时
2. 敌方单位入侵玩家村落时 ✗ (敌方AI未实现)
3. 多个我方单位与多个敌方单位在同一村落交战时

### 5.2 战斗参与条件

**我方单位**：
- Stationed 状态：若村落被敌方入侵，立即转为 Attacking 并参战
- Attacking 状态：自动参与战斗
- Moving 状态：不参与战斗

**敌方单位**：
- 存在于村落中时，自动参战

### 5.3 战斗伤害计算规则

**伤害流程**（每回合）：

**第一步：收集参战单位**
```
我方参战单位 = 村落中所有非 Moving 状态的玩家单位（活着）
敌方参战单位 = 村落中所有活着的敌方单位
```

**第二步：计算当前攻击力**
```
对每个单位：
  if 单位饱腹值 >= 20:
    使用基础攻击力
  else:  # ✗ NOT IMPLEMENTED
    使用基础攻击力 / 2（向下取整）
```

**第三步：计算总伤害**
```
我方总伤害 = Σ(所有参战我方单位的当前攻击力)
敌方总伤害 = Σ(所有参战敌方单位的攻击力)
```

**第四步：计算单位平均伤害**
```
敌方每单位受伤 = floor(我方总伤害 ÷ 敌方单位数)
我方每单位受伤 = floor(敌方总伤害 ÷ 我方单位数)
```

**第五步：应用伤害**
```
对所有参战敌方单位：
  当前生命值 -= 敌方每单位受伤

对所有参战我方单位：
  当前生命值 -= 我方每单位受伤

移除 health <= 0 的所有单位
```

**示例**：
```
我方：
  - Rebel Army (HP=100, ATK=30, 饱腹≥20)
  - Female Corps (HP=80, ATK=20, 驻扎, 饱腹≥20, 倍数×2=40)
  共 2 个单位

敌方：3 个 Enemy Unit (HP=80 each, ATK=25 each)

伤害计算：
  我方总伤害 = 30 + 40 = 70
  敌方总伤害 = 3 × 25 = 75

  敌方每单位受伤 = floor(70 / 3) = 23
  我方每单位受伤 = floor(75 / 2) = 37

结果：
  敌方：各单位 80 - 23 = 57 HP（全部存活）
  我方：
    - Rebel Army: 100 - 37 = 63 HP
    - Female Corps: 80 - 37 = 43 HP
```

### 5.4 战斗结束条件

战斗在以下情况结束：
```
if 我方单位全部死亡:
  结果：敌方胜利，玩家失去该村落控制权

elif 敌方单位全部死亡:
  结果：我方胜利，该村落被占领为玩家控制
  后续：所有参战我方单位状态转为 Stationed

else:
  战斗继续下一回合
```

### 5.5 战斗中的单位移动

- Moving 状态的单位：不参与战斗
- 当单位完成移动抵达战斗中的村落时：加入该战斗（下一回合开始参战）

---

## 6. 用户界面系统 [✓ 已实现]

### 功能：地图显示、节点信息、单位管理
**管理脚本**：`UIManager.gd`、`CameraUIController.gd`、`CameraArrowManager.gd`、`PauseMenuController.gd`

### 6.1 镜头控制系统 ✓

**镜头管理脚本**：`CameraManager.gd`

**功能**：
- 4 个固定镜头位置（Tinta, Andahuaylillas, Marcapata, Jungle）
- 镜头间通过方向箭头按钮切换
- 平滑 0.5 秒过渡动画

**UI 箭头**：
- 上箭头：切换到 Andahuaylillas
- 下箭头：切换到 Jungle 或 Marcapata
- 左箭头：切换到 Marcapata
- 右箭头：切换到 Tinta

### 6.2 节点信息面板 ✓

**位置**：屏幕左下角

**显示内容**：
- 村落名称
- 当前人口
- 饥饿状态指示 [HUNGRY]
- 海拔图标（高/中/低）
- 生产资源图标（最多 2 个）

### 6.3 资源与单位面板 ✓

**位置**：屏幕左侧（可滚动）

**显示内容**：
1. **--- Units ---** 标题
   - 每个驻扎单位一行：[图标] [单位名称]
   - 若单位在移动中：显示 [MOVING] 覆盖层

2. **--- Resources ---** 标题
   - 每种有库存的资源一行：[图标] ×[数量]

3. **--- Enemies ---** 标题
   - 每个敌方单位一行：[图标] [敌方单位名称]

### 6.4 单位拖放系统 ✓

**操作**：
1. 点击资源面板中的友方单位图标
2. 拖动至地图上的目标村落
3. 释放鼠标完成移动指令

**特性**：
- 拖动中的图标半透明（50% 不透明度）
- 仅可拖放到有效目标村落（除当前所在村落外）
- 移动中的单位显示 [MOVING] 标签，无法重新分配

### 6.5 招募系统 ✓

**招募按钮**：屏幕右下角（当选中玩家控制村落时显示）

**招募规则**：
- **成本**：25 人口 / 单位
- **类型概率**：80% Rebel Army、20% Female Corps
- **失败提示**：人口不足时显示红色提示 "Not enough population! (Need 25, Have X)"

**执行**：
```
if 点击招募按钮：
  if 当前村落人口 >= 25：
    随机生成 Rebel Army（80%）或 Female Corps（20%）
    人口 -= 25
    刷新 UI
  else:
    显示失败提示 2 秒
```

### 6.6 暂停菜单 ✓

**快捷键**：ESC 键

**功能**：
- Resume Game
- Settings （未实现）
- Return to Menu
- Quit

---

## 7. 摄像头系统 [✓ 已实现]

### 功能：多镜头视角管理与平滑过渡

**管理脚本**：`CameraManager.gd`

**4 个镜头位置**（像素坐标）：
- Tinta: (732, 960)
- Andahuaylillas: (547, 633)
- Marcapata: (1027, 574)
- Jungle: (670, 230)

**过渡方式**：
- 平滑 Tween 动画（0.5 秒，QUART 缓动）
- 完成后发出 `camera_view_changed(view_name)` 信号

---

## 8. 胜利条件系统 [✓ 已实现]

### 功能：游戏胜利判定
**管理脚本**：`GameController.gd`

### 8.1 胜利条件

**条件**：玩家占领所有 13 个村落

**实现**：
```gdscript
func check_victory_condition() -> bool:
	"""检查胜利条件 - 占领所有节点"""
	for node in game_map.all_nodes:
		if not node.control_by_player:
			return false  # 还有未占领的村庄
	
	# 所有村庄都被占领 - 玩家胜利
	emit_signal("game_over", "player")
	return true
```

**执行时机**：
- 每个自动结算阶段末（`_on_auto_phase_ended()`）调用一次
- 当所有村落都被玩家控制时触发 `game_over("player")` 信号

### 8.2 失败条件 ✗ 未实现

当前未实现以下失败条件：
- 所有友方单位全部死亡
- 所有玩家控制的村落被占领
- 资源系统完全崩溃（无法维持部队/人口）

---

# 第二部分：实现状态清单

## ✓ 已实现的功能

- [x] 回合系统与游戏循环
- [x] 地图与 13 个村落节点
- [x] 4 镜头系统与切换
- [x] 资源系统（生产、消耗、存储）
- [x] 资源消耗详细状态机
- [x] 单位类型（Rebel Army, Female Corps, Enemy Unit）
- [x] 单位状态机（Stationed, Moving, Attacking）
- [x] 单位拖放移动系统
- [x] 战斗系统（多单位伤害计算）
- [x] 单位库存系统
- [x] 单位自动消耗食物/药品
- [x] 资源增益系统（Corn/Quinoa/Llama）
- [x] 招募系统（25 人口/单位，80/20% 概率）
- [x] 节点占领与控制权管理
- [x] UI 信息面板、资源显示、单位面板
- [x] 镜头 UI 箭头控制
- [x] 暂停菜单
- [x] 胜利条件（占领所有 13 个村落）
- [x] 自动阶段动画系统（镜头移动 + 节点闪烁）
- [x] 回合标签显示
- [x] 教程遮罩系统

## ✗ 未实现的功能

- [ ] 低饱腹值战斗削弱（< 20 饱腹值时攻击力 /2）
- [ ] 敌方 AI 与自动移动
- [x] 敌方入侵与反制（每5回合自动入侵，仅当同镜头有未控制村落）
- [ ] 殖民干扰系统（第 6 章所述的干扰事件）
- [ ] 失败条件（资源崩溃、人口耗尽等）
- [x] 资源对单位的实时增益应用（Corn 战斗力倍数、Llama 运输倍数等）
- [ ] 游戏过渡场景与菜单系统

## 2024-2025 增量更新

### 新增功能

#### 1. 单位库存系统 [✓]
- 单位背包容量：5个资源位
- 资源自动消耗：当饱腹值 < 50 时自动从背包消耗食物
- 药品自动使用：当生命值 < 50 时自动从背包消耗 coca/quinoa

#### 2. 资源增益系统 [✓]
- **Corn**：战斗力 ×1.2（持续1回合）
- **Quinoa**：移速 ×1.2（持续1回合）
- **Llama**：运输速度 ×2.0

#### 3. 村落征兵系统 [✓]
- 每3回合征收一次
- 玩家控制村落：人口 -5
- 非玩家控制村落：资源产出减半

#### 4. 自动阶段动画系统 [✓]
- 自动阶段显示镜头移动和节点闪烁
- 镜头移动：0.5秒
- 节点闪烁：0.1秒间隔，约2秒/节点
- 回合标签格式："Turn X - Phase Name"

#### 5. 教程遮罩系统 [✓]
- **SpotlightMaskOverlay**：全屏暗色遮罩 + 高亮圆形
- **教程流程**：
  1. 显示 Tinta（玩家点击）
  2. 移动到 InfoPanel 中心
  3. 依次移动到：RecruitButton → +46px处 → +90px处 → ArrowUp
  4. 最后点击隐藏遮罩
- 移动曲线：TRANS_QUART + EASE_OUT（与镜头相同）
- Label 位于高亮区域上方，自动限制在屏幕范围内

---

# 第三部分：设计理念与平衡

## 核心概念

**"垂直群岛"（Vertical Archipelago）**：安第斯地区的资源依赖不同海拔。游戏通过三个海拔类型的资源（高地、中地、低地）来模拟这一特性，鼓励玩家同时控制多个海拔的村落。

## 平衡设计

**资源生产**：
- 人口多的村落（如 Cusco）生产速度快，但消耗也大
- 村落饥饿时生产速度大幅下降（×0.2），鼓励食物资源的储备

**单位战斗**：
- Rebel Army 攻击力强但防御低
- Female Corps 防御高，驻扎时攻击力加倍，适合据点防守
- 敌方 Enemy Unit 攻击力居中，数量优势

**移动成本**：
- 镜头间移动耗时较长，鼓励玩家建立本地据点而不是集中兵力
- 同镜头 2 回合，跨镜头最多 10+ 回合

---

# 附录：常见问题

**Q：为什么资源生产不是"人口 ÷ 50"？**
A：代码实现使用"人口 ÷ 100 × 资源倍数"，与 GDD 初稿有异。当前代码版本为准。

**Q：单位如何恢复饱腹值？**
A：目前代码未实现资源消耗恢复。应通过背包中的 Potato/Corn/Quinoa 恢复，但UI未提供此功能。

**Q：胜利条件是什么？**
A：玩家占领所有 13 个村落时游戏胜利。系统在每个自动结算阶段末检查一次胜利条件（`check_victory_condition()`）。

**Q：如何实现敌方 AI？**
A：未来版本可扩展 EnemyUnit 与敌方决策系统，使敌方能自动移动、进攻与防守。