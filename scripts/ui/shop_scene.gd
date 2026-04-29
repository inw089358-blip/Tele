extends Control

const ShopSystemScript: Script = preload("res://scripts/systems/shop_system.gd")
const SAVE_SLOT_PANEL_SCENE_PATH: String = "res://scenes/ui/save_slot_panel.tscn"
const SETTINGS_SCENE_PATH: String = "res://scenes/settings.tscn"
const NEON_OPTION_BUTTON_SCRIPT: Script = preload("res://scripts/ui/neon_option_button.gd")
const WEAPON_ICON_DIR: String = "res://sprite/weapons/generated_from_doc_v1_alpha_final_v2/"
const ITEM_ICON_DIR: String = "res://sprite/items/"
const WEAPON_SLOT_COUNT: int = 6
const WEAPON_GRID_COLUMNS: int = 3
const ITEMS_PANEL_RATIO: float = 2.1
const WEAPONS_PANEL_RATIO: float = 1.2
const NEXT_STAGE_PANEL_RATIO: float = 0.95
const OFFER_ICON_SIZE: Vector2 = Vector2(64, 64)
const GRID_ICON_SIZE: Vector2 = Vector2(54, 54)
const PAUSE_OPEN_DURATION: float = 0.18
const PAUSE_CLOSE_DURATION: float = 0.13
const PAUSE_PANEL_POP_SCALE: float = 0.94
const PAUSE_OVERLAY_Z_INDEX: int = 1000
const FLOATING_DETAIL_Z_INDEX: int = 100

const RARITY_COLORS: Dictionary = {
    "common": Color("#bdc3c7"),    # 银灰色
    "uncommon": Color("#2ecc71"),  # 翠绿色
    "rare": Color("#3498db"),      # 蔚蓝色
    "epic": Color("#9b59b6"),      # 紫罗兰
    "legendary": Color("#f1c40f")   # 琥珀金
}

@onready var top_bar: HBoxContainer = get_node_or_null("Root/MainVBox/TopBar") as HBoxContainer
@onready var top_bar_spacer: Control = get_node_or_null("Root/MainVBox/TopBar/SpacerTop") as Control
@onready var gold_label: Label = get_node_or_null("Root/MainVBox/TopBar/GoldLabel") as Label
@onready var wave_label: Label = get_node_or_null("Root/MainVBox/TopBar/WaveLabel") as Label
@onready var refresh_button: Button = get_node_or_null("Root/MainVBox/TopBar/RefreshButton") as Button
@onready var lock_button: Button = get_node_or_null("Root/MainVBox/TopBar/LockButton") as Button
@onready var next_wave_button: Button = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/BottomActions/NextWaveButton") as Button
@onready var offers_grid: GridContainer = get_node_or_null("Root/MainVBox/MidRow/OffersPanel/OffersMargin/OffersGrid") as GridContainer
@onready var attr_label: RichTextLabel = get_node_or_null("Root/MainVBox/MidRow/RightPanel/RightMargin/AttrLabel") as RichTextLabel
@onready var mid_row: HBoxContainer = get_node_or_null("Root/MainVBox/MidRow") as HBoxContainer
@onready var right_panel: PanelContainer = get_node_or_null("Root/MainVBox/MidRow/RightPanel") as PanelContainer
@onready var bottom_panel: PanelContainer = get_node_or_null("Root/MainVBox/BottomPanel") as PanelContainer
@onready var weapon_slots_row: HBoxContainer = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/BottomContentRow") as HBoxContainer
@onready var hint_label: Label = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/BottomActions/HintLabel") as Label
@onready var bottom_vbox: VBoxContainer = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox") as VBoxContainer
@onready var bottom_actions: HBoxContainer = get_node_or_null("Root/MainVBox/BottomPanel/BottomMargin/BottomVBox/BottomActions") as HBoxContainer

var _shop_system: ShopSystem
var _snapshot: Dictionary = {}
var _shop_offers: Array[Dictionary] = []
var _pending_replace_offer_id: String = ""
var _weapon_icon_cache: Dictionary = {}
var _item_icon_cache: Dictionary = {}
var _offer_icon_cache: Dictionary = {}

var _owned_items_title_label: Label
var _owned_items_scroll: ScrollContainer
var _owned_items_grid: GridContainer
var _equipped_weapons_title_label: Label
var _equipped_weapons_grid: GridContainer
var _next_stage_panel: VBoxContainer
var _elite_hint_label: Label
var _pause_overlay: Control
var _pause_panel: PanelContainer
var _pause_dimmer: ColorRect
var _pause_resume_button: Button
var _pause_main_menu_button: Button
var _pause_save_button: Button
var _pause_settings_button: Button
var _pause_opened: bool = false
var _slot_panel: SaveSlotPanel
var _save_slot_panel_scene: PackedScene
var _settings_panel: Control
var _settings_scene_resource: PackedScene
var _pause_transition_tween: Tween
var _scene_input_ready: bool = false
var _queued_action: Callable = Callable()
var _queued_action_id: String = ""
var _selected_weapon_slot_index: int = -1
var _weapon_action_panel: Control
var _weapon_action_icon: TextureRect
var _weapon_action_title: Label
var _weapon_action_subtitle: Label
var _weapon_action_detail: RichTextLabel
var _weapon_action_tags: RichTextLabel
var _weapon_combine_button: Button
var _weapon_recycle_button: Button
var _weapon_cancel_button: Button

# --- Tooltip System ---
var _tag_tooltip_container: Control
var _is_hovering_weapon: bool = false

func _ready() -> void:
    randomize()
    if not _validate_ui_nodes():
        push_error("ShopScene UI binding failed.")
        return
    _prepare_pause_sub_scenes()
    _create_pause_overlay()
    _bind_pause_menu()
    _create_pause_sub_panels()
    _set_pause_overlay_visible(false)
    _build_dynamic_bottom_sections()
    if lock_button != null:
        lock_button.visible = false
    _shop_system = ShopSystemScript.new() as ShopSystem
    _shop_system.setup(BalanceService.get_shop_catalog())
    _snapshot = _build_default_snapshot(GameManager.consume_pending_shop_snapshot())
    _ensure_shop_state()
    _bind_buttons()
    if not resized.is_connected(_on_layout_resized):
        resized.connect(_on_layout_resized)
    _roll_if_needed()
    _apply_responsive_layout(get_viewport_rect().size)
    _rebuild_ui()
    _add_vignette_background()
    _create_tag_tooltip_layer()
    _arm_scene_ready_gate()

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("pause"):
        return
    _invoke_or_queue(
        "shop_pause_toggle",
        Callable(self, "_toggle_pause_overlay"),
        _tx("msg.common.loading_short", "Loading...")
    )

func _toggle_pause_overlay() -> void:
    if _pause_opened:
        if _is_pause_sub_panel_open():
            _hide_pause_sub_panels()
            return
        _resume_shop_from_pause()
        return
    _open_pause_menu()

func _arm_scene_ready_gate() -> void:
    _scene_input_ready = false
    call_deferred("_await_scene_input_ready")

func _await_scene_input_ready() -> void:
    await get_tree().process_frame
    var guard: int = 0
    while _is_scene_transition_pending() and guard < 180:
        guard += 1
        await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    _scene_input_ready = true
    _flush_queued_action()

func _invoke_or_queue(action_id: String, action: Callable, pending_text: String = "") -> void:
    if _scene_input_ready and not _is_scene_transition_pending():
        action.call()
        return
    if _queued_action_id.is_empty():
        _queued_action_id = action_id
        _queued_action = action
    if not pending_text.is_empty() and hint_label != null:
        hint_label.text = pending_text

func _flush_queued_action() -> void:
    if not _queued_action.is_valid():
        return
    var queued: Callable = _queued_action
    _queued_action = Callable()
    _queued_action_id = ""
    queued.call_deferred()

func _is_scene_transition_pending() -> bool:
    var gm_busy: bool = (
        GameManager != null
        and GameManager.has_method("is_scene_transition_busy")
        and bool(GameManager.call("is_scene_transition_busy"))
    )
    var crt_busy: bool = (
        CRTTransition != null
        and CRTTransition.has_method("is_busy")
        and bool(CRTTransition.call("is_busy"))
    )
    return gm_busy or crt_busy

func _is_shop_interaction_blocked() -> bool:
    return _pause_opened or _is_scene_transition_pending()

func _create_pause_overlay() -> void:
    if _pause_overlay != null and is_instance_valid(_pause_overlay):
        return

    _pause_overlay = Control.new()
    _pause_overlay.name = "PauseOverlay"
    _pause_overlay.visible = false
    _pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    _pause_overlay.z_index = PAUSE_OVERLAY_Z_INDEX
    _pause_overlay.anchors_preset = Control.PRESET_FULL_RECT
    _pause_overlay.anchor_right = 1.0
    _pause_overlay.anchor_bottom = 1.0
    _pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_pause_overlay)
    move_child(_pause_overlay, get_child_count() - 1)

    _pause_dimmer = ColorRect.new()
    _pause_dimmer.name = "Dimmer"
    _pause_dimmer.anchors_preset = Control.PRESET_FULL_RECT
    _pause_dimmer.anchor_right = 1.0
    _pause_dimmer.anchor_bottom = 1.0
    _pause_dimmer.color = Color(0.0, 0.0, 0.0, 0.35)
    _pause_overlay.add_child(_pause_dimmer)

    _pause_panel = PanelContainer.new()
    _pause_panel.name = "PausePanel"
    _pause_panel.anchor_left = 0.5
    _pause_panel.anchor_top = 0.5
    _pause_panel.anchor_right = 0.5
    _pause_panel.anchor_bottom = 0.5
    _pause_panel.offset_left = -170.0
    _pause_panel.offset_top = -180.0
    _pause_panel.offset_right = 170.0
    _pause_panel.offset_bottom = 180.0
    _pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    _pause_overlay.add_child(_pause_panel)

    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.0941176, 0.160784, 0.184314, 0.94)
    panel_style.border_width_left = 3
    panel_style.border_width_top = 3
    panel_style.border_width_right = 3
    panel_style.border_width_bottom = 3
    panel_style.border_color = Color(0.203922, 0.298039, 0.333333, 1.0)
    panel_style.corner_radius_top_left = 14
    panel_style.corner_radius_top_right = 14
    panel_style.corner_radius_bottom_right = 14
    panel_style.corner_radius_bottom_left = 14
    panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
    panel_style.shadow_size = 12
    _pause_panel.add_theme_stylebox_override("panel", panel_style)

    var pause_vbox: VBoxContainer = VBoxContainer.new()
    pause_vbox.name = "PauseVBox"
    pause_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    pause_vbox.add_theme_constant_override("separation", 14)
    _pause_panel.add_child(pause_vbox)

    _pause_resume_button = _create_pause_menu_button()
    _pause_main_menu_button = _create_pause_menu_button()
    _pause_save_button = _create_pause_menu_button()
    _pause_settings_button = _create_pause_menu_button()
    pause_vbox.add_child(_pause_resume_button)
    pause_vbox.add_child(_pause_main_menu_button)
    pause_vbox.add_child(_pause_save_button)
    pause_vbox.add_child(_pause_settings_button)

func _create_pause_menu_button() -> Button:
    var button: Button = Button.new()
    button.custom_minimum_size = Vector2(320.0, 62.0)
    button.add_theme_font_size_override("font_size", 34)
    if NEON_OPTION_BUTTON_SCRIPT != null:
        button.set_script(NEON_OPTION_BUTTON_SCRIPT)
    return button

func _bind_pause_menu() -> void:
    if _pause_resume_button == null:
        return
    _pause_resume_button.text = _tx("ui.pause.resume", "Resume")
    _pause_main_menu_button.text = _tx("ui.pause.main_menu", "Main Menu")
    _pause_save_button.text = _tx("ui.pause.save", "Save")
    _pause_settings_button.text = _tx("ui.pause.settings", "Settings")
    _pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)
    _pause_main_menu_button.pressed.connect(_on_pause_main_menu_button_pressed)
    _pause_save_button.pressed.connect(_on_pause_save_button_pressed)
    _pause_settings_button.pressed.connect(_on_pause_settings_button_pressed)

func _prepare_pause_sub_scenes() -> void:
    var loaded_scene: Resource = ResourceLoader.load(SAVE_SLOT_PANEL_SCENE_PATH)
    if loaded_scene is PackedScene:
        _save_slot_panel_scene = loaded_scene as PackedScene
    else:
        _save_slot_panel_scene = null
        push_error("Failed to load scene: %s" % SAVE_SLOT_PANEL_SCENE_PATH)

    var loaded_settings_scene: Resource = ResourceLoader.load(SETTINGS_SCENE_PATH)
    if loaded_settings_scene is PackedScene:
        _settings_scene_resource = loaded_settings_scene as PackedScene
    else:
        _settings_scene_resource = null
        push_error("Failed to load scene: %s" % SETTINGS_SCENE_PATH)

