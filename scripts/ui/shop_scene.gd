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

func _open_pause_menu() -> void:
    if _is_scene_transition_pending():
        return
    _pause_opened = true
    _hide_pause_sub_panels()
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
    if _pause_panel != null:
        _pause_panel.visible = false

func _show_settings_panel() -> void:
    if _settings_panel == null:
        return
    if _slot_panel != null:
        _slot_panel.visible = false
    _settings_panel.visible = true
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
    var shop_rules: Dictionary = BalanceService.get_shop_catalog().get("shop_rules", {})
    var state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var refresh_count: int = int(state.get("refresh_count", 0))
    var refresh_price: int = int(shop_rules.get("refresh_base_cost", 20)) + int(shop_rules.get("refresh_cost_step", 10)) * refresh_count
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
    _snapshot["shop_offers"] = _shop_offers.duplicate(true)
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
    if sync_snapshot_offers:
        _snapshot["shop_offers"] = _shop_offers.duplicate(true)

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
    var locked_slots: Dictionary = {}
    for locked_offer: Dictionary in locked_source:
        if bool(locked_offer.get("sold", false)):
            continue
        locked_slots[int(locked_offer.get("slot_index", -1))] = true

    var result: Array[Dictionary] = []
    for i: int in range(offers.size()):
        var offer: Dictionary = offers[i].duplicate(true)
        var slot_index: int = int(offer.get("slot_index", i))
        offer["slot_index"] = slot_index
        offer["locked"] = bool(locked_slots.get(slot_index, false)) and not bool(offer.get("sold", false))
        if str(offer.get("icon_path", "")).is_empty():
            offer["icon_path"] = _resolve_offer_icon_path(offer)
        result.append(offer)
    return result

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

func _rebuild_ui() -> void:
    _apply_responsive_layout(get_viewport_rect().size)
    gold_label.text = _tf("ui.shop.gold_fmt", [int(_snapshot.get("current_gold", 0))], "Gold: %d")
    wave_label.text = _tf("ui.shop.wave_fmt", [str(_snapshot.get("stage_id", GameManager.current_stage_id))], "Stage %s Shop")
    var shop_state: Dictionary = _snapshot.get("shop_runtime_state", {})
    var refresh_count: int = int(shop_state.get("refresh_count", 0))
    var shop_rules: Dictionary = BalanceService.get_shop_catalog().get("shop_rules", {})
    var refresh_price: int = int(shop_rules.get("refresh_base_cost", 20)) + int(shop_rules.get("refresh_cost_step", 10)) * refresh_count
    refresh_button.text = _tf("ui.shop.refresh_fmt", [refresh_price], "Refresh (%dG)")
    if lock_button != null:
        lock_button.visible = false
    next_wave_button.text = _tx("ui.shop.next_stage", "Start Next Stage")
    next_wave_button.disabled = false
    _rebuild_offer_cards()
    _rebuild_attr_panel()
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
        bottom_panel.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.34, 208.0, 320.0))
    if mid_row != null:
        mid_row.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.36, 220.0, 360.0))
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
        var rarity_label: String = _rarity_label(str(offer.get("rarity", "common")))
        var is_locked: bool = bool(offer.get("locked", false))
        var sold: bool = bool(offer.get("sold", false))

        var card: PanelContainer = PanelContainer.new()
        card.custom_minimum_size = Vector2(210, 198)
        card.add_theme_stylebox_override("panel", _build_offer_card_style(is_locked, sold))

        var margin: MarginContainer = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 6)
        margin.add_theme_constant_override("margin_top", 6)
        margin.add_theme_constant_override("margin_right", 6)
        margin.add_theme_constant_override("margin_bottom", 6)

        var vb: VBoxContainer = VBoxContainer.new()
        vb.add_theme_constant_override("separation", 4)

        var title: Label = Label.new()
        title.text = _tf("ui.shop.offer_title_fmt", [offer_name, rarity_label], "%s [%s]")
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

        var icon_texture: Texture2D = _load_offer_icon(offer)
        var icon_block: Control = _build_icon_block(icon_texture, OFFER_ICON_SIZE, _tx("ui.shop.no_image", "No Image"))

        var desc: Label = Label.new()
        desc.text = offer_desc
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.max_lines_visible = 2
        desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        desc.clip_text = true

        var actions_row: HBoxContainer = HBoxContainer.new()
        actions_row.add_theme_constant_override("separation", 4)

        var lock_button_local: Button = Button.new()
        lock_button_local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        lock_button_local.text = _tx("ui.shop.offer_unlock", "Unlock") if is_locked else _tx("ui.shop.offer_lock", "Lock")
        lock_button_local.disabled = sold
        lock_button_local.pressed.connect(_on_offer_lock_pressed.bind(str(offer.get("offer_id", ""))))

        var buy_button: Button = Button.new()
        buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        buy_button.text = _tx("ui.shop.sold_out", "Sold Out") if sold else _tf("ui.shop.buy_fmt", [int(offer.get("price", 0))], "Buy - %dG")
        buy_button.disabled = sold or current_gold < int(offer.get("price", 0))
        buy_button.pressed.connect(_on_offer_buy_pressed.bind(str(offer.get("offer_id", ""))))

        actions_row.add_child(lock_button_local)
        actions_row.add_child(buy_button)

        vb.add_child(title)
        vb.add_child(icon_block)
        vb.add_child(desc)
        vb.add_child(actions_row)

        margin.add_child(vb)
        card.add_child(margin)
        offers_grid.add_child(card)

