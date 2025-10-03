class_name Player
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

@export var stats: CharacterStats : set = set_character_stats

# ## 중요 ##
# 이 변수가 인스펙터 창에 노출되어, 애니메이션 파일을 직접 연결할 수 있게 됩니다.
@export var animations: SpriteFrames

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler


func _ready() -> void:
	status_handler.status_owner = self
	
	# 인스펙터에서 연결해준 애니메이션 데이터를 AnimatedSprite2D에 할당합니다.
	if animations:
		animated_sprite_2d.sprite_frames = animations
	
	# 게임 시작 시 'idle' 애니메이션을 재생합니다.
	animated_sprite_2d.play("idle")


func set_character_stats(value: CharacterStats) -> void:
	stats = value
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)

	update_player()


func update_player() -> void:
	if not stats is CharacterStats: 
		return
	if not is_inside_tree(): 
		await ready
	
	update_stats()


func update_stats() -> void:
	stats_ui.update_stats(stats)


func perform_attack() -> void:
	animated_sprite_2d.play("attack")


func take_damage(damage: int, which_modifier: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	animated_sprite_2d.play("hit")
	
	animated_sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			animated_sprite_2d.material = null
			
			if stats.health <= 0:
				animated_sprite_2d.play("death")
				Events.player_died.emit()
			else:
				animated_sprite_2d.play("idle")
	)
