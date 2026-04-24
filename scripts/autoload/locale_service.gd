extends Node

signal locale_changed(locale: String)

const DEFAULT_LOCALE: String = "zh_CN"
const SUPPORTED_LOCALES: PackedStringArray = ["zh_CN", "en_US"]
const TRANSLATION_CSV_PATHS: PackedStringArray = [
	"res://i18n/ui_strings.csv",
	"res://i18n/data_strings.csv",
]

var _translations_loaded: bool = false
var _translations_by_locale: Dictionary = {}
var _active_locale: String = DEFAULT_LOCALE

func _ready() -> void:
	_ensure_translations_loaded()

func normalize_locale(raw: String) -> String:
	var normalized: String = raw.strip_edges()
	if SUPPORTED_LOCALES.has(normalized):
		return normalized
	return DEFAULT_LOCALE

func init_from_settings(settings: Dictionary) -> String:
	_ensure_translations_loaded()
	var system_settings: Dictionary = {}
	var system_value: Variant = settings.get("system", {})
	if system_value is Dictionary:
		system_settings = system_value
	return apply_locale(str(system_settings.get("language", DEFAULT_LOCALE)))

func apply_locale(raw: String) -> String:
	_ensure_translations_loaded()
	var normalized: String = normalize_locale(raw)
	TranslationServer.set_locale(normalized)
	var changed: bool = normalized != _active_locale
	_active_locale = normalized
	if changed:
		locale_changed.emit(_active_locale)
	return _active_locale

func get_active_locale() -> String:
	return _active_locale

func tx(key: String, fallback: String = "") -> String:
	_ensure_translations_loaded()
	var translated: String = tr(key)
	if translated == key and not fallback.is_empty():
		return fallback
	return translated

func tf(key: String, args: Array = [], fallback: String = "") -> String:
	var text: String = tx(key, fallback if not fallback.is_empty() else key)
	if args.is_empty():
		return text
	var placeholder_count: int = _count_format_placeholders(text)
	if placeholder_count <= 0:
		push_warning(
			"LocaleService.tf format mismatch (no placeholders): key=%s text=%s args=%s"
			% [key, text, str(args)]
		)
		return text
	if args.size() < placeholder_count:
		push_warning(
			"LocaleService.tf format mismatch (not enough args): key=%s text=%s args=%s"
			% [key, text, str(args)]
		)
		return fallback if not fallback.is_empty() else text

	var format_args: Variant
	if placeholder_count == 1:
		format_args = args[0]
	else:
		var trimmed: Array = []
		for i: int in range(placeholder_count):
			trimmed.append(args[i])
		format_args = trimmed

	if args.size() != placeholder_count:
		push_warning(
			"LocaleService.tf format mismatch (arg count adjusted): key=%s text=%s args=%s placeholders=%d"
			% [key, text, str(args), placeholder_count]
		)
	return text % format_args

func _count_format_placeholders(text: String) -> int:
	var count: int = 0
	var i: int = 0
	while i < text.length():
		if text[i] != "%":
			i += 1
			continue
		if i + 1 < text.length() and text[i + 1] == "%":
			i += 2
			continue
		count += 1
		var j: int = i + 1
		while j < text.length():
			var token: String = text[j]
			if _is_format_specifier(token):
				break
			if token == "%":
				j -= 1
				break
			j += 1
		i = max(i + 1, j + 1)
	return count

func _is_format_specifier(token: String) -> bool:
	return token.length() == 1 and "bcdoOxXeEfgGaAs".contains(token)

func t_data(kind: String, id: String, field: String, fallback: String = "") -> String:
	if kind.is_empty() or id.is_empty() or field.is_empty():
		return fallback
	var key: String = "data.%s.%s.%s" % [kind, id, field]
	return tx(key, fallback)

func get_locale_label(locale_key: String) -> String:
	match normalize_locale(locale_key):
		"en_US":
			return tx("locale.label.en_US", "English")
		_:
			return tx("locale.label.zh_CN", "Chinese (Simplified)")

func _ensure_translations_loaded() -> void:
	if _translations_loaded:
		return
	_translations_by_locale.clear()
	for locale_key: String in SUPPORTED_LOCALES:
		var translation: Translation = Translation.new()
		translation.locale = locale_key
		_translations_by_locale[locale_key] = translation

	for csv_path: String in TRANSLATION_CSV_PATHS:
		_load_translation_csv(csv_path)

	for locale_key: String in _translations_by_locale.keys():
		var translation_value: Variant = _translations_by_locale.get(locale_key)
		if translation_value is Translation:
			TranslationServer.add_translation(translation_value as Translation)

	_translations_loaded = true

func _load_translation_csv(csv_path: String) -> void:
	if not FileAccess.file_exists(csv_path):
		return
	var file: FileAccess = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		return

	if file.eof_reached():
		return

	var header: PackedStringArray = file.get_csv_line()
	if header.is_empty():
		return

	var key_index: int = header.find("key")
	if key_index < 0:
		return

	var locale_column_indices: Dictionary = {}
	for i: int in range(header.size()):
		var column_name: String = header[i].strip_edges()
		if SUPPORTED_LOCALES.has(column_name):
			locale_column_indices[column_name] = i

	if locale_column_indices.is_empty():
		return

	var max_locale_index: int = -1
	for locale_index_value: Variant in locale_column_indices.values():
		max_locale_index = max(max_locale_index, int(locale_index_value))

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue
		if key_index >= row.size():
			continue

		var key: String = row[key_index].strip_edges()
		if key.is_empty() or key.begins_with("#"):
			continue

		for locale_key: String in locale_column_indices.keys():
			var locale_index: int = int(locale_column_indices[locale_key])
			if locale_index >= row.size():
				continue
			var value: String = row[locale_index]
			if locale_index == max_locale_index and row.size() > max_locale_index + 1:
				var tail_parts: Array[String] = []
				for i: int in range(locale_index, row.size()):
					tail_parts.append(row[i])
				value = ",".join(tail_parts)
			if value.is_empty():
				continue

			var translation_value: Variant = _translations_by_locale.get(locale_key, null)
			if not (translation_value is Translation):
				continue
			(translation_value as Translation).add_message(key, value)
