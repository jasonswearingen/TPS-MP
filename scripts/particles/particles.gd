extends Particles

func _physics_process(delta):
	if !emitting:
		queue_free()
