extends CanvasLayer

@onready var stage_timer_label: Label = %StageTimerLabel
@onready var boss_bar_root: PanelContainer = %BossBarRoot
@onready var boss_name_label: Label = %BossNameLabel
@onready var boss_hp_bar: ProgressBar = %BossHpBar

@onready var hp_label: Label = %HpLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var exp_label: Label = %ExpLabel
@onready var exp_bar: ProgressBar = %ExpBar
@onready var gold_label: Label = %GoldLabel
@onready var stamina_label: Label = %StaminaLabel
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var dash_hint_label: Label = %DashHintLabel
@onready var status_items_container: HBoxContainer = %StatusItems

var _boss_hp_max: float = 100.0
var _boss_hp_current: float = 100.0
var _boss_hp_display: float = 100.0
var _player_hp_target: float = 100.0
var _player_hp_display: float = 100.0
const BOSS_BAR_HALF_WIDTH: float = 460.0
const PLAYER_HP_SMOOTH_SPEED: float = 11.0
const BOSS_HP_SMOOTH_SPEED: float = 9.0

func _ready() -> void :
    set_player_stats(100.0, 100.0, 80.0, 100.0, 0.0, 20.0, 1, 0)
    set_status_entries(_build_preview_status_entries(GameManager.current_wave))
    EventBus.wave_started.connect(_on_wave_started)

func _process(delta: float) -> void:
    if hp_bar != null:
        _player_hp_display = move_toward(_player_hp_display, _player_hp_target, PLAYER_HP_SMOOTH_SPEED * delta * max(hp_bar.max_value, 1.0))
        hp_bar.value = _player_hp_display
    if boss_hp_bar != null:
        _boss_hp_display = move_toward(_boss_hp_display, _boss_hp_current, BOSS_HP_SMOOTH_SPEED * delta * max(_boss_hp_max, 1.0))
        boss_hp_bar.value = _boss_hp_display

func _on_wave_started(wave_id: int) -> void :
    set_status_entries(_build_preview_status_entries(wave_id))

func set_stage_timer(visible: bool, value_text: String = "", tint: Color = Color(0.82, 0.96, 1.0, 0.95)) -> void:
    if stage_timer_label == null:
        return
    stage_timer_label.visible = visible
    if not visible:
        return
    stage_timer_label.text = value_text
    stage_timer_label.modulate = tint

func show_boss_bar(boss_name: String, max_hp: float, current_hp: float) -> void :
    _boss_hp_max = max(max_hp, 1.0)
    _boss_hp_current = clamp(current_hp, 0.0, _boss_hp_max)
    _boss_hp_display = _boss_hp_current
    boss_name_label.text = boss_name
    boss_bar_root.visible = true
    boss_bar_root.modulate.a = 0.0
    boss_bar_root.anchor_left = 0.5
    boss_bar_root.anchor_right = 0.5
    boss_bar_root.offset_left = 0.0
    boss_bar_root.offset_right = 0.0
    _update_boss_bar_value()

    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(boss_bar_root, "modulate:a", 1.0, 0.24)
    tween.parallel().tween_property(boss_bar_root, "offset_left", - BOSS_BAR_HALF_WIDTH, 0.34)
    tween.parallel().tween_property(boss_bar_root, "offset_right", BOSS_BAR_HALF_WIDTH, 0.34)

func update_boss_hp(current_hp: float) -> void :
    _boss_hp_current = clamp(current_hp, 0.0, _boss_hp_max)
    _update_boss_bar_value()

func hide_boss_bar() -> void :
    if not boss_bar_root.visible:
        return
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.parallel().tween_property(boss_bar_root, "modulate:a", 0.0, 0.2)
    tween.parallel().tween_property(boss_bar_root, "offset_left", 0.0, 0.24)
    tween.parallel().tween_property(boss_bar_root, "offset_right", 0.0, 0.24)
    await tween.finished
    boss_bar_root.visible = false