func _create_pause_sub_panels() -> void:
    if _pause_overlay == null:
        return
    var panel_node: Node = null
    if _save_slot_panel_scene != null:
        panel_node = _save_slot_panel_scene.instantiate()
    else:
        panel_node = SaveSlotPanel.new()
    _slot_panel = panel_node as SaveSlotPanel
    if _slot_panel != null:
        _add_pause_sub_panel(_slot_panel)
        _slot_panel.slot_selected.connect(_on_pause_slot_button_pressed)
        _slot_panel.panel_closed.connect(_hide_pause_sub_panels)
        _slot_panel.visible = false
    elif panel_node != null:
        panel_node.queue_free()

    if _settings_scene_resource != null:
        var settings_node: Node = _settings_scene_resource.instantiate()
        _settings_panel = settings_node as Control
        if _settings_panel != null:
            _add_pause_sub_panel(_settings_panel)
            _settings_panel.visible = false
            if _settings_panel.has_method("set_embedded_mode"):
                _settings_panel.call("set_embedded_mode", true)
            if _settings_panel.has_signal("request_close"):
                _settings_panel.connect("request_close", Callable(self, "_on_settings_panel_close_requested"))

func _add_pause_sub_panel(panel: Control) -> void:
    if _pause_overlay == null or panel == null:
        return
    _pause_overlay.add_child(panel)
    var panel_index: int = max(0, _pause_overlay.get_child_count() - 2)
    _pause_overlay.move_child(panel, panel_index)
    panel.z_index = PAUSE_OVERLAY_Z_INDEX + 1

func _open_pause_menu() -> void:
    if _is_scene_transition_pending():
        return
    _pause_opened = true
    _hide_pause_sub_panels()
    if _pause_overlay != null:
        _pause_overlay.move_to_front()
    _play_pause_overlay_open_transition()

func _resume_shop_from_pause() -> void:
    _pause_opened = false
    _hide_pause_sub_panels()
    _play_pause_overlay_close_transition()

func _set_pause_overlay_visible(is_visible: bool) -> void:
    _stop_pause_transition_tween()
    if _pause_overlay == null:
        return
    _pause_overlay.visible = is_visible
    _pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE
    if is_visible:
        _pause_overlay.move_to_front()
    if _pause_dimmer != null:
        _pause_dimmer.modulate.a = 1.0 if is_visible else 0.0
    if _pause_panel != null:
        _pause_panel.modulate.a = 1.0 if is_visible else 0.0
        _pause_panel.scale = Vector2.ONE
        _pause_panel.pivot_offset = _pause_panel.size * 0.5
    if not is_visible:
        _hide_pause_sub_panels()

func _play_pause_overlay_open_transition() -> void:
    if _pause_overlay == null or _pause_panel == null:
        _set_pause_overlay_visible(true)
        return
    _stop_pause_transition_tween()
    _pause_overlay.visible = true
    _pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _pause_overlay.move_to_front()
    _pause_panel.visible = true
    _pause_panel.pivot_offset = _pause_panel.size * 0.5
    _pause_panel.scale = Vector2(PAUSE_PANEL_POP_SCALE, PAUSE_PANEL_POP_SCALE)
    _pause_panel.modulate.a = 0.0
    if _pause_dimmer != null:
        _pause_dimmer.modulate.a = 0.0
    _pause_transition_tween = create_tween()
    _pause_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _pause_transition_tween.set_trans(Tween.TRANS_QUART)
    _pause_transition_tween.set_ease(Tween.EASE_OUT)
    _pause_transition_tween.parallel().tween_property(_pause_panel, "modulate:a", 1.0, PAUSE_OPEN_DURATION)
    _pause_transition_tween.parallel().tween_property(_pause_panel, "scale", Vector2.ONE, PAUSE_OPEN_DURATION)
    if _pause_dimmer != null:
        _pause_transition_tween.parallel().tween_property(_pause_dimmer, "modulate:a", 1.0, PAUSE_OPEN_DURATION)
    _pause_transition_tween.finished.connect(func() -> void:
        _pause_transition_tween = null
    )

func _play_pause_overlay_close_transition(on_finished: Callable = Callable()) -> void:
    if _pause_overlay == null or _pause_panel == null:
        _set_pause_overlay_visible(false)
        if on_finished.is_valid():
            on_finished.call()
        return
    if not _pause_overlay.visible:
        if on_finished.is_valid():
            on_finished.call()
        return
    _stop_pause_transition_tween()
    _pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _pause_panel.visible = true
    _pause_panel.pivot_offset = _pause_panel.size * 0.5
    _pause_transition_tween = create_tween()
    _pause_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _pause_transition_tween.set_trans(Tween.TRANS_QUART)
    _pause_transition_tween.set_ease(Tween.EASE_IN)
    _pause_transition_tween.parallel().tween_property(_pause_panel, "modulate:a", 0.0, PAUSE_CLOSE_DURATION)
    _pause_transition_tween.parallel().tween_property(
        _pause_panel,
        "scale",
        Vector2(PAUSE_PANEL_POP_SCALE, PAUSE_PANEL_POP_SCALE),
        PAUSE_CLOSE_DURATION
    )
    if _pause_dimmer != null:
        _pause_transition_tween.parallel().tween_property(_pause_dimmer, "modulate:a", 0.0, PAUSE_CLOSE_DURATION)
    _pause_transition_tween.finished.connect(func() -> void:
        if _pause_overlay != null:
            _pause_overlay.visible = false
        if _pause_panel != null:
            _pause_panel.modulate.a = 1.0
            _pause_panel.scale = Vector2.ONE
        if _pause_dimmer != null:
            _pause_dimmer.modulate.a = 1.0
        _pause_transition_tween = null
        if on_finished.is_valid():
            on_finished.call()
    )

func _stop_pause_transition_tween() -> void:
    if _pause_transition_tween != null and is_instance_valid(_pause_transition_tween):
        _pause_transition_tween.kill()
    _pause_transition_tween = null

func _on_pause_resume_button_pressed() -> void:
    _resume_shop_from_pause()

func _on_pause_main_menu_button_pressed() -> void:
    _pause_opened = false
    _play_pause_overlay_close_transition(func() -> void:
        GameManager.go_to_menu()
    )

func _on_pause_save_button_pressed() -> void:
    _show_slot_panel(SaveSlotPanel.MODE_SAVE)

func _on_pause_settings_button_pressed() -> void:
    _show_settings_panel()

func _show_slot_panel(mode: String) -> void:
    if _slot_panel == null:
        return
    if _settings_panel != null:
        _settings_panel.visible = false
    _slot_panel.setup(mode)
    _slot_panel.visible = true
    _slot_panel.move_to_front()
    if _pause_overlay != null:
        _pause_overlay.move_to_front()
    if _pause_panel != null:
        _pause_panel.visible = false

func _show_settings_panel() -> void:
    if _settings_panel == null:
        return
    if _slot_panel != null:
        _slot_panel.visible = false
    _settings_panel.visible = true
    _settings_panel.move_to_front()
    if _pause_overlay != null:
        _pause_overlay.move_to_front()
    if _pause_panel != null:
        _pause_panel.visible = false

func _hide_pause_sub_panels() -> void:
    if _slot_panel != null:
        _slot_panel.visible = false
    if _settings_panel != null:
        _settings_panel.visible = false
    if _pause_panel != null:
        _pause_panel.visible = true

func _is_pause_sub_panel_open() -> bool:
    var slot_open: bool = _slot_panel != null and _slot_panel.visible
    var settings_open: bool = _settings_panel != null and _settings_panel.visible
    return slot_open or settings_open

func _on_pause_slot_button_pressed(slot_id: String) -> void:
    if _slot_panel == null:
        return
    if _slot_panel.get_mode() != SaveSlotPanel.MODE_SAVE:
        return
    var save_payload: Dictionary = _build_runtime_save_payload()
    SaveSystem.save_to_slot(slot_id, save_payload)
    _slot_panel.show_hint(_tf("msg.slot.saved_to_fmt", [_slot_title(slot_id)], "Saved to %s"))
    _slot_panel.refresh_slots()

func _slot_title(slot_id: String) -> String:
    match slot_id:
        "slot_1":
            return _tx("ui.save_slot.slot_1", "Slot 1")
        "slot_2":
            return _tx("ui.save_slot.slot_2", "Slot 2")
        "slot_3":
            return _tx("ui.save_slot.slot_3", "Slot 3")
        _:
            return slot_id

func _on_settings_panel_close_requested() -> void:
    _hide_pause_sub_panels()

func _build_runtime_save_payload() -> Dictionary:
    _refresh_weapon_tag_state_snapshot()
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)

    var base_save: Dictionary = SaveSystem.load_save()
    var unlocked_characters: Array[String] = _extract_character_array(base_save.get("unlocked_characters", ["the_fool"]))
    var selected_character_id: String = _resolve_snapshot_character_id()
    if unlocked_characters.is_empty():
        unlocked_characters.append(selected_character_id)
    elif not unlocked_characters.has(selected_character_id):
        unlocked_characters.append(selected_character_id)

    var snapshot_stage_id: String = str(_snapshot.get("stage_id", GameManager.current_stage_id))
    var selected_starter_weapon_id: String = str(_snapshot.get("selected_starter_weapon_id", GameManager.selected_starter_weapon_id))
    var shop_state: Dictionary = {}
    var shop_state_value: Variant = _snapshot.get("shop_runtime_state", {})
    if shop_state_value is Dictionary:
        shop_state = (shop_state_value as Dictionary).duplicate(true)
    var stats_value: Variant = _snapshot.get("player_stats", {})
    var player_stats: Dictionary = {}
    if stats_value is Dictionary:
        player_stats = (stats_value as Dictionary).duplicate(true)
    var settings_value: Variant = base_save.get("settings", SaveSystem.DEFAULT_SETTINGS.duplicate(true))
    var settings_payload: Dictionary = SaveSystem.DEFAULT_SETTINGS.duplicate(true)
    if settings_value is Dictionary:
        settings_payload = (settings_value as Dictionary).duplicate(true)

    return {
        "unlocked_characters": unlocked_characters,
        "best_stage": str(base_save.get("best_stage", snapshot_stage_id)),
        "total_kills": int(base_save.get("total_kills", 0)),
        "total_gold": int(base_save.get("total_gold", 0)),
        "total_play_time": float(base_save.get("total_play_time", 0.0)),
        "selected_character": selected_character_id,
        "selected_starter_weapon_id": selected_starter_weapon_id,
        "difficulty": GameManager.current_difficulty,
        "stage_id": snapshot_stage_id,
        "wave": max(1, int(_snapshot.get("wave", 1))),
        "wave_progress_index": max(0, int(_snapshot.get("wave_progress_index", 0))),
        "player_hp": int(_snapshot.get("player_hp", _snapshot.get("player_max_hp", 100))),
        "player_max_hp": int(_snapshot.get("player_max_hp", 100)),
        "player_stamina": float(_snapshot.get("player_stamina", 100.0)),
        "player_stamina_max": float(_snapshot.get("player_stamina_max", 100.0)),
        "player_move_speed": float(_snapshot.get("player_move_speed", 220.0)),
        "bonus_target_range": float(_snapshot.get("bonus_target_range", 0.0)),
        "bonus_attack_damage": int(_snapshot.get("bonus_attack_damage", 0)),
        "player_stats": player_stats,
        "current_level": max(1, int(_snapshot.get("current_level", 1))),
        "current_xp": max(0, int(_snapshot.get("current_xp", 0))),
        "current_gold": max(0, int(_snapshot.get("current_gold", 0))),
        "shop_runtime_state": shop_state,
        "equipped_weapons": _normalize_weapon_slots(shop_state.get("equipped_weapons", [])),
        "locked_shop_offers": _normalize_locked_offers(shop_state.get("locked_shop_offers", [])),
        "reward_history": _extract_string_array(_snapshot.get("reward_history", [])),
        "recent_categories": _extract_string_array(_snapshot.get("recent_categories", [])),
        "build_tags": _extract_string_array(_snapshot.get("build_tags", [])),
        "reward_pity_state": _snapshot.get("reward_pity_state", {"no_output_streak": 0}),
        "reward_owned": _snapshot.get("reward_owned", {}),
        "auto_attack_interval_multiplier": float(_snapshot.get("auto_attack_interval_multiplier", 1.0)),
        "gold_gain_multiplier": float(_snapshot.get("gold_gain_multiplier", 1.0)),
        "run_survival_time": max(0.0, float(_snapshot.get("run_survival_time", 0.0))),
        "xp_to_next_level": max(1, int(_snapshot.get("xp_to_next_level", 20))),
        "player_pos_x": float(_snapshot.get("player_pos_x", 0.0)),
        "player_pos_y": float(_snapshot.get("player_pos_y", 0.0)),
        "settings": settings_payload,
    }

