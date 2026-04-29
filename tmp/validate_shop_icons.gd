extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/shop_scene.tscn")
    if packed == null:
        push_error("failed_to_load_scene")
        quit(2)
        return
    var inst: Node = packed.instantiate()
    root.add_child(inst)
    await process_frame
    await process_frame
    var offers_grid: GridContainer = inst.get_node_or_null("Root/MainVBox/MidRow/OffersPanel/OffersMargin/OffersGrid")
    if offers_grid == null:
        print("offers_grid_missing")
        quit(3)
        return
    print("offers_children=%d" % offers_grid.get_child_count())
    var texture_rects := []
    var labels := []
    _collect(offers_grid, texture_rects, labels)
    var textured := 0
    for t in texture_rects:
        if t.texture != null:
            textured += 1
    var no_image := 0
    for l in labels:
        if str(l.text).to_lower().contains("no image"):
            no_image += 1
    print("texture_rects=%d" % texture_rects.size())
    print("textured_rects=%d" % textured)
    print("no_image_labels=%d" % no_image)
    quit()

func _collect(node: Node, texture_rects: Array, labels: Array) -> void:
    for child in node.get_children():
        if child is TextureRect:
            texture_rects.append(child)
        elif child is Label:
            labels.append(child)
        _collect(child, texture_rects, labels)
