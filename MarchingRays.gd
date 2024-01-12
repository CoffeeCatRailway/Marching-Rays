@tool
extends MeshInstance3D

@export var run: bool = false:
	set(_value):
		_run()
		run = false;

@export var unitBox: Vector3 = Vector3(.25, .25, .25)
@export var isoLevel: float = .5
@export var size: int = 5
@export var material: Material

@export var noise: FastNoiseLite

func _ready() -> void:
	_run()

func _run() -> void:
	var halfSize: int = size / 2
	var cubes: Array[Vector4]
	for x in size:
		for y in size:
			for z in size:
				var pos = Vector3(x - halfSize, y - halfSize, z - halfSize) * unitBox * 2.
				var value := (noise.get_noise_3dv(pos) + 1.) / 2. + .01
				if value > isoLevel:
					var cube = Vector4(pos.x, pos.y, pos.z, value)
					cubes.append(cube)
	
	material.set_shader_parameter("isoLevel", isoLevel)
	material.set_shader_parameter("unitBox", unitBox)
	material.set_shader_parameter("cubesIn", cubes)
	mesh.material = material
	print("Passed cubes array of size ", size**3)

func _process(delta) -> void:
	DebugDraw2D.set_text("Frames", Engine.get_frames_drawn())
	DebugDraw2D.set_text("FPS", Engine.get_frames_per_second())
	DebugDraw2D.set_text("Delta", delta)