func _extract_character_array(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if value is Array:
        var raw_array: Array = value
        for item in raw_array:
            var character_id: String = str(item)
            if character_id.is_empty():
                continue
            if not result.has(character_id):
                result.append(character_id)
    return result

func _extract_string_array(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if value is Array:
        var raw_array: Array = value
        for item in raw_array:
            var text: String = str(item)
            if text.is_empty():
                continue
            result.append(text)
    return result

func _build_default_snapshot(raw: Dictionary) -> Dictionary:
    var snapshot: Dictionary = {
        "stage_id": GameManager.current_stage_id,
        "wave": max(1, GameManager.current_wave),
        "wave_progress_index": max(0, GameManager.current_wave - 1),
        "selected_character": GameManager.selected_character,
        "current_gold": 0,
        "player_max_hp": 100,
        "player_stats": {},
        "bonus_attack_damage": 0,
        "bonus_target_range": 0.0,
        "player_move_speed": 220.0,
        "gold_gain_multiplier": 1.0,
        "shop_runtime_state": {},
        "shop_offers": [],
    }
    for key: String in raw.keys():
        snapshot[key] = raw[key]
    var stats_value: Variant = snapshot.get("player_stats", {})
    var stats: Dictionary = {}
    if stats_value is Dictionary:
        stats = (stats_value as Dictionary).duplicate(true)
    var legacy_bonus_attack_damage: int = int(snapshot.get("bonus_attack_damage", 0))
    var combat_params: Dictionary = BalanceService.get_global_combat_params()
    var attack_flat_to_percent: float = max(0.0, float(combat_params.get("attack_flat_to_global_attack_percent", 3.0)))
    if legacy_bonus_attack_damage != 0 and not stats.has("global_attack_percent"):
        stats["global_attack_percent"] = float(legacy_bonus_attack_damage) * attack_flat_to_percent
    if not stats.has("luck"):
        stats["luck"] = 0.0
    if not stats.has("harvest"):
        stats["harvest"] = 0.0
    if not stats.has("hp_regen"):
        stats["hp_regen"] = 0.0
    snapshot["player_stats"] = stats
    return snapshot

func _ensure_shop_state() -> void:
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    if not (state is Dictionary):
        state = {}
    state["equipped_weapons"] = _normalize_weapon_slots(state.get("equipped_weapons", []))
    state["locked_shop_offers"] = _normalize_locked_offers(state.get("locked_shop_offers", []))
    state["owned_items"] = _normalize_owned_items(state.get("owned_items", []))
    state["refresh_count"] = max(0, int(state.get("refresh_count", 0)))

    var legacy_shop_locked: bool = bool(state.get("shop_locked", false))
    if legacy_shop_locked:
        var legacy_migrated: Array[Dictionary] = []
        for i: int in range(state["locked_shop_offers"].size()):
            var row: Dictionary = (state["locked_shop_offers"][i] as Dictionary).duplicate(true)
            row["slot_index"] = int(row.get("slot_index", i))
            row["locked"] = true
            row["sold"] = false
            if str(row.get("icon_path", "")).is_empty():
                row["icon_path"] = _resolve_offer_icon_path(row)
            legacy_migrated.append(row)
        state["locked_shop_offers"] = legacy_migrated
    state["shop_locked"] = false
    _snapshot["shop_runtime_state"] = state
    _snapshot["shop_offers"] = _normalize_offer_list(_snapshot.get("shop_offers", []))
    _refresh_weapon_tag_state_snapshot()

func _bind_buttons() -> void:
    refresh_button.pressed.connect(_on_refresh_pressed)
    next_wave_button.pressed.connect(_on_next_wave_pressed)

func _validate_ui_nodes() -> bool:
    return (
        gold_label != null
        and wave_label != null
        and refresh_button != null
        and next_wave_button != null
        and offers_grid != null
        and attr_label != null
        and mid_row != null
        and right_panel != null
        and bottom_panel != null
        and top_bar != null
        and top_bar_spacer != null
        and weapon_slots_row != null
        and hint_label != null
        and bottom_vbox != null
        and bottom_actions != null
    )

func _build_dynamic_bottom_sections() -> void:
    if _owned_items_grid != null and _equipped_weapons_grid != null and _elite_hint_label != null:
        return

    for child: Node in weapon_slots_row.get_children():
        child.queue_free()

    weapon_slots_row.add_theme_constant_override("separation", 16)
    _reparent_status_hint_to_top_bar()
    bottom_actions.visible = false
    bottom_actions.custom_minimum_size = Vector2.ZERO

    var owned_panel: VBoxContainer = VBoxContainer.new()
    owned_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    owned_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    owned_panel.size_flags_stretch_ratio = ITEMS_PANEL_RATIO
    owned_panel.add_theme_constant_override("separation", 6)
    _owned_items_title_label = Label.new()
    _owned_items_title_label.text = _tx("ui.shop.owned_items_title", "Items")
    _owned_items_scroll = ScrollContainer.new()
    _owned_items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _owned_items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _owned_items_scroll.custom_minimum_size = Vector2(0, 132)
    var owned_items_scroll_content: VBoxContainer = VBoxContainer.new()
    owned_items_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    owned_items_scroll_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _owned_items_grid = GridContainer.new()
    _owned_items_grid.columns = 8
    _owned_items_grid.add_theme_constant_override("h_separation", 6)
    _owned_items_grid.add_theme_constant_override("v_separation", 6)
    owned_items_scroll_content.add_child(_owned_items_grid)
    _owned_items_scroll.add_child(owned_items_scroll_content)
    owned_panel.add_child(_owned_items_title_label)
    owned_panel.add_child(_owned_items_scroll)

    var weapons_panel: VBoxContainer = VBoxContainer.new()
    weapons_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    weapons_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    weapons_panel.size_flags_stretch_ratio = WEAPONS_PANEL_RATIO
    weapons_panel.add_theme_constant_override("separation", 6)
    _equipped_weapons_title_label = Label.new()
    _equipped_weapons_title_label.text = _tf("ui.shop.equipped_weapons_title_fmt", [0, WEAPON_SLOT_COUNT], "Weapons (%d/%d)")
    _equipped_weapons_grid = GridContainer.new()
    _equipped_weapons_grid.columns = WEAPON_GRID_COLUMNS
    _equipped_weapons_grid.add_theme_constant_override("h_separation", 6)
    _equipped_weapons_grid.add_theme_constant_override("v_separation", 6)
    _build_weapon_action_panel()
    add_child(_weapon_action_panel)
    _weapon_action_panel.move_to_front()
    weapons_panel.add_child(_equipped_weapons_title_label)
    weapons_panel.add_child(_equipped_weapons_grid)

    _next_stage_panel = VBoxContainer.new()
    _next_stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _next_stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _next_stage_panel.size_flags_stretch_ratio = NEXT_STAGE_PANEL_RATIO
    _next_stage_panel.custom_minimum_size = Vector2(220, 0)
    _next_stage_panel.add_theme_constant_override("separation", 8)
    _next_stage_panel.alignment = BoxContainer.ALIGNMENT_END

    weapon_slots_row.add_child(owned_panel)
    weapon_slots_row.add_child(weapons_panel)
    weapon_slots_row.add_child(_next_stage_panel)

    _elite_hint_label = Label.new()
    _elite_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _elite_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _elite_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _elite_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    _elite_hint_label.custom_minimum_size = Vector2(0, 44)
    _next_stage_panel.add_child(_elite_hint_label)
    _reparent_next_wave_button_to_next_stage_panel()
    next_wave_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    next_wave_button.custom_minimum_size = Vector2(220, 56)

func _build_weapon_action_panel() -> void:
    _weapon_action_panel = HBoxContainer.new()
    _weapon_action_panel.custom_minimum_size = Vector2(560, 300)
    _weapon_action_panel.size = _weapon_action_panel.custom_minimum_size
    _weapon_action_panel.z_index = FLOATING_DETAIL_Z_INDEX
    _weapon_action_panel.visible = false
    (_weapon_action_panel as HBoxContainer).add_theme_constant_override("separation", 8)

    var weapon_panel: PanelContainer = PanelContainer.new()
    weapon_panel.custom_minimum_size = Vector2(312, 300)
    weapon_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    weapon_panel.add_theme_stylebox_override(
        "panel",
        _make_brotato_panel_style(Color(0.02, 0.02, 0.02, 0.94), Color(0.28, 0.28, 0.28, 1.0), 2, 5)
    )
    _weapon_action_panel.add_child(weapon_panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 8)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_right", 8)
    margin.add_theme_constant_override("margin_bottom", 6)
    weapon_panel.add_child(margin)

    var root: VBoxContainer = VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    margin.add_child(root)

    var main_col: VBoxContainer = VBoxContainer.new()
    main_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_col.add_theme_constant_override("separation", 8)
    root.add_child(main_col)

    var header: HBoxContainer = HBoxContainer.new()
    header.add_theme_constant_override("separation", 10)
    main_col.add_child(header)

    var icon_frame: PanelContainer = PanelContainer.new()
    icon_frame.custom_minimum_size = Vector2(70, 70)
    icon_frame.add_theme_stylebox_override(
        "panel",
        _make_brotato_panel_style(Color(0.06, 0.06, 0.06, 1.0), Color(0.22, 0.22, 0.22, 1.0), 1, 4)
    )
    header.add_child(icon_frame)

    _weapon_action_icon = TextureRect.new()
    _weapon_action_icon.custom_minimum_size = Vector2(64, 64)
    _weapon_action_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _weapon_action_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_frame.add_child(_weapon_action_icon)

    var title_box: VBoxContainer = VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_box.add_theme_constant_override("separation", 2)
    header.add_child(title_box)

    _weapon_action_title = Label.new()
    _weapon_action_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _weapon_action_title.add_theme_font_size_override("font_size", 19)
    _weapon_action_title.add_theme_color_override("font_color", Color(0.96, 0.96, 0.9, 1.0))
    title_box.add_child(_weapon_action_title)

    _weapon_action_subtitle = Label.new()
    _weapon_action_subtitle.add_theme_font_size_override("font_size", 14)
    _weapon_action_subtitle.add_theme_color_override("font_color", Color(0.82, 0.78, 0.62, 1.0))
    title_box.add_child(_weapon_action_subtitle)

    _weapon_action_detail = RichTextLabel.new()
    _weapon_action_detail.bbcode_enabled = true
    _weapon_action_detail.fit_content = false
    _weapon_action_detail.scroll_active = false
    _weapon_action_detail.custom_minimum_size = Vector2(0, 108)
    _weapon_action_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_col.add_child(_weapon_action_detail)

    var actions: HBoxContainer = HBoxContainer.new()
    actions.add_theme_constant_override("separation", 6)
    root.add_child(actions)

    _weapon_combine_button = _make_shop_action_button(_tx("ui.shop.combine", "Combine"))
    _weapon_recycle_button = _make_shop_action_button(_tx("ui.shop.recycle", "Recycle"))
    _weapon_cancel_button = _make_shop_action_button(_tx("ui.common.cancel", "Cancel"))
    _weapon_combine_button.pressed.connect(_on_weapon_combine_pressed)
    _weapon_recycle_button.pressed.connect(_on_weapon_recycle_pressed)
    _weapon_cancel_button.pressed.connect(_on_weapon_cancel_pressed)
    actions.add_child(_weapon_combine_button)
    actions.add_child(_weapon_recycle_button)
    actions.add_child(_weapon_cancel_button)

    var tags_panel: PanelContainer = PanelContainer.new()
    tags_panel.custom_minimum_size = Vector2(240, 300)
    tags_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tags_panel.add_theme_stylebox_override(
        "panel",
        _make_brotato_panel_style(Color(0.02, 0.02, 0.02, 0.94), Color(0.28, 0.28, 0.28, 1.0), 2, 5)
    )
    _weapon_action_panel.add_child(tags_panel)

    var tags_margin: MarginContainer = MarginContainer.new()
    tags_margin.add_theme_constant_override("margin_left", 8)
    tags_margin.add_theme_constant_override("margin_top", 8)
    tags_margin.add_theme_constant_override("margin_right", 8)
    tags_margin.add_theme_constant_override("margin_bottom", 8)
    tags_panel.add_child(tags_margin)

    _weapon_action_tags = RichTextLabel.new()
    _weapon_action_tags.bbcode_enabled = true
    _weapon_action_tags.fit_content = false
    _weapon_action_tags.scroll_active = true
    _weapon_action_tags.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _weapon_action_tags.add_theme_font_size_override("normal_font_size", 11)
    _weapon_action_tags.add_theme_font_size_override("bold_font_size", 12)
    _weapon_action_tags.add_theme_constant_override("line_separation", 0)
    tags_margin.add_child(_weapon_action_tags)

func _make_shop_action_button(text_value: String) -> Button:
    var button: Button = Button.new()
    button.text = text_value
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 36)
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_stylebox_override("normal", _make_brotato_panel_style(Color(0.08, 0.08, 0.08, 1.0), Color(0.18, 0.18, 0.18, 1.0), 1, 4))
    button.add_theme_stylebox_override("hover", _make_brotato_panel_style(Color(0.13, 0.13, 0.13, 1.0), Color(0.55, 0.55, 0.48, 1.0), 1, 4))
    return button

func _roll_if_needed() -> void:
    var existing: Array[Dictionary] = _normalize_offer_list(_snapshot.get("shop_offers", []))
    if not existing.is_empty():
        _shop_offers = _apply_locked_flags_from_state(existing)
    if _shop_offers.is_empty():
        _shop_offers = _shop_system.roll_shop_offers(_snapshot)
    _shop_offers = _normalize_offer_list(_shop_offers)
    _shop_offers = _apply_locked_flags_from_state(_shop_offers)
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)

func _on_refresh_pressed() -> void:
    if _is_shop_interaction_blocked():
        return
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = _tx("msg.shop.finish_replacement_first", "Please finish weapon replacement first.")
        return
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var refresh_count: int = int(state.get("refresh_count", 0))
    var stage_id: String = str(_snapshot.get("stage_id", "stage_001"))
    var stage_num: int = int(stage_id.split("_")[-1]) if "_" in stage_id else 1
    
    var refresh_price: int = _calculate_refresh_price(stage_num, refresh_count)
    var current_gold: int = int(_snapshot.get("current_gold", 0))
    if current_gold < refresh_price:
        hint_label.text = _tx("msg.shop.not_enough_gold_refresh", "Not enough gold for refresh.")
        return
    _snapshot["current_gold"] = current_gold - refresh_price
    state["refresh_count"] = refresh_count + 1
    state["shop_locked"] = false
    _snapshot["shop_runtime_state"] = state
    _synchronize_locked_offers_state(false)
    _shop_offers = _shop_system.roll_shop_offers(_snapshot)
    _shop_offers = _normalize_offer_list(_shop_offers)
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)
    hint_label.text = _tx("msg.shop.refreshed", "Shop refreshed.")
    _rebuild_ui()