func set_player_stats(
    hp: float, 
    hp_max: float, 
    stamina: float, 
    stamina_max: float, 
    current_xp: float = 0.0, 
    xp_to_next_level: float = 1.0, 
    current_level: int = 1,
    current_gold: int = 0
) -> void :
    var hp_max_safe: float = max(hp_max, 1.0)
    var stamina_max_safe: float = max(stamina_max, 1.0)
    var xp_max_safe: float = max(xp_to_next_level, 1.0)
    var hp_safe: float = clamp(hp, 0.0, hp_max_safe)
    var stamina_safe: float = clamp(stamina, 0.0, stamina_max_safe)
    var xp_safe: float = clamp(current_xp, 0.0, xp_max_safe)

    hp_bar.max_value = hp_max_safe
    _player_hp_target = hp_safe
    if absf(_player_hp_display - _player_hp_target) < 0.001 or hp_safe >= _player_hp_display:
        _player_hp_display = hp_safe
    hp_bar.value = _player_hp_display
    hp_label.text = _tf("ui.hud.hp_fmt", [int(round(hp_safe)), int(round(hp_max_safe))], "HP %d/%d")

    exp_bar.max_value = xp_max_safe
    exp_bar.value = xp_safe
    exp_label.text = _tf(
        "ui.hud.exp_fmt",
        [int(round(xp_safe)), int(round(xp_max_safe)), max(1, current_level)],
        "EXP %d/%d  Lv.%d"
    )
    if gold_label != null:
        gold_label.text = _tf("ui.hud.gold_fmt", [max(0, current_gold)], "Gold %d")

    stamina_bar.max_value = stamina_max_safe
    stamina_bar.value = stamina_safe
    stamina_label.text = _tf("ui.hud.stamina_fmt", [int(round(stamina_safe)), int(round(stamina_max_safe))], "Stamina %d/%d")
    dash_hint_label.text = _tx("ui.hud.dash_ready", "Dash: Ready") if stamina_safe > 0.0 else _tx("ui.hud.dash_empty", "Dash: Empty")
    dash_hint_label.modulate = Color(0.65, 1.0, 0.65, 1.0) if stamina_safe > 0.0 else Color(1.0, 0.48, 0.48, 1.0)

func set_status_entries(entries: Array[Dictionary]) -> void :
    for child: Node in status_items_container.get_children():
        child.queue_free()

    for entry: Dictionary in entries:
        status_items_container.add_child(_build_status_chip(entry))

func _update_boss_bar_value() -> void :
    boss_hp_bar.max_value = _boss_hp_max
    if _boss_hp_display > _boss_hp_max:
        _boss_hp_display = _boss_hp_max
    if _boss_hp_current > _boss_hp_display:
        _boss_hp_display = _boss_hp_current
    boss_hp_bar.value = _boss_hp_display

func _build_preview_status_entries(wave_id: int) -> Array[Dictionary]:
    return [
        {"label": _tx("ui.hud.wave", "Wave"), "value": _tf("ui.common.wave_fmt", [wave_id], "WAVE %d"), "color": Color(0.36, 0.82, 1.0, 1.0)}, 
        {"label": _tx("ui.hud.state", "State"), "value": _tx("ui.hud.signal_hot", "Signal Hot"), "color": Color(1.0, 0.78, 0.34, 1.0)}, 
        {"label": _tx("ui.hud.buff", "Buff"), "value": _tx("ui.hud.buff_crit", "Crit +12%"), "color": Color(0.58, 1.0, 0.58, 1.0)}, 
        {"label": _tx("ui.hud.debuff", "Debuff"), "value": _tx("ui.hud.debuff_burn", "Burn 4s"), "color": Color(1.0, 0.49, 0.42, 1.0)}, 
    ]

func _build_status_chip(entry: Dictionary) -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    panel.custom_minimum_size = Vector2(138.0, 58.0)

    var tint_value: Variant = entry.get("color", Color(0.75, 0.84, 0.88, 1.0))
    var tint: Color = Color(0.75, 0.84, 0.88, 1.0)
    if tint_value is Color:
        tint = tint_value
    panel.modulate = tint

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 6)
    margin.add_theme_constant_override("margin_top", 4)
    margin.add_theme_constant_override("margin_right", 6)
    margin.add_theme_constant_override("margin_bottom", 4)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 2)
    margin.add_child(vbox)

    var label_text: String = str(entry.get("label", "Status"))
    var value_text: String = str(entry.get("value", "-"))

    var title_label: Label = Label.new()
    title_label.text = label_text
    title_label.add_theme_font_size_override("font_size", 13)
    vbox.add_child(title_label)

    var value_label: Label = Label.new()
    value_label.text = value_text
    value_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(value_label)

    return panel

func _tx(key: String, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tx(key, fallback if not fallback.is_empty() else key)
    if fallback.is_empty():
        return key
    return fallback

func _tf(key: String, args: Array, fallback: String = "") -> String:
    if LocaleService != null:
        return LocaleService.tf(key, args, fallback if not fallback.is_empty() else key)
    var base: String = fallback if not fallback.is_empty() else key
    return base % args