func _build_offer_card_style(locked: bool, sold: bool) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.07, 0.1, 0.14, 0.95)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.18, 0.42, 0.58, 0.95)
    if locked:
        style.border_color = Color(0.95, 0.82, 0.32, 1.0)
    if sold:
        style.bg_color = Color(0.08, 0.08, 0.08, 0.96)
        style.border_color = Color(0.3, 0.3, 0.3, 0.95)
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_left = 6
    style.corner_radius_bottom_right = 6
    return style

func _build_icon_block(texture: Texture2D, icon_size: Vector2, no_image_text: String) -> Control:
    var panel: PanelContainer = PanelContainer.new()
    panel.custom_minimum_size = icon_size + Vector2(8, 8)

    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.07, 0.1, 0.92)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.45, 0.55, 0.65, 0.9)
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    panel.add_theme_stylebox_override("panel", style)

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
    lines.append(_tx("ui.shop.stats_title_bb", "[b]Stats[/b]"))
    lines.append(_tf("ui.shop.stat_max_hp", [int(_snapshot.get("player_max_hp", 100))], "Max HP: %d"))
    lines.append(_tf("ui.shop.stat_hp_regen", [float(stats.get("hp_regen", 0.0))], "HP Regen: %.1f"))
    lines.append(_tf("ui.shop.stat_global_atk_percent", [float(stats.get("global_attack_percent", 0.0))], "Global ATK: %.1f%%"))
    lines.append(_tf("ui.shop.stat_melee_bonus", [int(stats.get("bonus_melee_attack_damage", 0))], "Melee ATK+: %d"))
    lines.append(_tf("ui.shop.stat_ranged_bonus", [int(stats.get("bonus_ranged_attack_damage", 0))], "Ranged ATK+: %d"))
    lines.append(_tf("ui.shop.stat_luck", [float(stats.get("luck", 0.0))], "Luck: %.1f"))
    lines.append(_tf("ui.shop.stat_harvest", [float(stats.get("harvest", 0.0))], "Harvest: %.1f"))
    lines.append(_tf("ui.shop.stat_range_bonus", [float(_snapshot.get("bonus_target_range", 0.0))], "Attack Range: %.0f"))
    lines.append(_tf("ui.shop.stat_extra_move_speed", [extra_move_speed], "Bonus Move Speed: %+.0f"))
    lines.append(_tf("ui.shop.stat_armor", [float(stats.get("armor", 0.0))], "Armor: %.1f"))
    lines.append(_tf("ui.shop.stat_dodge", [(float(stats.get("dodge_chance", 0.0)) * 100.0)], "Dodge: %.1f%%"))
    lines.append(_tf("ui.shop.stat_extra_atk_speed", [extra_attack_speed_percent], "Bonus Atk Speed: %+.1f%%"))
    lines.append(_tf("ui.shop.stat_crit", [(float(stats.get("crit_chance", 0.05)) * 100.0)], "Crit: %.1f%%"))
    lines.append(_tf("ui.shop.stat_lifesteal", [(float(stats.get("lifesteal", 0.0)) * 100.0)], "Lifesteal: %.1f%%"))
    _append_weapon_tag_lines(lines, tag_state)
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
        button.disabled = _pending_replace_offer_id.is_empty()

        var has_weapon: bool = slot_weapon is Dictionary and not str((slot_weapon as Dictionary).get("weapon_id", "")).is_empty()
        if has_weapon:
            var weapon: Dictionary = slot_weapon
            var weapon_id: String = str(weapon.get("weapon_id", "weapon"))
            var weapon_name: String = LocaleService.t_data("weapon", weapon_id, "name", weapon_id)
            var rarity_label: String = _rarity_label(str(weapon.get("rarity", "common")))
            button.tooltip_text = "%d: %s [%s]" % [i + 1, weapon_name, rarity_label]
            var icon_path: String = _resolve_weapon_icon_path(weapon_id)
            var icon: Texture2D = _load_texture_cached(icon_path, _weapon_icon_cache)
            if icon != null:
                button.icon = icon
                button.text = ""
            else:
                button.text = _tx("ui.shop.no_image", "No Image")
        else:
            button.tooltip_text = _tf("ui.shop.weapon_slot_empty", [i + 1], "%d: Empty")
            button.text = _tf("ui.shop.weapon_slot_empty", [i + 1], "%d: Empty")

        button.pressed.connect(_on_weapon_slot_pressed.bind(i))
        _equipped_weapons_grid.add_child(button)