func _on_next_wave_pressed() -> void:
    if _is_shop_interaction_blocked():
        return
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = _tx("msg.shop.choose_slot_replace", "Choose a slot to replace first.")
        return
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    state.erase("pending_replace_weapon")
    state["shop_locked"] = false
    _snapshot["shop_runtime_state"] = state
    _synchronize_locked_offers_state(false)
    _refresh_weapon_tag_state_snapshot()
    _snapshot["shop_offers"] = []
    
    # Resolve next stage ID so the game starts the correct next level
    var current_id: String = str(_snapshot.get("stage_id", "stage_001"))
    var next_id: String = _resolve_next_stage_id(current_id)
    if not next_id.is_empty():
        _snapshot["stage_id"] = next_id
        
    GameManager.continue_from_shop(_snapshot)

func _on_offer_buy_pressed(offer_id: String) -> void:
    if _is_shop_interaction_blocked():
        return
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = _tx("msg.shop.choose_weapon_slot", "Choose a weapon slot first.")
        return
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)
    var result: Dictionary = _shop_system.purchase_offer(offer_id, _snapshot)
    var updated_state: Dictionary = result.get("state", _snapshot)
    if bool(result.get("ok", false)):
        _snapshot = updated_state
        _ensure_shop_state()
        _shop_offers = _normalize_offer_list(_snapshot.get("shop_offers", []))
        _shop_offers = _apply_locked_flags_from_state(_shop_offers)
        _snapshot["shop_offers"] = _shop_offers.duplicate(true)
        _pending_replace_offer_id = ""
        _synchronize_locked_offers_state(false)
        hint_label.text = _tx(str(result.get("message", "msg.shop.purchase_success")), "Purchased.")
        _rebuild_ui()
        return
    if bool(result.get("needs_replace", false)):
        _snapshot = updated_state
        _ensure_shop_state()
        _pending_replace_offer_id = offer_id
        hint_label.text = _tx("msg.shop.weapon_slots_full_click_replace", "Weapon slots full. Click a slot below to replace.")
        _rebuild_ui()
        return
    hint_label.text = _tx(str(result.get("message", "msg.shop.purchase_failed")), "Purchase failed")
    _rebuild_ui()

func _on_offer_lock_pressed(offer_id: String) -> void:
    if _is_shop_interaction_blocked():
        return
    if not _pending_replace_offer_id.is_empty():
        hint_label.text = _tx("msg.shop.finish_replacement_first", "Please finish weapon replacement first.")
        return
    for i: int in range(_shop_offers.size()):
        var offer: Dictionary = _shop_offers[i]
        if str(offer.get("offer_id", "")) != offer_id:
            continue
        if bool(offer.get("sold", false)):
            hint_label.text = _tx("msg.shop.offer_sold", "Offer already sold")
            return
        var next_locked: bool = not bool(offer.get("locked", false))
        offer["locked"] = next_locked
        offer["slot_index"] = int(offer.get("slot_index", i))
        _shop_offers[i] = offer
        _snapshot["shop_offers"] = _shop_offers.duplicate(true)
        _synchronize_locked_offers_state(true)
        hint_label.text = _tx(
            "msg.shop.offer_locked" if next_locked else "msg.shop.offer_unlocked",
            "Offer locked." if next_locked else "Offer unlocked."
        )
        _rebuild_ui()
        return

func _on_weapon_slot_pressed(slot_index: int) -> void:
    if _is_shop_interaction_blocked():
        return
    if _pending_replace_offer_id.is_empty():
        _select_weapon_slot(slot_index)
        return
    _snapshot["replace_slot_index"] = slot_index
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)
    var result: Dictionary = _shop_system.purchase_offer(_pending_replace_offer_id, _snapshot)
    _snapshot.erase("replace_slot_index")
    if bool(result.get("ok", false)):
        _snapshot = result.get("state", _snapshot)
        _ensure_shop_state()
        _shop_offers = _normalize_offer_list(_snapshot.get("shop_offers", []))
        _shop_offers = _apply_locked_flags_from_state(_shop_offers)
        _snapshot["shop_offers"] = _shop_offers.duplicate(true)
        _pending_replace_offer_id = ""
        _synchronize_locked_offers_state(false)
        hint_label.text = _tx("msg.shop.weapon_replaced", "Weapon replaced.")
    else:
        hint_label.text = _tx(str(result.get("message", "msg.shop.replace_failed")), "Replace failed")
    _rebuild_ui()

func _select_weapon_slot(slot_index: int) -> void:
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var slots: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    if slot_index < 0 or slot_index >= slots.size():
        _selected_weapon_slot_index = -1
        _rebuild_ui()
        return
    if not (slots[slot_index] is Dictionary) or str((slots[slot_index] as Dictionary).get("weapon_id", "")).is_empty():
        _selected_weapon_slot_index = -1
        hint_label.text = _tx("msg.shop.weapon_slot_empty", "Empty weapon slot.")
        _rebuild_ui()
        return
    _selected_weapon_slot_index = slot_index
    hint_label.text = _tx("msg.shop.weapon_selected", "Weapon selected.")
    _rebuild_ui()

func _on_weapon_combine_pressed() -> void:
    if _is_shop_interaction_blocked():
        return
    if _selected_weapon_slot_index < 0:
        return
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)
    var result: Dictionary = _shop_system.combine_weapon_slot(_selected_weapon_slot_index, _snapshot)
    _snapshot = result.get("state", _snapshot)
    _ensure_shop_state()
    _selected_weapon_slot_index = -1
    hint_label.text = _tx(str(result.get("message", "msg.shop.combine_failed")), "Combine failed.")
    _rebuild_ui()

func _on_weapon_recycle_pressed() -> void:
    if _is_shop_interaction_blocked():
        return
    if _selected_weapon_slot_index < 0:
        return
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
    _synchronize_locked_offers_state(false)
    var result: Dictionary = _shop_system.recycle_weapon_slot(_selected_weapon_slot_index, _snapshot)
    _snapshot = result.get("state", _snapshot)
    _ensure_shop_state()
    _selected_weapon_slot_index = -1
    if bool(result.get("ok", false)):
        hint_label.text = _tf("msg.shop.recycle_success_fmt", [int(result.get("refund", 0))], "Recycled for %dG.")
    else:
        hint_label.text = _tx(str(result.get("message", "msg.shop.recycle_failed")), "Recycle failed.")
    _rebuild_ui()

func _on_weapon_cancel_pressed() -> void:
    _selected_weapon_slot_index = -1
    _rebuild_ui()

func _synchronize_locked_offers_state(sync_snapshot_offers: bool) -> void:
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    if not (state is Dictionary):
        state = {}
    var locked_subset: Array[Dictionary] = []
    for i: int in range(_shop_offers.size()):
        var offer: Dictionary = (_shop_offers[i] as Dictionary).duplicate(true)
        offer["slot_index"] = int(offer.get("slot_index", i))
        var is_locked: bool = bool(offer.get("locked", false))
        var is_sold: bool = bool(offer.get("sold", false))
        if is_locked and not is_sold:
            locked_subset.append(offer)
    state["locked_shop_offers"] = locked_subset
    state["shop_locked"] = false
    state["owned_items"] = _normalize_owned_items(state.get("owned_items", []))
    _snapshot["shop_runtime_state"] = state
    _snapshot["locked_shop_offers"] = locked_subset.duplicate(true)
    if sync_snapshot_offers:
        _snapshot["shop_offers"] = _shop_offers.duplicate(true)

func _clear_shop_offer_locks_for_transition() -> void:
    for i: int in range(_shop_offers.size()):
        var offer: Dictionary = (_shop_offers[i] as Dictionary).duplicate(true)
        offer["locked"] = false
        offer["slot_index"] = int(offer.get("slot_index", i))
        _shop_offers[i] = offer

    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    if not (state is Dictionary):
        state = {}
    state["locked_shop_offers"] = []
    state["shop_locked"] = false
    _snapshot["shop_runtime_state"] = state

func _normalize_offer_list(raw: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not (raw is Array):
        return result
    var source: Array = raw
    for i: int in range(source.size()):
        var row: Variant = source[i]
        if not (row is Dictionary):
            continue
        var offer: Dictionary = (row as Dictionary).duplicate(true)
        offer["slot_index"] = int(offer.get("slot_index", i))
        offer["locked"] = bool(offer.get("locked", false))
        offer["sold"] = bool(offer.get("sold", false))
        if str(offer.get("icon_path", "")).is_empty():
            offer["icon_path"] = _resolve_offer_icon_path(offer)
        result.append(offer)
    return result

func _apply_locked_flags_from_state(offers: Array[Dictionary]) -> Array[Dictionary]:
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var locked_source: Array[Dictionary] = _normalize_locked_offers(state.get("locked_shop_offers", []))
    var locked_by_offer_id: Dictionary = {}
    var legacy_locked_slots: Dictionary = {}
    for locked_offer: Dictionary in locked_source:
        if bool(locked_offer.get("sold", false)):
            continue
        var locked_offer_id: String = str(locked_offer.get("offer_id", ""))
        if locked_offer_id.is_empty():
            legacy_locked_slots[int(locked_offer.get("slot_index", -1))] = locked_offer
            continue
        locked_by_offer_id[locked_offer_id] = locked_offer

    var result: Array[Dictionary] = []
    for i: int in range(offers.size()):
        var offer: Dictionary = offers[i].duplicate(true)
        var slot_index: int = int(offer.get("slot_index", i))
        offer["slot_index"] = slot_index
        var is_locked: bool = false
        var offer_id: String = str(offer.get("offer_id", ""))
        if not offer_id.is_empty() and locked_by_offer_id.has(offer_id):
            var locked_offer: Dictionary = locked_by_offer_id[offer_id]
            is_locked = _offer_matches_locked_record(offer, locked_offer)
        elif legacy_locked_slots.has(slot_index):
            var legacy_locked_offer: Dictionary = legacy_locked_slots[slot_index]
            is_locked = _offer_matches_locked_record(offer, legacy_locked_offer)
        offer["locked"] = is_locked and not bool(offer.get("sold", false))
        if str(offer.get("icon_path", "")).is_empty():
            offer["icon_path"] = _resolve_offer_icon_path(offer)
        result.append(offer)
    return result

func _offer_matches_locked_record(offer: Dictionary, locked_offer: Dictionary) -> bool:
    var offer_slot: int = int(offer.get("slot_index", -1))
    var locked_slot: int = int(locked_offer.get("slot_index", -1))
    if offer_slot != locked_slot:
        return false

    var locked_offer_id: String = str(locked_offer.get("offer_id", ""))
    if not locked_offer_id.is_empty():
        return str(offer.get("offer_id", "")) == locked_offer_id

    var offer_kind: String = str(offer.get("kind", ""))
    if offer_kind != str(locked_offer.get("kind", "")):
        return false
    if offer_kind == "weapon":
        return _extract_offer_weapon_id(offer) == _extract_offer_weapon_id(locked_offer)
    return str(offer.get("item_id", "")) == str(locked_offer.get("item_id", ""))

func _normalize_locked_offers(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not (value is Array):
        return result
    var raw_array: Array = value
    for i: int in range(raw_array.size()):
        var row_value: Variant = raw_array[i]
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = (row_value as Dictionary).duplicate(true)
        row["slot_index"] = int(row.get("slot_index", i))
        row["locked"] = bool(row.get("locked", true))
        row["sold"] = bool(row.get("sold", false))
        if str(row.get("icon_path", "")).is_empty():
            row["icon_path"] = _resolve_offer_icon_path(row)
        result.append(row)
    return result

func _normalize_owned_items(value: Variant) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not (value is Array):
        return result
    var raw_array: Array = value
    for row_value: Variant in raw_array:
        if not (row_value is Dictionary):
            continue
        var row: Dictionary = row_value
        var item_id: String = str(row.get("item_id", ""))
        if item_id.is_empty():
            continue
        var normalized: Dictionary = {
            "item_id": item_id,
            "count": max(1, int(row.get("count", 1))),
            "rarity": str(row.get("rarity", "common")),
            "icon_path": str(row.get("icon_path", "")),
        }
        if str(normalized.get("icon_path", "")).is_empty():
            normalized["icon_path"] = _resolve_item_icon_path(item_id)
        result.append(normalized)
    return result

func _normalize_weapon_slots(raw_slots: Variant) -> Array:
    var slots: Array = []
    if raw_slots is Array:
        var raw_array: Array = raw_slots
        for i: int in range(min(raw_array.size(), WEAPON_SLOT_COUNT)):
            var item: Variant = raw_array[i]
            slots.append(item.duplicate(true) if item is Dictionary else {})
    while slots.size() < WEAPON_SLOT_COUNT:
        slots.append({})
    return slots


func _calculate_refresh_price(stage_num: int, refresh_count: int) -> int:
    # Base price starts at current stage index.
    var base: int = max(1, stage_num)
    # Inflation: +1G for early stages, scales up every 5 stages.
    var inflation: int = 1 + int(max(0, stage_num - 1) / 5)
    return base + (refresh_count * inflation)

func _rebuild_ui() -> void:
    _apply_responsive_layout(get_viewport_rect().size)
    gold_label.text = _tf("ui.shop.gold_fmt", [int(_snapshot.get("current_gold", 0))], "金币: %d")
    wave_label.text = _tf("ui.shop.wave_fmt", [str(_snapshot.get("stage_id", GameManager.current_stage_id))], "关卡 %s 商店")
    
    # 样式化全局面板
    var panel_style: StyleBoxFlat = _build_neon_style(Color(0.04, 0.06, 0.09, 0.94), Color("#1a3a4a"), 2, 8)
    if right_panel: right_panel.add_theme_stylebox_override("panel", panel_style)
    if bottom_panel: bottom_panel.add_theme_stylebox_override("panel", panel_style)
    
    # 样式化主交互按钮
    var btn_style: StyleBoxFlat = _build_neon_style(Color(0.1, 0.15, 0.2, 0.9), Color("#00f0ff"), 2, 10)
    var btn_hover: StyleBoxFlat = btn_style.duplicate()
    btn_hover.bg_color = Color(0.15, 0.22, 0.3, 0.9)
    btn_hover.border_width_left = 3
    btn_hover.border_width_top = 3
    btn_hover.border_width_right = 3
    btn_hover.border_width_bottom = 3
    
    refresh_button.add_theme_stylebox_override("normal", btn_style)
    refresh_button.add_theme_stylebox_override("hover", btn_hover)
    next_wave_button.add_theme_stylebox_override("normal", btn_style)
    next_wave_button.add_theme_stylebox_override("hover", btn_hover)

    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var stage_id: String = str(_snapshot.get("stage_id", "stage_001"))
    var stage_num: int = int(stage_id.split("_")[-1]) if "_" in stage_id else 1
    var refresh_count: int = int(shop_state.get("refresh_count", 0))
    var refresh_price: int = _calculate_refresh_price(stage_num, refresh_count)
    refresh_button.text = _tf("ui.shop.refresh_fmt", [refresh_price], "刷新 (%dG)")
    if lock_button != null:
        lock_button.visible = false
    next_wave_button.text = _tx("ui.shop.next_stage", "开始下一关")
    next_wave_button.disabled = false
    _rebuild_offer_cards_brotato()
    _rebuild_attr_panel_brotato()
    _rebuild_owned_items_grid()
    _rebuild_weapon_slots_grid()
    _rebuild_elite_hint()

func _reparent_status_hint_to_top_bar() -> void:
    if hint_label == null or top_bar == null:
        return
    if hint_label.get_parent() != top_bar:
        var existing_parent: Node = hint_label.get_parent()
        if existing_parent != null:
            existing_parent.remove_child(hint_label)
        top_bar.add_child(hint_label)
    var spacer_index: int = top_bar.get_children().find(top_bar_spacer)
    if spacer_index > 0:
        top_bar.move_child(hint_label, spacer_index)
    hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hint_label.custom_minimum_size = Vector2(260, 0)
    hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    hint_label.clip_text = true
    hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _reparent_next_wave_button_to_next_stage_panel() -> void:
    if next_wave_button == null:
        return
    if _next_stage_panel == null:
        return
    if next_wave_button.get_parent() == _next_stage_panel:
        return
    var existing_parent: Node = next_wave_button.get_parent()
    if existing_parent != null:
        existing_parent.remove_child(next_wave_button)
    _next_stage_panel.add_child(next_wave_button)

func _on_layout_resized() -> void:
    _apply_responsive_layout(get_viewport_rect().size)

func _apply_responsive_layout(viewport_size: Vector2) -> void:
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    if bottom_panel != null:
        bottom_panel.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.30, 208.0, 280.0))
    if mid_row != null:
        mid_row.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.43, 286.0, 390.0))
    if right_panel != null:
        right_panel.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.23, 260.0, 360.0), 0)
    if attr_label != null:
        attr_label.fit_content = false
        attr_label.scroll_active = true
        attr_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    if _next_stage_panel != null:
        _next_stage_panel.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.19, 220.0, 320.0), 0)
    if next_wave_button != null:
        next_wave_button.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.16, 210.0, 300.0), 56.0)

