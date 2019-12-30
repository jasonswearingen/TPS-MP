extends RigidBody

var slide
var hit
var roll
var whoosh
export (Array, AudioStreamSample) var HIT
export (AudioStreamSample) var SLIDE
export (AudioStreamSample) var ROLL_SLOW
export (AudioStreamSample) var ROLL_MEDIUM
export (AudioStreamSample) var ROLL_FAST
export (AudioStreamSample) var WHOOSH

export (PackedScene) var particle_scn

var prev_lvl
var lvl
var avl
var avx
var avy
var avz

func _ready():
	slide = get_node("audio/slide")
	hit = get_node("audio/hit")
	roll = get_node("audio/roll")
	whoosh = get_node("audio/whoosh")

func _physics_process(delta):
	process_stuff()

func process_stuff():
	lvl = linear_velocity.length()
	avl = angular_velocity.length()
	avx = angular_velocity.x
	avy = angular_velocity.y
	avz = angular_velocity.z
	
	var bodies = get_colliding_bodies()
	
	if roll:
		if bodies.size() > 0:
			if !roll.playing:
				if abs(avl) > 0.25:
					roll.stream = ROLL_SLOW
				if abs(avl) > 4:
					roll.stream = ROLL_MEDIUM
				if abs(avl) > 8:
					roll.stream = ROLL_FAST
				roll.play()
		else:
			roll.stop()
	
		roll.unit_size = avl / 3
	
	if slide:
		if bodies.size() > 0 and lvl > 0.15:
			
			slide.pitch_scale = 1
			
			if !slide.playing:
				slide.stream = SLIDE
				slide.play()
			
	#		if lvl > 6:
	#			var particles = particle_scn.instance()
	#			globals.main.add_child(particles)
	#			particles.global_transform.origin = global_transform.origin
	#			particles.emitting = true
		else:
			slide.stop()

		#slide.pitch_scale = clamp(lvl, 1, 1.1)
		slide.unit_size = lvl
	
	if hit:
		if bodies.size() > 0 and (prev_lvl - lvl) >= 0.25:
			hit.stream = HIT[randi() % HIT.size()]
			hit.play()
		
		hit.unit_size = lvl

	# Set previous velocity
	prev_lvl = lvl
	
#	rpc_unreliable("update_trans_rot", translation, rotation)
#
#puppet func update_trans_rot(trans, rot):
#	translation = trans
#	rotation = rot
