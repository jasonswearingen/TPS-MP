extends VehicleBody

var driver

# Behaviour values
export var MAX_ENGINE_FORCE = 200
export var MAX_BRAKE_FORCE = 5.0
export var MAX_STEER_ANGLE = 0.5

export var steer_speed = 5.0

var steer_target = 0.0
var steer_angle = 0.0

# Input
export var joy_steering = JOY_ANALOG_LX
export var steering_mult = -1.0
export var joy_throttle = JOY_ANALOG_R2
export var throttle_mult = 1.0
export var joy_brake = JOY_ANALOG_L2
export var brake_mult = 1.0

# Sounds
var engine_player
var brakes_player
var air_player
var collision_player
var slide_player

var idle_sound = preload("res://sounds/vehicles/truck/idle.wav")
var engine_sound = preload("res://sounds/vehicles/truck/idle.wav")
var brakes_sound = preload("res://sounds/vehicles/truck/brakes.wav")
var tire_sound = preload("res://sounds/vehicles/truck/tires.wav")
var skid_sound = preload("res://sounds/vehicles/truck/skid.wav")
var air_sound = preload("res://sounds/physics/wind.wav")
var spring_sound = [
	preload("res://sounds/vehicles/truck/spring_1.wav"),
	preload("res://sounds/vehicles/truck/spring_2.wav"),
	preload("res://sounds/vehicles/truck/spring_4.wav"),
	preload("res://sounds/vehicles/truck/spring_4.wav")
]
var collision_sound = [
	preload("res://sounds/vehicles/truck/collision.wav")
]
var slide_sound = preload("res://sounds/vehicles/truck/body_slide.wav")
var slide_player_unit_db = 0.0
var slide_player_unit_db_target = 0.0

# Wheels
onready var wheels = {
	FR = {
		node = get_node("FR"),
		trans = 0.0,
		prev_trans = 0.0,
		rpm = 0.0,
		spring = get_node("FR/spring"),
		contact = get_node("FR/contact"),
		skid = get_node("FR/skid")
	},
	FL = {
		node = get_node("FL"),
		trans = 0.0,
		prev_trans = 0.0,
		rpm = 0.0,
		spring = get_node("FL/spring"),
		contact = get_node("FL/contact"),
		skid = get_node("FL/skid")
	},
	RR = {
		node = get_node("RR"),
		trans = 0.0,
		prev_trans = 0.0,
		rpm = 0.0,
		spring = get_node("RR/spring"),
		contact = get_node("RR/contact"),
		skid = get_node("RR/skid")
	},
	RL = {
		node = get_node("RL"),
		trans = 0.0,
		prev_trans = 0.0,
		rpm = 0.0,
		spring = get_node("RL/spring"),
		contact = get_node("RL/contact"),
		skid = get_node("RL/skid")
	}
}

# Skid
var skid_scn

# Velocity
var lvl = 0.0
var prev_lvl = 0.0
var prev_pos = Vector3()
var current_speed_mps = 0.0

# Misc
var main_scn

# Engine
var throttle_val = 0.0
var throttle_val_target = 0.0
var steer_val = 0.0
var brake_val = 0.0

var gear_ratio = [
	3.380/1,
	2.000/1,
	1.325/1,
	1.000/1
]
var current_gear = 0
var switching_gears = false

var max_engine_RPM = 5000.0
var min_engine_RPM = 1000.0
var engine_RPM = 0.0
var prev_engine_RPM = 0.0

func _ready():
	# Misc
	main_scn = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	
	# Sounds
	collision_player = get_node("audio/collision")
	slide_player = get_node("audio/slide")
	engine_player = get_node("audio/engine")
	brakes_player = get_node("audio/breaks")
	air_player = get_node("audio/air")
	air_player.stream = air_sound
	
	# Skids
	skid_scn = preload("res://scenes/misc/skid.tscn")
	
func _physics_process(delta):
	if driver:
		if is_network_master():
			process_input(delta)
	
	if is_network_master():
		rpc("process_other_stuff", delta)

func process_input(delta):
	steer_val = steering_mult * Input.get_joy_axis(0, joy_steering)
	#throttle_val = throttle_mult * Input.get_joy_axis(0, joy_throttle)
	brake_val = brake_mult * Input.get_joy_axis(0, joy_brake)
	
	throttle_val_target = 0.0
	
	if (throttle_val_target < 0.0):
		throttle_val_target = 0.0
	
	if (brake_val < 0.0):
		brake_val = 0.0
	
	# overrules for keyboard
	if driver.is_network_master():
		if Input.is_action_pressed("movement_forward"):
			throttle_val_target = 1.0
		if Input.is_action_pressed("movement_backward"):
			throttle_val_target = -1.0
		if Input.is_action_pressed("jump"):
			brake_val = 1.0
		if Input.is_action_pressed("movement_left"):
			steer_val = 1.0
		elif Input.is_action_pressed("movement_right"):
			steer_val = -1.0
	