func _rebuild_offer_cards() -> void:
    for child: Node in offers_grid.get_children():
        child.queue_free()
    var current_gold: int = int(_snapshot.get("current_gold", 0))
    for i: int in range(_shop_offers.size()):
        var offer: Dictionary = _shop_offers[i]
        var offer_name: String = _resolve_offer_name(offer)
        var offer_desc: String = _resolve_offer_desc(offer)
        var rarity_key: String = str(offer.get("rarity", "common"))
        var rarity_color: Color = RARITY_COLORS.get(rarity_key, Color.WHITE)
        var is_locked: bool = bool(offer.get("locked", false))
        var sold: bool = bool(offer.get("sold", false))

        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size = Vector2(210, 198)
        card.pivot_offset = Vector2(105, 99) # 中心点
        card.add_theme_stylebox_override("panel", _build_offer_card_style(rarity_key, is_locked, sold))

        # --- 动态入场动画 ---
        card.modulate.a = 0
        card.scale = Vector2(0.85, 0.85)
        var tween: Tween = create_tween().set_parallel(true)
        tween.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(i * 0.04)
        tween.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * 0.04)
        # ------------------

        var margin: MarginContainer = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 6)
        margin.add_theme_constant_override("margin_top", 6)
        margin.add_theme_constant_override("margin_right", 6)
        margin.add_theme_constant_override("margin_bottom", 6)

        var vb: VBoxContainer = VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)

        var title: Label = Label.new()
        var prefix: String = "✧ " if rarity_key == "legendary" else "◈ "
        title.text = prefix + offer_name
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        title.add_theme_color_override("font_color", rarity_color) # 标题颜色与品质挂钩
        title.add_theme_font_size_override("font_size", 18)

        var icon_texture: Texture2D = _load_offer_icon(offer)
        var icon_block: Control = _build_icon_block(icon_texture, OFFER_ICON_SIZE, _tx("ui.shop.no_image", "No Image"))

        var desc: Label = Label.new()
        desc.text = offer_desc
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.max_lines_visible = 4
        desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
        desc.clip_text = true
        desc.add_theme_font_size_override("font_size", 14)

        var actions_row: HBoxContainer = HBoxContainer.new()
        actions_row.add_theme_constant_override("separation", 4)

        var lock_button_local: Button = Button.new()
        lock_button_local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        lock_button_local.text = _tx("ui.shop.offer_unlock", "解锁") if is_locked else _tx("ui.shop.offer_lock", "锁定")
        lock_button_local.disabled = sold
        lock_button_local.pressed.connect(_on_offer_lock_pressed.bind(str(offer.get("offer_id", ""))))

        var buy_button: Button = Button.new()
        buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        buy_button.text = _tx("ui.shop.sold_out", "已售罄") if sold else _tf("ui.shop.buy_fmt", [int(offer.get("price", 0))], "购买 - %dG")
        buy_button.disabled = sold or current_gold < int(offer.get("price", 0))
        buy_button.pressed.connect(_on_offer_buy_pressed.bind(str(offer.get("offer_id", ""))))
        
        # 按钮样式
        var buy_btn_style: StyleBoxFlat = _build_neon_style(Color(0.12, 0.18, 0.24, 0.9), Color("#00f0ff"), 1, 6)
        buy_button.add_theme_stylebox_override("normal", buy_btn_style)
        lock_button_local.add_theme_stylebox_override("normal", buy_btn_style)

        actions_row.add_child(lock_button_local)
        actions_row.add_child(buy_button)

        vb.add_child(title)
        vb.add_child(icon_block)
        vb.add_child(desc)
        vb.add_child(actions_row)

        margin.add_child(vb)
        card.add_child(margin)
        
        # 绑定悬停事件显示标签详情
        card.mouse_entered.connect(_on_weapon_card_hover_start.bind(offer, card))
        card.mouse_exited.connect(_on_weapon_hover_end)
        offers_grid.add_child(card)

func _rebuild_offer_cards_brotato() -> void:
    for child: Node in offers_grid.get_children():
        child.queue_free()
    var current_gold: int = int(_snapshot.get("current_gold", 0))
    for i: int in range(_shop_offers.size()):
        var offer: Dictionary = _shop_offers[i]
        var offer_name: String = _resolve_offer_name(offer)
        var offer_desc: String = _resolve_offer_desc(offer)
        var rarity_key: String = str(offer.get("rarity", "common"))
        var rarity_label: String = _rarity_label(rarity_key)
        var rarity_color: Color = RARITY_COLORS.get(rarity_key, Color.WHITE)
        var is_locked: bool = bool(offer.get("locked", false))
        var sold: bool = bool(offer.get("sold", false))
        var kind: String = str(offer.get("kind", "item"))

        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size = Vector2(224, 260)
        card.pivot_offset = Vector2(112, 130)
        card.add_theme_stylebox_override("panel", _build_offer_card_style_brotato(rarity_key, is_locked, sold))

        var margin: MarginContainer = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 8)
        margin.add_theme_constant_override("margin_top", 8)
        margin.add_theme_constant_override("margin_right", 8)
        margin.add_theme_constant_override("margin_bottom", 8)

        var vb: VBoxContainer = VBoxContainer.new()
        vb.add_theme_constant_override("separation", 6)

        var icon_row: CenterContainer = CenterContainer.new()
        icon_row.add_child(_build_icon_block(_load_offer_icon(offer), OFFER_ICON_SIZE, _tx("ui.shop.no_image", "No Image")))

        var title: Label = Label.new()
        title.text = offer_name
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.add_theme_color_override("font_color", Color(0.94, 0.94, 0.88, 1.0))
        title.add_theme_font_size_override("font_size", 17)

        var subtitle: Label = Label.new()
        subtitle.text = "%s / %s" % [rarity_label, _tx("ui.shop.kind_weapon", "Weapon") if kind == "weapon" else _tx("ui.shop.kind_item", "Item")]
        subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        subtitle.add_theme_color_override("font_color", rarity_color)
        subtitle.add_theme_font_size_override("font_size", 13)

        var desc: Label = Label.new()
        desc.text = offer_desc
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.custom_minimum_size = Vector2(0, 84)
        desc.max_lines_visible = 5
        desc.clip_text = true
        desc.add_theme_font_size_override("font_size", 13)
        desc.add_theme_color_override("font_color", Color(0.86, 0.86, 0.78, 1.0))

        var actions_row: HBoxContainer = HBoxContainer.new()
        actions_row.add_theme_constant_override("separation", 6)
        var lock_button_local: Button = Button.new()
        lock_button_local.custom_minimum_size = Vector2(74, 34)
        lock_button_local.text = _tx("ui.shop.offer_unlock", "解锁") if is_locked else _tx("ui.shop.offer_lock", "锁定")
        lock_button_local.disabled = sold
        lock_button_local.pressed.connect(_on_offer_lock_pressed.bind(str(offer.get("offer_id", ""))))

        var buy_button: Button = Button.new()
        buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        buy_button.text = _tx("ui.shop.sold_out", "Sold Out") if sold else _tf("ui.shop.buy_fmt", [int(offer.get("price", 0))], "Buy - %dG")
        buy_button.disabled = sold or current_gold < int(offer.get("price", 0))
        buy_button.pressed.connect(_on_offer_buy_pressed.bind(str(offer.get("offer_id", ""))))
        var normal_button_style: StyleBoxFlat = _make_brotato_panel_style(Color(0.08, 0.08, 0.08, 1.0), Color(0.16, 0.16, 0.16, 1.0), 1, 5)
        var hover_button_style: StyleBoxFlat = _make_brotato_panel_style(Color(0.13, 0.13, 0.13, 1.0), Color(0.58, 0.58, 0.48, 1.0), 1, 5)
        buy_button.add_theme_stylebox_override("normal", normal_button_style)
        buy_button.add_theme_stylebox_override("hover", hover_button_style)
        lock_button_local.add_theme_stylebox_override("normal", normal_button_style)
        lock_button_local.add_theme_stylebox_override("hover", hover_button_style)
        actions_row.add_child(lock_button_local)
        actions_row.add_child(buy_button)

        var spacer: Control = Control.new()
        spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

        vb.add_child(icon_row)
        vb.add_child(title)
        vb.add_child(subtitle)
        vb.add_child(desc)
        vb.add_child(spacer)
        vb.add_child(actions_row)
        margin.add_child(vb)
        card.add_child(margin)
        card.mouse_entered.connect(_on_weapon_card_hover_start.bind(offer, card))
        card.mouse_exited.connect(_on_weapon_hover_end)
        offers_grid.add_child(card)

func _build_offer_card_style_brotato(rarity: String, locked: bool, sold: bool) -> StyleBoxFlat:
    var rarity_color: Color = RARITY_COLORS.get(rarity.to_lower(), Color("#bdc3c7"))
    var bg: Color = Color(0.015, 0.015, 0.015, 0.96)
    if rarity == "legendary":
        bg = Color(0.09, 0.07, 0.03, 0.98)
    elif rarity == "epic":
        bg = Color(0.06, 0.04, 0.08, 0.98)
    var style: StyleBoxFlat = _make_brotato_panel_style(bg, rarity_color.darkened(0.25), 2, 5)
    if locked:
        style.border_color = Color(0.95, 0.78, 0.18, 1.0)
        style.shadow_color = Color(0.95, 0.78, 0.18, 0.34)
        style.border_width_left = 3
        style.border_width_top = 3
        style.border_width_right = 3
        style.border_width_bottom = 3
    if sold:
        style.bg_color = Color(0.035, 0.035, 0.035, 0.94)
        style.border_color = Color(0.25, 0.25, 0.25, 0.6)
        style.shadow_size = 0
    return style

