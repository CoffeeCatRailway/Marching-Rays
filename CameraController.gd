extends Node3D

@export var rotateSpeed := 1.
var angle := 0

func _process(delta):
	rotation.y = fmod(rotation.y + rotateSpeed * delta, PI * 2.)
