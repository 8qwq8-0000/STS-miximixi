extends Node

# Card-related events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(card_ui: CardUI)
signal card_aim_ended(card_ui: CardUI)
signal card_played(card: Card)
## 发的是「图标 + 已经算好的说明文字」，不是 Card 本身。
##
## 说明文字由 CardUI 现场算好再发出来：同一张牌指向不同目标时伤害数字会变
## （get_updated_tooltip），所以这里传的是那一刻的结果，而不是让接收方自己再算一遍。
signal card_tooltip_requested(icon: Texture, text: String)
signal tooltip_hide_requested

# Player-related events
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_hit
signal player_died

# Enemy-related events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_died(enemy: Enemy)
signal minion_summon_requested(minion_stats: EnemyStats)

# Battle-related events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal extra_turn_started

# Cooking-related events
signal dish_cooked(dish: DishCard)

# Map-related events
signal map_exited(room: Room)

# Shop-related events
signal shop_entered(shop: Shop)
signal shop_relic_bought(relic: Relic, gold_cost: int)
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_exited

# Campfire-related events
signal campfire_exited

# Battle Reward-related events
signal battle_reward_exited

# Treasure Room-related events
signal treasure_room_exited(found_relic: Relic)

# Relic-related events
signal relic_tooltip_requested(relic: Relic)

# Random Event room-related events
signal event_room_exited

# 设置相关的通知：开发者模式开关一变，地图之类的常驻场景要跟着换行为
signal developer_mode_changed(enabled: bool)