master func process_other_stuff(delta):
	steer_target = steer_val * MAX_STEER_ANGLE
	
	if (steer_target < steer_angle):
		steer_angle -= steer_speed * delta
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		steer_angle += steer_speed * delta
		if (steer_target < steer_angle):
			steer_angle = steer_target
	
	steering = steer_angle
	
	# Velocity
	lvl = linear_velocity.length()
	# Same
	current_speed_mps = (translation - prev_pos).length() / delta
	
	throttle_val += (throttle_val_target - throttle_val) * 10 * delta
	
	# Wheels
	for w in wheels.values():
		if w.node.is_in_contact():
			w.trans = w.node.translation.y
			if (w.trans - w.prev_trans) > 0.02:
				randomize()
				w.spring.stream = spring_sound[randi() % spring_sound.size()]
				w.spring.play()
			w.contact.unit_size = lvl / 50
			if !w.contact.playing:
				w.contact.stream = tire_sound
				w.contact.play()
			w.prev_trans = w.trans
		else:
			w.contact.stop()

		if w.node.get_skidinfo() < 0.05:
			if !w.skid.playing:
				w.skid.stream = skid_sound
				w.skid.play()
		
		var skid_unit_size = 0.0
		var skid_unit_size_target = (1 - w.node.get_skidinfo()) * 5
		skid_unit_size += (skid_unit_size_target - skid_unit_size) * 0.25
		w.skid.unit_size = skid_unit_size
		
		if w.node.is_in_contact() and w.node.get_skidinfo() < 0.15:
			var skid = skid_scn.instance()
			main_scn.add_child(skid)
			skid.global_transform.origin = w.node.global_transform.origin + Vector3(0, -w.node.wheel_radius + 0.15, 0)
		
		w.rpm = (lvl / (w.node.wheel_radius * TAU)) * 300
	
	# Engine
	engine_RPM = clamp(((wheels.FL.rpm + wheels.FR.rpm)) / 2 * gear_ratio[current_gear], min_engine_RPM, max_engine_RPM)
	#engine_RPM = (throttle_val * gear_ratio[current_gear]) * 1000
	#print(engine_RPM)
	
	shift_gears()
	
	#print(current_gear)
	#print(linear_velocity.length())
	#print(current_speed_mps)
	#print(get_speed_kph())
	#print(wheels.FL.rpm)
	
	process_sounds()
	
	prev_lvl = lvl
	prev_pos = translation
	prev_engine_RPM = engine_RPM
	
	rpc_unreliable("update_trans_rot", translation, rotation, get_node("body").rotation, driver, engine_force, steer_angle, engine_RPM)

puppet func update_trans_rot(trans, rot, body_rot, drv, en_f, st_angle, en_RPM):
	translation = trans
	rotation = rot
	get_node("body").rotation = body_rot
	driver = drv
	steering = st_angle
	engine_force = en_f
	engine_RPM = en_RPM
	process_sounds()
	
func process_sounds():
	if !engine_player.playing:
		engine_player.stream = engine_sound
		engine_player.play()
	engine_player.pitch_scale = clamp(abs(engine_RPM / 1000) * 1.0, 1.0, 5.0)

	engine_force = MAX_ENGINE_FORCE / gear_ratio[current_gear] * throttle_val
	brake = brake_val * MAX_BRAKE_FORCE
	
	# Air
	air_player.unit_size = lvl / 30
	if !air_player.playing:
		air_player.play()
	
	# Collisions
	var bodies = get_colliding_bodies()
	
	# Smack player
	if bodies.size() > 0 and abs(prev_lvl - lvl) > 5:
		for b in bodies:
			if b is Player:
				b.rpc("die")
	
	if bodies.size() > 0 and abs(prev_lvl - lvl) > 0.5:
		if !collision_player.playing:
			collision_player.pitch_scale = randf() * 2 + 1
			collision_player.stream = collision_sound[randi() % collision_sound.size()]
			collision_player.play()
	
	# Sliding
	if !slide_player.playing:
		slide_player.stream = slide_sound
		slide_player.play()
	if bodies.size() > 0 and lvl > 0.3:
		slide_player_unit_db_target = 2
	else:
		slide_player_unit_db_target = -80
	slide_player_unit_db += (slide_player_unit_db_target - slide_player_unit_db) * 0.9
	slide_player.unit_db = slide_player_unit_db

func shift_gears():
	var appropriate_gear
	
	if engine_RPM >= max_engine_RPM:
		appropriate_gear = current_gear
		for i in gear_ratio:
			if wheels.FL.rpm * gear_ratio[i] < max_engine_RPM:
				appropriate_gear = i
				break
		current_gear = appropriate_gear

	if engine_RPM <= min_engine_RPM:
		appropriate_gear = current_gear
		var gear_ratio_inverted = gear_ratio
		gear_ratio_inverted.invert()
		for j in gear_ratio_inverted:
			if wheels.FL.rpm * gear_ratio[j] > min_engine_RPM:
				appropriate_gear = j
				break
		current_gear = appropriate_gear

func get_speed_kph():
	return current_speed_mps * 3600.0 / 1000.0