func _rebuild_elite_hint() -> void:
    if _elite_hint_label == null:
        return
    var start_stage_id: String = str(_snapshot.get("stage_id", GameManager.current_stage_id))
    var elite_info: Dictionary = _find_nearest_future_elite_stage(start_stage_id)
    if elite_info.is_empty():
        _elite_hint_label.text = _tx("ui.shop.elite_hint_none", "No elite warning in upcoming stages.")
        return
    var stage_no: int = int(elite_info.get("stage_no", 0))
    if stage_no <= 0:
        _elite_hint_label.text = _tx("ui.shop.elite_hint_none", "No elite warning in upcoming stages.")
        return
    _elite_hint_label.text = _tf(
        "ui.shop.elite_hint_fmt",
        [stage_no],
        "An elite enemy will appear in stage %d."
    )

func _find_nearest_future_elite_stage(start_stage_id: String) -> Dictionary:
    var start_stage_no: int = _extract_stage_number(start_stage_id)
    if start_stage_no <= 0:
        return {}
    var miss_count: int = 0
    for stage_no: int in range(start_stage_no, start_stage_no + 200):
        var stage_id: String = "stage_%03d" % stage_no
        if not BalanceService.has_stage_profile(stage_id):
            miss_count += 1
            if miss_count >= 2:
                break
            continue
        miss_count = 0
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
    if kind == "weapon":
        var weapon_id: String = _extract_offer_weapon_id(offer)
        return LocaleService.t_data("weapon", weapon_id, "desc", str(offer.get("description", "")))
    var item_id: String = str(offer.get("item_id", ""))
    return LocaleService.t_data("item", item_id, "desc", str(offer.get("description", "")))

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