func _build_neon_style(bg_color: Color, border_color: Color, border_width: int = 2, shadow_size: int = 10) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_left = 6
    style.corner_radius_bottom_right = 6
    style.shadow_color = border_color
    style.shadow_color.a = 0.25
    style.shadow_size = shadow_size
    return style

func _make_brotato_panel_style(bg_color: Color, border_color: Color, border_width: int = 1, radius: int = 4) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
    style.shadow_size = 3
    return style

func _build_offer_card_style(rarity: String, locked: bool, sold: bool) -> StyleBoxFlat:
    var rarity_color: Color = RARITY_COLORS.get(rarity.to_lower(), Color("#bdc3c7"))
    
    # 高级感背景：为高品质道具添加微弱的色彩倾向
    var bg: Color = Color(0.05, 0.07, 0.1, 0.96)
    if rarity == "legendary": bg = Color(0.12, 0.09, 0.05, 0.98)
    elif rarity == "epic": bg = Color(0.09, 0.06, 0.11, 0.98)
    
    var style: StyleBoxFlat = _build_neon_style(
        bg, 
        rarity_color, 
        2, 
        14 if not sold else 0
    )
    
    if locked:
        style.border_color = Color("#f1c40f")
        style.shadow_color = Color("#f1c40f")
        style.shadow_color.a = 0.45
        style.border_width_left = 3 # 锁定状态加粗边框
        style.border_width_top = 3
        style.border_width_right = 3
        style.border_width_bottom = 3
    if sold:
        style.bg_color = Color(0.06, 0.06, 0.06, 0.98)
        style.border_color = Color(0.25, 0.25, 0.25, 0.6)
        style.shadow_size = 0
    
    return style

func _add_vignette_background() -> void:
    var vignette: TextureRect = TextureRect.new()
    vignette.name = "VignetteOverlay"
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    var mat: CanvasItemMaterial = CanvasItemMaterial.new()
    vignette.material = mat
    
    # 使用渐变背景模拟暗角
    var grad: Gradient = Gradient.new()
    grad.set_color(0, Color(0, 0, 0, 0))
    grad.set_color(1, Color(0, 0, 0, 0.45))
    
    var fill: GradientTexture2D = GradientTexture2D.new()
    fill.gradient = grad
    fill.fill = GradientTexture2D.FILL_RADIAL
    fill.fill_from = Vector2(0.5, 0.5)
    fill.fill_to = Vector2(1.0, 1.0)
    
    vignette.texture = fill
    add_child(vignette)
    move_child(vignette, 0) # 放在最底层

func _build_icon_block(texture: Texture2D, icon_size: Vector2, no_image_text: String) -> Control:
    var panel: PanelContainer = PanelContainer.new()
    panel.custom_minimum_size = icon_size + Vector2(8, 8)
    
    var icon_style: StyleBoxFlat = StyleBoxFlat.new()
    icon_style.bg_color = Color(1, 1, 1, 0.04)
    icon_style.border_width_left = 1
    icon_style.border_width_top = 1
    icon_style.border_width_right = 1
    icon_style.border_width_bottom = 1
    icon_style.border_color = Color(0.4, 0.5, 0.6, 0.4)
    icon_style.corner_radius_top_left = 4
    icon_style.corner_radius_top_right = 4
    icon_style.corner_radius_bottom_left = 4
    icon_style.corner_radius_bottom_right = 4
    panel.add_theme_stylebox_override("panel", icon_style)

    var center: CenterContainer = CenterContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.add_child(center)

    if texture != null:
        var texture_rect: TextureRect = TextureRect.new()
        texture_rect.custom_minimum_size = icon_size
        texture_rect.texture = texture
        texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        center.add_child(texture_rect)
    else:
        var placeholder_label: Label = Label.new()
        placeholder_label.text = no_image_text
        placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        placeholder_label.custom_minimum_size = icon_size
        placeholder_label.add_theme_font_size_override("font_size", 12)
        center.add_child(placeholder_label)
    return panel

func _rebuild_attr_panel() -> void:
    var stats: Dictionary = _snapshot.get("player_stats", {})
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var character_id: String = _resolve_snapshot_character_id()
    var base_move_speed: float = _resolve_character_base_move_speed(character_id)
    var current_move_speed: float = float(_snapshot.get("player_move_speed", base_move_speed))
    var extra_move_speed: float = current_move_speed - base_move_speed
    var base_attack_speed_mult: float = _resolve_character_base_attack_speed_mult(character_id)
    var safe_base_attack_speed_mult: float = max(0.01, base_attack_speed_mult)
    var current_attack_speed_mult: float = float(stats.get("attack_speed_mult", safe_base_attack_speed_mult))
    var extra_attack_speed_percent: float = (current_attack_speed_mult / safe_base_attack_speed_mult - 1.0) * 100.0
    var tag_state: Dictionary = {}
    var tag_state_raw: Variant = shop_state.get("weapon_tag_state", {})
    if tag_state_raw is Dictionary:
        tag_state = (tag_state_raw as Dictionary).duplicate(true)
    if tag_state.is_empty() and _shop_system != null:
        tag_state = _shop_system.resolve_weapon_tag_state(shop_state)
    
    var lines: Array[String] = []
    lines.append("[center][b][color=#00f0ff]属性状态[/color][/b][/center]")
    lines.append("") # 留空行增加透气感
    
    lines.append("[table=2]")
    _add_stat_line(lines, "生命上限", int(_snapshot.get("player_max_hp", 100)), "", 0, true)
    _add_stat_line(lines, "生命回复", float(stats.get("hp_regen", 0.0)), "", 0, true)
    _add_stat_line(lines, "攻击加成", float(stats.get("global_attack_percent", 0.0)), "%", 0, true)
    _add_stat_line(lines, "近战加成", int(stats.get("bonus_melee_attack_damage", 0)), "", 0, true)
    _add_stat_line(lines, "远程加成", int(stats.get("bonus_ranged_attack_damage", 0)), "", 0, true)
    _add_stat_line(lines, "幸运值", float(stats.get("luck", 0.0)), "", 0, true)
    _add_stat_line(lines, "收益收获", float(stats.get("harvest", 0.0)), "", 0, true)
    _add_stat_line(lines, "攻击范围", float(_snapshot.get("bonus_target_range", 0.0)), "", 0, true)
    _add_stat_line(lines, "移动速度", extra_move_speed, "", 0, true)
    _add_stat_line(lines, "护甲防御", float(stats.get("armor", 0.0)), "", 0, true)
    _add_stat_line(lines, "闪避概率", (float(stats.get("dodge_chance", 0.0)) * 100.0), "%", 0, true)
    _add_stat_line(lines, "攻击频率", extra_attack_speed_percent, "%", 0, true)
    _add_stat_line(lines, "暴击概率", (float(stats.get("crit_chance", 0.05)) * 100.0), "%", 0, true)
    _add_stat_line(lines, "生命吸取", (float(stats.get("lifesteal", 0.0)) * 100.0), "%", 0, true)
    lines.append("[/table]")
    
    attr_label.text = "\n".join(lines)

func _add_stat_line(lines: Array[String], label: String, val: Variant, unit: String, _base: float, color_logic: bool) -> void:
    var color: String = "#ffffff"
    var f_val: float = float(val)
    if color_logic:
        if f_val > 0.0001: color = "#2ecc71" # 正数绿色
        elif f_val < -0.0001: color = "#e74c3c" # 负数红色
    
    var val_str: String = ""
    if val is float:
        val_str = "%.1f" % val
    else:
        val_str = str(val)
        
    lines.append("[cell][color=#95a5a6]%s:[/color][/cell] [cell][color=%s]%s%s[/color][/cell]" % [label, color, val_str, unit])

func _rebuild_attr_panel_brotato() -> void:
    var stats: Dictionary = _snapshot.get("player_stats", {})
    var character_id: String = _resolve_snapshot_character_id()
    var base_move_speed: float = _resolve_character_base_move_speed(character_id)
    var current_move_speed: float = float(_snapshot.get("player_move_speed", base_move_speed))
    var extra_move_speed: float = current_move_speed - base_move_speed
    var base_attack_speed_mult: float = max(0.01, _resolve_character_base_attack_speed_mult(character_id))
    var current_attack_speed_mult: float = float(stats.get("attack_speed_mult", base_attack_speed_mult))
    var extra_attack_speed_percent: float = (current_attack_speed_mult / base_attack_speed_mult - 1.0) * 100.0

    var lines: Array[String] = []
    lines.append("[center][b][color=#f1f1e8]属性[/color][/b][/center]")
    lines.append("")
    lines.append("[b][color=#d8d8cf]主要[/color][/b]")
    lines.append("[table=2]")
    _add_stat_line(lines, "最大生命值", int(_snapshot.get("player_max_hp", 100)), "", 0, true)
    _add_stat_line(lines, "伤害", float(stats.get("global_attack_percent", 0.0)), "%", 0, true)
    _add_stat_line(lines, "近战伤害", int(stats.get("bonus_melee_attack_damage", 0)), "", 0, true)
    _add_stat_line(lines, "远程伤害", int(stats.get("bonus_ranged_attack_damage", 0)), "", 0, true)
    _add_stat_line(lines, "攻击速度", extra_attack_speed_percent, "%", 0, true)
    _add_stat_line(lines, "范围", float(_snapshot.get("bonus_target_range", 0.0)), "", 0, true)
    lines.append("[/table]")
    lines.append("")
    lines.append("[b][color=#d8d8cf]次要[/color][/b]")
    lines.append("[table=2]")
    _add_stat_line(lines, "生命再生", float(stats.get("hp_regen", 0.0)), "", 0, true)
    _add_stat_line(lines, "护甲", float(stats.get("armor", 0.0)), "", 0, true)
    _add_stat_line(lines, "闪避", float(stats.get("dodge_chance", 0.0)) * 100.0, "%", 0, true)
    _add_stat_line(lines, "暴击率", float(stats.get("crit_chance", 0.05)) * 100.0, "%", 0, true)
    _add_stat_line(lines, "生命窃取", float(stats.get("lifesteal", 0.0)) * 100.0, "%", 0, true)
    _add_stat_line(lines, "速度", extra_move_speed, "", 0, true)
    _add_stat_line(lines, "幸运", float(stats.get("luck", 0.0)), "", 0, true)
    _add_stat_line(lines, "收获", float(stats.get("harvest", 0.0)), "", 0, true)
    lines.append("[/table]")
    attr_label.text = "\n".join(lines)

func _resolve_snapshot_character_id() -> String:
    var character_id: String = str(_snapshot.get("selected_character", ""))
    if character_id.is_empty():
        character_id = GameManager.selected_character
    if character_id.is_empty():
        character_id = "the_fool"
    return character_id

func _resolve_character_base_move_speed(character_id: String) -> float:
    var profile: Dictionary = BalanceService.get_character_profile(character_id)
    return float(profile.get("move_speed", 220.0))

func _resolve_character_base_attack_speed_mult(character_id: String) -> float:
    var profile: Dictionary = BalanceService.get_character_profile(character_id)
    return float(profile.get("attack_speed_mult", 1.0))

func _refresh_weapon_tag_state_snapshot() -> void:
    if _shop_system == null:
        return
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    if not (state is Dictionary):
        state = {}
    state["weapon_tag_state"] = _shop_system.resolve_weapon_tag_state(state)
    _snapshot["shop_runtime_state"] = state

func _append_weapon_tag_lines(lines: Array[String], tag_state: Dictionary) -> void:
    lines.append("")
    lines.append(_tx("ui.shop.weapon_tag_bonus_title_bb", "[b]Weapon Tag Bonuses[/b]"))

    if tag_state.is_empty():
        lines.append(_tx("ui.shop.weapon_tag_empty", "No active weapon tags"))
        return

    var enabled: bool = bool(tag_state.get("enabled", false))
    var max_stack: int = max(1, int(tag_state.get("max_stack_per_tag", WEAPON_SLOT_COUNT)))
    var counts_raw: Variant = tag_state.get("counts", {})
    if not (counts_raw is Dictionary) or (counts_raw as Dictionary).is_empty():
        lines.append(_tx("ui.shop.weapon_tag_empty", "No active weapon tags"))
        return

    var counts: Dictionary = counts_raw
    var active_tiers: Dictionary = {}
    var active_tiers_raw: Variant = tag_state.get("active_tiers", {})
    if active_tiers_raw is Dictionary:
        active_tiers = active_tiers_raw
    var next_tiers: Dictionary = {}
    var next_tiers_raw: Variant = tag_state.get("next_tiers", {})
    if next_tiers_raw is Dictionary:
        next_tiers = next_tiers_raw
    var tag_meta: Dictionary = {}
    var tag_meta_raw: Variant = tag_state.get("tag_meta", {})
    if tag_meta_raw is Dictionary:
        tag_meta = tag_meta_raw

    var tag_keys: Array = counts.keys()
    tag_keys.sort()
    for tag_key_raw: Variant in tag_keys:
        var tag_key: String = str(tag_key_raw)
        var count: int = int(counts.get(tag_key, 0))
        var active_tier: int = int(active_tiers.get(tag_key, 0))
        var next_tier: int = int(next_tiers.get(tag_key, 0))
        var tag_name: String = tag_key
        var meta_value: Variant = tag_meta.get(tag_key, {})
        if meta_value is Dictionary:
            var meta_dict: Dictionary = meta_value
            var display_name: String = str(meta_dict.get("name", ""))
            if not display_name.is_empty():
                tag_name = display_name
        lines.append(_format_weapon_tag_line(tag_name, count, max_stack, active_tier, next_tier))

    if not enabled:
        lines.append(_tx("ui.shop.weapon_tag_preview_hint", "(Rules disabled; showing tier preview only)"))

