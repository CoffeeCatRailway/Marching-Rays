extends Node

@export var MOUSE_SENSIIVITY := .05;
@export var MAX_SPEED := 300.;

var velocity := Vector3.ZERO
var mouseOffsets := Vector2.ZERO; # degrees
var mouseModeToggle := true # false is visible

func computeDirection(pitchRads: float, yawRads: float) -> Vector3:
	# Get front unit vector from pitch & yaw
	return Vector3(
		cos(pitchRads) * cos(yawRads),
		sin(pitchRads),
		cos(pitchRads) * sin(yawRads)
	)

func computeDirForward(yawRads: float) -> Vector3:
	# Get front unit direction on the XZ plane (not cosidering the height)
	return Vector3(
		cos(yawRads),
		0.,
		sin(yawRads)
	)

func computeDirRight(yawRads: float) -> Vector3:
	# Get right unit direction on the XZ plane (not cosidering the height)
	return Vector3(
		-sin(yawRads),
		0.,
		cos(yawRads)
	)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if mouseModeToggle:
			mouseOffsets += event.relative * MOUSE_SENSIIVITY
			# Keep pitch in (-90, 90) degrees range to prevent reversing the camera
			mouseOffsets.y = clamp(mouseOffsets.y, -87., 87.)
			var newDir = computeDirection(deg_to_rad(-mouseOffsets.y), deg_to_rad(mouseOffsets.x))
			
			# Update front vector in the shader
			var colorRect = get_parent()
			colorRect.material.set_shader_parameter("front", newDir)
	if event is InputEventKey:
		## Show/hide mouse
		if event.is_action_released("ui_cancel"):
			mouseModeToggle = !mouseModeToggle
			if mouseModeToggle:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func updateVelocity(delta) -> void:
	# Update velocity vector using actions (keyboard or gamepad axis)
	var deltaStep = MAX_SPEED * delta # current step size
	var dirForward = computeDirForward(deg_to_rad(mouseOffsets.x))
	var dirRight = computeDirRight(deg_to_rad(mouseOffsets.x))
	# we will have no inertia, if we release buttons, we will stop immediately
	self.velocity = Vector3.ZERO
	
	# forward/backward
	if Input.is_action_pressed("camera_forward"):
		self.velocity += deltaStep * dirForward
	elif Input.is_action_pressed("camera_backward"):
		self.velocity -= deltaStep * dirForward
	
	# left/right
	if Input.is_action_pressed("camera_left"):
		self.velocity -= deltaStep * dirRight
	elif Input.is_action_pressed("camera_right"):
		self.velocity += deltaStep * dirRight
	
	# up/down
	if Input.is_action_pressed("camera_up"):
		self.velocity.y = deltaStep
	elif Input.is_action_pressed("camera_down"):
		self.velocity.y = -deltaStep

func updateCameraPosition(delta) -> void:
	# Update camera position and pass it to the shader
	var colorRect = get_parent()
	var currentPos: Vector3 = colorRect.material.get_shader_parameter("cameraPos")
	var newPos: Vector3 = currentPos + self.velocity * delta
	colorRect.material.set_shader_parameter("cameraPos", newPos)

func _physics_process(delta) -> void:
	# Move camera with steady 60 FPS
	updateVelocity(delta)
	updateCameraPosition(delta)






