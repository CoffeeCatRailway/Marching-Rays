extends Node

@export var WHEEL_STEP := 5.
@onready var fov: float = get_parent().material.get_shader_parameter("fov")

func updateFov(nfov: float) -> void:
	# keep fov in [15, 135]
	self.fov = clamp(nfov, 15., 135.)
	get_parent().material.set_shader_parameter("fov", nfov)

func _input(event) -> void:
	# Process mouse wheel scroll event
	if event.is_action_pressed("camera_zoom_in"):
		updateFov(fov - WHEEL_STEP)
	elif event.is_action_pressed("camera_zoom_out"):
		updateFov(fov + WHEEL_STEP)