func _format_weapon_tag_line(tag_name: String, count: int, max_stack: int, active_tier: int, next_tier: int) -> String:
    var line: String = "- %s %d/%d" % [tag_name, count, max_stack]
    if active_tier > 0:
        line += "  " + _tf("ui.shop.weapon_tag_active_tier_fmt", [active_tier], "Active T%d")
    if next_tier > 0:
        line += "  " + _tf("ui.shop.weapon_tag_next_tier_fmt", [next_tier], "Next T%d")
    else:
        line += "  " + _tx("ui.shop.weapon_tag_capped", "Capped")
    return line

func _rebuild_owned_items_grid() -> void:
    if _owned_items_grid == null or _owned_items_title_label == null:
        return
    for child: Node in _owned_items_grid.get_children():
        child.queue_free()
    _owned_items_title_label.text = _tx("ui.shop.owned_items_title", "Items")
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var owned_items: Array[Dictionary] = _normalize_owned_items(state.get("owned_items", []))
    if owned_items.is_empty():
        var empty_label: Label = Label.new()
        empty_label.text = _tx("ui.shop.owned_items_empty", "No Items")
        _owned_items_grid.add_child(empty_label)
        return

    for row: Dictionary in owned_items:
        var item_id: String = str(row.get("item_id", ""))
        var count: int = max(1, int(row.get("count", 1)))
        var icon_path: String = str(row.get("icon_path", ""))
        if icon_path.is_empty():
            icon_path = _resolve_item_icon_path(item_id)
        var texture: Texture2D = _load_texture_cached(icon_path, _item_icon_cache)

        var cell: VBoxContainer = VBoxContainer.new()
        cell.custom_minimum_size = Vector2(64, 94)
        cell.add_theme_constant_override("separation", 4)
        var item_name: String = LocaleService.t_data("item", item_id, "name", item_id)
        cell.tooltip_text = item_name

        var icon_block: Control = _build_icon_block(texture, GRID_ICON_SIZE, _tx("ui.shop.no_image", "No Image"))
        var count_label: Label = Label.new()
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        count_label.text = _tf("ui.shop.owned_item_count_fmt", [count], "x%d")

        cell.add_child(icon_block)
        cell.add_child(count_label)
        _owned_items_grid.add_child(cell)

func _rebuild_weapon_slots_grid() -> void:
    if _equipped_weapons_grid == null or _equipped_weapons_title_label == null:
        return
    for child: Node in _equipped_weapons_grid.get_children():
        child.queue_free()
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var slots: Array = _normalize_weapon_slots(shop_state.get("equipped_weapons", []))
    var filled_count: int = 0
    for slot_value: Variant in slots:
        if slot_value is Dictionary and not str((slot_value as Dictionary).get("weapon_id", "")).is_empty():
            filled_count += 1
    _equipped_weapons_title_label.text = _tf(
        "ui.shop.equipped_weapons_title_fmt",
        [filled_count, WEAPON_SLOT_COUNT],
        "Weapons (%d/%d)"
    )

    for i: int in range(slots.size()):
        var slot_weapon: Variant = slots[i]
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(68, 68)
        button.focus_mode = Control.FOCUS_NONE
        button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 46)
        
        # 移除 disabled 状态，防止图标变暗蒙层
        button.disabled = false 
        
        var has_weapon: bool = slot_weapon is Dictionary and not str((slot_weapon as Dictionary).get("weapon_id", "")).is_empty()
        var rarity_key: String = "common"
        if has_weapon:
            var weapon: Dictionary = slot_weapon
            rarity_key = str(weapon.get("rarity", "common"))
            var weapon_id: String = str(weapon.get("weapon_id", "weapon"))
            var weapon_name: String = LocaleService.t_data("weapon", weapon_id, "name", weapon_id)
            button.tooltip_text = ""
            var icon_path: String = _resolve_weapon_icon_path(weapon_id)
            var icon: Texture2D = _load_texture_cached(icon_path, _weapon_icon_cache)
            if icon != null:
                button.icon = icon
                button.text = ""
            else:
                button.text = _tx("ui.shop.no_image", "No Image")
        else:
            button.tooltip_text = ""
            button.text = "" # 空位保持简洁

        # 为已装备武器添加品质边框风格
        var style: StyleBoxFlat = _build_offer_card_style(rarity_key, false, false)
        # 稍微调暗背景色，以区分于待购商品
        style.bg_color = Color(0.05, 0.07, 0.1, 0.9)
        if i == _selected_weapon_slot_index and has_weapon:
            style.border_color = Color(0.95, 0.78, 0.18, 1.0)
            style.border_width_left = 3
            style.border_width_top = 3
            style.border_width_right = 3
            style.border_width_bottom = 3
        button.add_theme_stylebox_override("normal", style)
        button.add_theme_stylebox_override("hover", style)
        button.add_theme_stylebox_override("pressed", style)
        button.add_theme_stylebox_override("disabled", style)
        
        if has_weapon:
            button.mouse_entered.connect(_on_weapon_card_hover_start.bind(slot_weapon, button))
            button.mouse_exited.connect(_on_weapon_hover_end)

        # 如果处于替换模式，增加一个闪烁或者明显的提示（此处先让其可点击）
        if not _pending_replace_offer_id.is_empty():
            var highlight: StyleBoxFlat = style.duplicate()
            highlight.border_color = Color.WHITE
            button.add_theme_stylebox_override("normal", highlight)

        button.pressed.connect(_on_weapon_slot_pressed.bind(i))
        _equipped_weapons_grid.add_child(button)
    _refresh_weapon_action_panel(slots)

func _refresh_weapon_action_panel(slots: Array) -> void:
    if _weapon_action_panel == null:
        return
    if _selected_weapon_slot_index < 0 or _selected_weapon_slot_index >= slots.size():
        _weapon_action_panel.visible = false
        return
    var slot_value: Variant = slots[_selected_weapon_slot_index]
    if not (slot_value is Dictionary) or str((slot_value as Dictionary).get("weapon_id", "")).is_empty():
        _selected_weapon_slot_index = -1
        _weapon_action_panel.visible = false
        return
    var weapon: Dictionary = slot_value
    var weapon_id: String = str(weapon.get("weapon_id", "weapon"))
    var weapon_name: String = LocaleService.t_data("weapon", weapon_id, "name", weapon_id)
    var rarity: String = str(weapon.get("rarity", "common"))
    var rarity_label: String = _rarity_label(rarity)
    var can_combine: bool = _find_merge_partner_for_slot(slots, _selected_weapon_slot_index) >= 0
    var recycle_value: int = max(1, int(weapon.get("recycle_value", _estimate_weapon_recycle_value_ui(weapon))))
    var icon: Texture2D = _load_texture_cached(_resolve_weapon_icon_path(weapon_id), _weapon_icon_cache)

    _weapon_action_panel.visible = true
    _position_weapon_action_panel()
    _weapon_action_icon.texture = icon
    _weapon_action_title.text = "%d. %s" % [_selected_weapon_slot_index + 1, weapon_name]
    _weapon_action_subtitle.text = "%s / %s" % [rarity_label, _tx("ui.shop.kind_weapon", "武器")]
    _weapon_action_subtitle.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color(0.82, 0.78, 0.62, 1.0)))
    _weapon_action_detail.text = _build_weapon_action_detail(weapon)
    _weapon_action_tags.text = _build_weapon_action_tags(weapon)
    _weapon_combine_button.disabled = not can_combine
    _weapon_recycle_button.text = _tf("ui.shop.recycle_fmt", [recycle_value], "Recycle +%dG")
    _weapon_cancel_button.text = _tx("ui.common.cancel", "Cancel")

func _position_weapon_action_panel() -> void:
    if _weapon_action_panel == null:
        return
    var panel_size: Vector2 = _weapon_action_panel.custom_minimum_size
    _weapon_action_panel.size = panel_size
    var viewport_size: Vector2 = get_viewport_rect().size
    var anchor_rect: Rect2 = Rect2(Vector2.ZERO, viewport_size)
    if _equipped_weapons_grid != null:
        anchor_rect = _equipped_weapons_grid.get_global_rect()
    elif bottom_panel != null:
        anchor_rect = bottom_panel.get_global_rect()

    var target_x: float = anchor_rect.position.x + (anchor_rect.size.x - panel_size.x) * 0.5
    var target_y: float = anchor_rect.position.y - panel_size.y - 10.0
    if target_y < 56.0:
        target_y = anchor_rect.position.y + 10.0
    target_x = clampf(target_x, 10.0, max(10.0, viewport_size.x - panel_size.x - 10.0))
    target_y = clampf(target_y, 56.0, max(56.0, viewport_size.y - panel_size.y - 10.0))
    _weapon_action_panel.global_position = Vector2(target_x, target_y)
    _weapon_action_panel.move_to_front()

func _build_weapon_action_detail(weapon: Dictionary) -> String:
    var profile: Dictionary = weapon.get("attack_profile", {})
    var parts: Array[String] = []
    if not profile.is_empty():
        parts.append("[color=#f1f1e8]伤害:[/color] %s" % str(profile.get("base_damage", "-")))
        parts.append("[color=#f1f1e8]冷却:[/color] %.2fs" % float(profile.get("interval", 0.0)))
        parts.append("[color=#f1f1e8]范围:[/color] %s" % str(profile.get("range", "-")))
        if profile.has("crit_chance"):
            parts.append("[color=#f1f1e8]暴击:[/color] %.0f%%" % (float(profile.get("crit_chance", 0.0)) * 100.0))
    var effects: Dictionary = weapon.get("effects", {})
    for key: Variant in effects.keys():
        if parts.size() >= 5:
            break
        var key_text: String = str(key)
        if key_text.begins_with("bonus_"):
            continue
        var value: Variant = effects[key]
        if value is int or value is float:
            var numeric_value: float = float(value)
            if is_zero_approx(numeric_value):
                continue
            var sign: String = "+" if numeric_value >= 0.0 else ""
            parts.append("[color=#f1f1e8]%s:[/color] %s%.1f" % [key_text, sign, numeric_value])
    var stat_text: String = "[color=#aeb6b8]暂无武器属性[/color]"
    if not parts.is_empty():
        stat_text = "\n".join(parts)
    return "[font_size=18]%s[/font_size]" % stat_text

func _build_weapon_action_tags(weapon: Dictionary) -> String:
    var tags: Array = _extract_offer_tags(weapon)
    if tags.is_empty():
        tags = weapon.get("tags", []) if weapon.get("tags", []) is Array else []
    var catalog: Dictionary = BalanceService.get_shop_catalog()
    var tag_rules: Dictionary = catalog.get("weapon_tag_bonus_rules", {})
    var tag_defs: Dictionary = tag_rules.get("tag_defs", {})
    var tier_steps: Array = tag_rules.get("tier_steps", [2, 3, 4, 5, 6])
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var tag_state: Dictionary = _shop_system.resolve_weapon_tag_state(shop_state)
    var counts: Dictionary = tag_state.get("counts", {})

    var lines: Array[String] = []
    if tags.is_empty():
        return "[center][b][color=#f1f1e8]标签[/color][/b][/center]\n[color=#7f8c8d]无标签[/color]"

    for tag_value: Variant in tags:
        var tag_id: String = str(tag_value)
        if tag_id.is_empty():
            continue
        var tag_name: String = tag_id
        var tiers_data: Dictionary = {}
        var tag_def_raw: Variant = tag_defs.get(tag_id, {})
        if tag_def_raw is Dictionary:
            var tag_def: Dictionary = tag_def_raw
            tag_name = str(tag_def.get("name", tag_id))
            tiers_data = tag_def.get("tiers", {})
        var current_count: int = int(counts.get(tag_id, 0))
        if not lines.is_empty():
            lines.append("")
        lines.append("[font_size=15][b][color=#00f0ff]%s (%d)[/color][/b][/font_size]" % [tag_name, current_count])
        lines.append("[font_size=9][color=#1f6f78]────────────[/color][/font_size]")
        for step_idx: int in range(tier_steps.size()):
            var step_count: int = int(tier_steps[step_idx])
            var step_tier: int = step_idx + 1
            var tier_info: Dictionary = tiers_data.get(str(step_tier), {})
            var bonus_text: String = str(tier_info.get("note", "Bonus T%d" % step_tier))
            bonus_text = _tx("ui.tag.%s.tier%d" % [tag_id, step_tier], bonus_text)
            var line_color: String = "#f1f1e8" if current_count >= step_count else "#6f7678"
            lines.append("[font_size=13][color=%s](%d) %s[/color][/font_size]" % [line_color, step_count, bonus_text])
    return "\n".join(lines)

