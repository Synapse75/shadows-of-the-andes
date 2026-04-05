#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
地图切换系统使用示例和说明

MapSystem 使用指南：
====================

1. 基础概念
-----------
- MapView: 每个地图视野（摄像机观看位置）
- explored_maps: 玩家已探索的地图列表
- connected_maps: 某地图可以到达的其他地图
- current_map_id: 当前正在查看的地图

2. 初始化地图
-----------

在 GameMap.gd 或 UIManager.gd 中的 _ready() 函数里：

```gdscript
func _ready():
    var map_system = get_node("Main/Systems/MapSystem")
    
    # 注册所有地图
    map_system.register_map_view(
        "tinta",                          # 地图ID
        "Tinta",                          # 地图名称
        Vector2(400, 300),                # 摄像机位置
        ["tungasuca", "paucartambo"]      # 可到达的地图ID
    )
    
    map_system.register_map_view(
        "tungasuca",
        "Tungasuca",
        Vector2(300, 150),
        ["tinta", "cusco"]                # 可以回到Tinta或前往Cusco
    )
    
    map_system.register_map_view(
        "cusco",
        "Cusco",
        Vector2(400, 400),
        ["tungasuca"]
    )
    
    # 设置初始地图（必须是已注册的）
    map_system.set_starting_map("tinta")
```

3. 处理地图切换按钮
------------------

当玩家点击"前往某地图"按钮时：

```gdscript
func _on_go_to_map_button_pressed(map_id: String):
    var map_system = get_node("Main/Systems/MapSystem")
    var success = map_system.switch_map(map_id)
    
    if success:
        print("切换到: " + map_id)
        # 摄像机会自动切换并带有渐黑渐亮效果
    else:
        print("无法切换到该地图")
```

4. 获取可用的切换目标
-------------------

当进入某个地图时，需要更新可用的切换按钮：

```gdscript
func _on_map_changed(map_id: String):
    var map_system = get_node("Main/Systems/MapSystem")
    var accessible_maps = map_system.get_accessible_maps()
    
    print("从 %s 可以到达: %s" % [map_id, accessible_maps])
    
    # 根据accessible_maps来启用/禁用相应的切换按钮
    for map_id_option in accessible_maps:
        var button = get_node("UILayer/MapButton_" + map_id_option)
        button.disabled = false
```

5. 探索新地图
-----------

当玩家完成某个条件时，解锁新地图：

```gdscript
func unlock_new_map(map_id: String):
    var map_system = get_node("Main/Systems/MapSystem")
    map_system.explore_map(map_id)
    # 现在玩家就可以切换到这个地图了
```

6. 摄像机过渡效果
----------------

CameraManager.gd 会：
1. 淡出0.3秒（屏幕变黑）
2. 在黑屏中立即移动摄像机位置
3. 淡入0.3秒（屏幕恢复）
总耗时：1秒

可在 main.tscn 中的 Camera2D 节点调整：
- transition_duration: 过渡时间（秒）
- use_fade_effect: 是否启用渐黑渐亮（默认true）

7. 完整示例 - UIManager 改进版本
================================

部分伪代码展示（需要在实际UIManager中实现）：

```gdscript
extends Node

@onready var map_system = get_node("/root/Main/Systems/MapSystem")

# UI按钮引用
@onready var map_buttons = {
    "tungasuca": $UILayer/GotoTungasucaButton,
    "cusco": $UILayer/GotoCuscoButton,
    # ...
}

func _ready():
    # 连接地图切换信号
    map_system.map_changed.connect(_on_map_changed)
    
    # 连接所有按钮
    for map_id in map_buttons:
        map_buttons[map_id].pressed.connect(_on_switch_map_button.bindv([map_id]))
    
    # 隐藏所有按钮（初始化时只有出生点可用）
    for button in map_buttons.values():
        button.visible = false

func _on_map_changed(map_id: String):
    # 更新可用的切换目标
    var accessible = map_system.get_accessible_maps()
    
    for target_map_id in map_buttons:
        if target_map_id in accessible:
            map_buttons[target_map_id].visible = true
        else:
            map_buttons[target_map_id].visible = false

func _on_switch_map_button(target_map_id: String):
    var success = map_system.switch_map(target_map_id)
    if not success:
        print("切换失败: " + target_map_id)
```

8. 常见错误
---------

✗ 错误：调用 switch_map() 时提示"地图不存在"
→ 检查地图ID拼写是否正确，确保已用 register_map_view() 注册

✗ 错误："无法从X到达Y"
→ 检查connected_maps是否包含目标地图，或者目标地图是否已explored

✗ 地图切换时摄像机没有移动
→ 确保设置了 set_starting_map()，并且 Camera2D 有 MapSystem 的引用

"""

# 这是示例和说明文件，不需要运行
