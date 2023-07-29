extends Node2D

func _physics_process(delta):
	$Path2D/PathFollow2D.progress_ratio += $"..".speed * delta