func _find_merge_partner_for_slot(slots: Array, source_index: int) -> int:
    if source_index < 0 or source_index >= slots.size():
        return -1
    var source_value: Variant = slots[source_index]
    if not (source_value is Dictionary):
        return -1
    var source: Dictionary = source_value
    var source_stack: String = str(source.get("stack_key", source.get("weapon_id", "")))
    var source_rarity: String = str(source.get("rarity", "common"))
    if source_stack.is_empty() or source_rarity == "legendary":
        return -1
    for i: int in range(slots.size()):
        if i == source_index:
            continue
        var other_value: Variant = slots[i]
        if not (other_value is Dictionary):
            continue
        var other: Dictionary = other_value
        if str(other.get("weapon_id", "")).is_empty():
            continue
        if str(other.get("stack_key", other.get("weapon_id", ""))) == source_stack and str(other.get("rarity", "common")) == source_rarity:
            return i
    return -1

func _estimate_weapon_recycle_value_ui(weapon: Dictionary) -> int:
    var acquired_price: int = int(weapon.get("acquired_price", 0))
    if acquired_price <= 0:
        acquired_price = int(weapon.get("base_price", 35))
    return max(1, int(round(float(acquired_price) * 0.25)))

func _rebuild_elite_hint() -> void:
    if _elite_hint_label == null:
        return
    var start_stage_id: String = str(_snapshot.get("stage_id", GameManager.current_stage_id))
    var elite_info: Dictionary = _find_nearest_future_elite_stage(start_stage_id)
    if elite_info.is_empty():
        _elite_hint_label.text = ""
        _elite_hint_label.visible = false
        return
    var stage_no: int = int(elite_info.get("stage_no", 0))
    if stage_no <= 0:
        _elite_hint_label.text = ""
        _elite_hint_label.visible = false
        return
    _elite_hint_label.visible = true
    _elite_hint_label.text = _tf(
        "ui.shop.elite_hint_fmt",
        [stage_no],
        "⚠ An elite enemy will appear in stage %d!"
    )

func _find_nearest_future_elite_stage(start_stage_id: String) -> Dictionary:
    var start_stage_no: int = _extract_stage_number(start_stage_id)
    if start_stage_no <= 0:
        return {}
    # User requested: only warn if elite appears in the immediate next stage.
    for stage_no: int in range(start_stage_no, start_stage_no + 1):
        var stage_id: String = "stage_%03d" % stage_no
        if not BalanceService.has_stage_profile(stage_id):
            continue
        var stage_profile: Dictionary = BalanceService.get_stage_profile(stage_id)
        var elite_schedule_value: Variant = stage_profile.get("elite_schedule", {})
        if not (elite_schedule_value is Dictionary):
            continue
        var elite_schedule: Dictionary = elite_schedule_value
        if bool(elite_schedule.get("enabled", false)):
            return {
                "stage_id": stage_id,
                "stage_no": stage_no,
            }
    return {}

func _extract_stage_number(stage_id: String) -> int:
    if not stage_id.begins_with("stage_"):
        return 0
    var suffix: String = stage_id.substr(6)
    if suffix.is_empty():
        return 0
    return max(0, int(suffix))

func _resolve_offer_name(offer: Dictionary) -> String:
    var kind: String = str(offer.get("kind", "item"))
    if kind == "weapon":
        var weapon_id: String = _extract_offer_weapon_id(offer)
        return LocaleService.t_data("weapon", weapon_id, "name", str(offer.get("name", "Weapon")))
    var item_id: String = str(offer.get("item_id", ""))
    return LocaleService.t_data("item", item_id, "name", str(offer.get("name", "Item")))

func _resolve_offer_desc(offer: Dictionary) -> String:
    var kind: String = str(offer.get("kind", "item"))
    var base_desc: String = ""
    if kind == "weapon":
        var weapon_id: String = _extract_offer_weapon_id(offer)
        base_desc = LocaleService.t_data("weapon", weapon_id, "desc", str(offer.get("description", "")))
        
        # 动态生成武器数值描述 (类似土豆兄弟)
        var weapon_data: Dictionary = offer.get("weapon", {})
        var profile: Dictionary = weapon_data.get("attack_profile", {})
        if not profile.is_empty():
            var dmg: float = float(profile.get("base_damage", 0.0))
            var interval: float = float(profile.get("interval", 1.0))
            var w_range: float = float(profile.get("range", 0.0))
            var stats_line: String = "\n伤害:%d 频率:%.2fs 范围:%d" % [dmg, interval, w_range]
            base_desc += stats_line
    else:
        var item_id: String = str(offer.get("item_id", ""))
        base_desc = LocaleService.t_data("item", item_id, "desc", str(offer.get("description", "")))
        
        # 如果描述依然为空，则自动列出效果
        if base_desc.is_empty():
            var effects: Dictionary = offer.get("effects", {})
            var parts: Array[String] = []
            for key in effects.keys():
                parts.append("%s: %s" % [key, str(effects[key])])
            base_desc = ", ".join(parts)
            
    return base_desc

func _load_offer_icon(offer: Dictionary) -> Texture2D:
    var icon_path: String = str(offer.get("icon_path", ""))
    if icon_path.is_empty():
        icon_path = _resolve_offer_icon_path(offer)
    return _load_texture_cached(icon_path, _offer_icon_cache)

func _resolve_offer_icon_path(offer: Dictionary) -> String:
    var explicit_path: String = str(offer.get("icon_path", ""))
    if not explicit_path.is_empty():
        return explicit_path
    var kind: String = str(offer.get("kind", "item"))
    if kind == "weapon":
        var weapon_id: String = _extract_offer_weapon_id(offer)
        return _resolve_weapon_icon_path(weapon_id)
    var item_id: String = str(offer.get("item_id", ""))
    return _resolve_item_icon_path(item_id)

func _resolve_weapon_icon_path(weapon_id: String) -> String:
    if weapon_id.is_empty():
        return ""
    return "%s%s.png" % [WEAPON_ICON_DIR, weapon_id]

func _resolve_item_icon_path(item_id: String) -> String:
    if item_id.is_empty():
        return ""
    return "%s%s.png" % [ITEM_ICON_DIR, item_id]

func _extract_offer_weapon_id(offer: Dictionary) -> String:
    var weapon_id: String = str(offer.get("weapon_id", ""))
    if not weapon_id.is_empty():
        return weapon_id
    var weapon_value: Variant = offer.get("weapon", {})
    if weapon_value is Dictionary:
        return str((weapon_value as Dictionary).get("weapon_id", ""))
    return ""

func _load_texture_cached(path: String, cache: Dictionary) -> Texture2D:
    if path.is_empty():
        return null
    if cache.has(path):
        var cached: Variant = cache[path]
        return cached as Texture2D if cached is Texture2D else null
    if not ResourceLoader.exists(path):
        cache[path] = null
        return null
    var texture: Texture2D = load(path) as Texture2D
    cache[path] = texture
    return texture

func _rarity_label(rarity_raw: String) -> String:
    var rarity: String = rarity_raw.to_lower()
    return _tx("ui.common.rarity.%s" % rarity, rarity.to_upper())

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

# --- Tag Tooltip Logic ---

func _create_tag_tooltip_layer() -> void:
    _tag_tooltip_container = Control.new()
    _tag_tooltip_container.name = "TagTooltipContainer"
    _tag_tooltip_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_tag_tooltip_container)

func _on_weapon_card_hover_start(offer_or_weapon: Dictionary, anchor: Control) -> void:
    _on_weapon_hover_end() # 清除旧的
    
    var tags: Array = _extract_offer_tags(offer_or_weapon)
    if tags.is_empty():
        return
        
    _is_hovering_weapon = true
    if _tag_tooltip_container:
        _tag_tooltip_container.move_to_front() # 确保在最上层
    _spawn_tag_tooltips(tags, anchor)

func _on_weapon_hover_end() -> void:
    _is_hovering_weapon = false
    if _tag_tooltip_container:
        for child in _tag_tooltip_container.get_children():
            child.queue_free()

func _extract_offer_tags(offer_or_weapon: Dictionary) -> Array:
    var tags: Array = []
    # 如果是 offer (包含武器字典)
    if offer_or_weapon.has("weapon"):
        var w_data = offer_or_weapon.get("weapon", {})
        if w_data is Dictionary:
            tags = (w_data as Dictionary).get("build_tags", [])
    # 如果是直接的 weapon 字典
    elif offer_or_weapon.has("build_tags"):
        tags = offer_or_weapon.get("build_tags", [])
    return tags

func _spawn_tag_tooltips(tag_ids: Array, anchor: Control) -> void:
    var catalog: Dictionary = BalanceService.get_shop_catalog()
    var tag_rules: Dictionary = catalog.get("weapon_tag_bonus_rules", {})
    var tag_defs: Dictionary = tag_rules.get("tag_defs", {})
    var tier_steps: Array = tag_rules.get("tier_steps", [2, 3, 4, 5, 6])
    
    # 获取当前的羁绊状态以显示进度
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var tag_state: Dictionary = _shop_system.resolve_weapon_tag_state(shop_state)
    var counts: Dictionary = tag_state.get("counts", {})
    var screen_size: Vector2 = get_viewport_rect().size
    var tooltip_w: float = 240.0
    var spacing: float = 10.0
    
    # 智能定位：优先右侧，如果右侧出界则显示在左侧
    var anchor_pos: Vector2 = anchor.get_screen_position()
    var target_x: float = anchor_pos.x + anchor.size.x + spacing
    if target_x + tooltip_w > screen_size.x - 20:
        target_x = anchor_pos.x - tooltip_w - spacing
    
    var start_y: float = anchor_pos.y
    
    for i in range(tag_ids.size()):
        var tag_id: String = tag_ids[i]
        var tag_def: Dictionary = tag_defs.get(tag_id, {})
        var tag_name: String = tag_def.get("name", tag_id)
        
        var panel: PanelContainer = PanelContainer.new()
        panel.custom_minimum_size = Vector2(240, 0)
        # 使用霓虹风格
        panel.add_theme_stylebox_override("panel", _build_neon_style(Color(0.08, 0.1, 0.12, 0.96), Color(0.0, 0.94, 1.0, 0.6), 1, 6))
        _tag_tooltip_container.add_child(panel)
        
        # 垂直堆叠定位，并防止底部出界
        var panel_y: float = start_y + (i * 145)
        # 如果整组太长，整体向上偏移
        var total_height_needed: float = tag_ids.size() * 145
        if start_y + total_height_needed > screen_size.y - 20:
             panel_y -= (start_y + total_height_needed - (screen_size.y - 20))
        
        panel.global_position = Vector2(target_x, max(10, panel_y))
        
        var margin: MarginContainer = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 14)
        margin.add_theme_constant_override("margin_top", 12)
        margin.add_theme_constant_override("margin_right", 14)
        margin.add_theme_constant_override("margin_bottom", 12)
        panel.add_child(margin)
        
        var vb: VBoxContainer = VBoxContainer.new()
        vb.add_theme_constant_override("separation", 6)
        margin.add_child(vb)
        
        # 标题：标签名 + 当前拥有数量
        var title_lbl: Label = Label.new()
        var current_count: int = int(counts.get(tag_id, 0))
        title_lbl.text = "%s (%d)" % [tag_name, current_count]
        title_lbl.add_theme_color_override("font_color", Color("#00f0ff"))
        title_lbl.add_theme_font_size_override("font_size", 18)
        vb.add_child(title_lbl)
        
        # 分割线
        var separator: ColorRect = ColorRect.new()
        separator.custom_minimum_size = Vector2(0, 1)
        separator.color = Color(0.0, 0.94, 1.0, 0.3)
        vb.add_child(separator)
        
        # 奖励进度列表
        var tiers_data: Dictionary = tag_def.get("tiers", {})
        for step_idx in range(tier_steps.size()):
            var step_count: int = int(tier_steps[step_idx])
            var step_tier: int = step_idx + 1
            var tier_info: Dictionary = tiers_data.get(str(step_tier), {})
            
            var tier_lbl: Label = Label.new()
            var is_active: bool = current_count >= step_count
            
            var bonus_text: String = tier_info.get("note", "Bonus T%d" % step_tier)
            # 翻译（如果可用）
            bonus_text = _tx("ui.tag.%s.tier%d" % [tag_id, step_tier], bonus_text)
            
            tier_lbl.text = "(%d) %s" % [step_count, bonus_text]
            if is_active:
                tier_lbl.add_theme_color_override("font_color", Color.WHITE)
            else:
                tier_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
            
            tier_lbl.add_theme_font_size_override("font_size", 14)
            vb.add_child(tier_lbl)

func _resolve_next_stage_id(current_stage_id: String) -> String:
    if current_stage_id.is_empty():
        return ""
    var stage_profile: Dictionary = BalanceService.get_stage_profile(current_stage_id)
    var config_next_stage: String = str(stage_profile.get("next_stage_id", ""))
    if not config_next_stage.is_empty() and BalanceService.has_stage_profile(config_next_stage):
        return config_next_stage

    if not current_stage_id.begins_with("stage_"):
        return ""
    var suffix: String = current_stage_id.substr(6)
    if suffix.is_empty():
        return ""
    var stage_no: int = int(suffix)
    if stage_no <= 0:
        return ""
    var inferred_next_stage_id: String = "stage_%03d" % (stage_no + 1)
    if BalanceService.has_stage_profile(inferred_next_stage_id):
        return inferred_next_stage_id
    return ""
