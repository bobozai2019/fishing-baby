extends SceneTree


func _initialize() -> void:
	call_deferred("_capture_from_args")


func _capture_from_args() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: godot -s res://scripts/tools/capture_scene.gd <scene_path> <output_path> [width] [height]")
		quit(1)
		return

	var scene_path := args[0]
	var output_path := args[1]
	var width := int(args[2]) if args.size() >= 3 else 1280
	var height := int(args[3]) if args.size() >= 4 else 720

	if DisplayServer.get_name() == "headless":
		push_error("capture_scene.gd requires a real display driver. In this Godot build, --headless uses the dummy renderer and cannot export viewport textures. Run capture in windowed mode.")
		quit(6)
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Failed to load scene: %s" % scene_path)
		quit(2)
		return

	var instance := packed.instantiate()

	var viewport := SubViewport.new()
	viewport.name = "CaptureViewport"
	viewport.size = Vector2i(width, height)
	viewport.transparent_bg = false
	viewport.disable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	root.add_child(viewport)
	viewport.add_child(instance)

	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.35).timeout

	var texture := viewport.get_texture()
	if texture == null:
		push_error("Failed to get viewport texture for scene: %s" % scene_path)
		quit(3)
		return

	var image := texture.get_image()
	if image == null:
		push_error("Failed to capture image for scene: %s" % scene_path)
		quit(4)
		return

	var absolute_output := ProjectSettings.globalize_path(output_path)
	var output_dir := absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var save_error := image.save_png(absolute_output)
	if save_error != OK:
		push_error("Failed to save png: %s (%s)" % [absolute_output, error_string(save_error)])
		quit(5)
		return

	quit(0)
