class_name Hud
extends CanvasLayer
## Affichage : score, vies, jauge de charge, barre du boss, titres de niveau et messages.

var _score: Label
var _lives: Label
var _level: Label
var _title: Label
var _subtitle: Label
var _message_box: Control
var _charge: ProgressBar
var _boss_bar: ProgressBar
var _boss_name: Label
var _level_timer := 0.0
var _bonus_label: Label
var _toast: Label
var _toast_timer := 0.0


func _ready() -> void:
	_score = _label(26)
	_score.position = Vector2(24, 16)
	_lives = _label(26)
	_lives.position = Vector2(24, 50)
	_bonus_label = _label(20)
	_bonus_label.position = Vector2(24, 90)

	_toast = _label(32)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.anchor_right = 1.0
	_toast.offset_top = 200
	_toast.visible = false

	_level = _label(34)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level.anchor_right = 1.0
	_level.offset_top = 140
	_level.visible = false

	var charge_label := _label(18)
	charge_label.text = "Charge"
	charge_label.anchor_top = 1.0
	charge_label.anchor_bottom = 1.0
	charge_label.offset_left = 24
	charge_label.offset_top = -70
	_charge = _bar(Color(1.0, 0.35, 0.9))
	_charge.anchor_top = 1.0
	_charge.anchor_bottom = 1.0
	_charge.offset_left = 24
	_charge.offset_right = 264
	_charge.offset_top = -42
	_charge.offset_bottom = -24

	_boss_bar = _bar(Color(0.3, 0.85, 1.0))
	_boss_bar.anchor_left = 0.25
	_boss_bar.anchor_right = 0.75
	_boss_bar.offset_top = 22
	_boss_bar.offset_bottom = 42
	_boss_bar.visible = false
	_boss_name = _label(20)
	_boss_name.text = GameConfig.BOSS_NAME
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.anchor_right = 1.0
	_boss_name.offset_top = 46
	_boss_name.visible = false

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_message_box = center
	_title = _label(84, box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	_subtitle = _label(24, box)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer / 0.5, 0.0, 1.0)
		_toast.visible = _toast_timer > 0.0
	if _level_timer > 0.0:
		_level_timer -= delta
		_level.modulate.a = clampf(_level_timer, 0.0, 1.0)
		_level.visible = _level_timer > 0.0


func update_stats(score: int, lives: int, charge_ratio: float, boss: Enemy) -> void:
	_score.text = "Score  %06d" % score
	_lives.text = "Vies  %d" % maxi(lives, 0)
	_charge.value = charge_ratio * 100.0
	var has_boss := boss != null and is_instance_valid(boss)
	_boss_bar.visible = has_boss
	_boss_name.visible = has_boss
	if has_boss:
		_boss_bar.value = 100.0 * boss.health / boss.max_health


## Liste des bonus actifs, sous les vies.
func set_bonuses(text: String) -> void:
	_bonus_label.text = text


## Petit message coloré quand on ramasse un bonus.
func toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color.lightened(0.3))
	_toast_timer = 1.6
	_toast.modulate.a = 1.0
	_toast.visible = true


func flash(text: String) -> void:
	_level.text = text
	_level_timer = 3.5
	_level.visible = true


func show_message(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_message_box.visible = true


func hide_message() -> void:
	_message_box.visible = false


func _label(size: int, parent: Node = self) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.03, 0.1, 0.7)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	add_child(bar)
	return bar
