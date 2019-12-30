extends Node

func _ready():
	pass

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func preload_sounds_from_dir(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.get_extension() == "wav":
			var file_path = path + "/" + file
			files.append(load(file_path))
	dir.list_dir_end()
	return files

func norm(value, vmin, vmax):
	return (value - vmin) / (vmax - vmin)

func some_lerp(norm, vmin, vmax):
	return (vmax - vmin) * norm + vmin

func map(value, source_min, source_max, dest_min, dest_max):
	return some_lerp(norm(value, source_min, source_max), dest_min, dest_max)

func look_at_with_x(trans, new_x, v_up):
	# Y vector
	trans.basis.x = new_x.normalized()
	trans.basis.z = v_up * -1
	trans.basis.y = trans.basis.z.cross(trans.basis.x).normalized()
	# Recompute z = y cross X
	trans.basis.z = trans.basis.y.cross(trans.basis.x).normalized()
	trans.basis.x = trans.basis.x * 1
	trans.basis = trans.basis.orthonormalized() # make sure it is valid
	return trans

func look_at_with_y(trans, new_y, v_up):
	# Y vector
	trans.basis.y = new_y.normalized()
	trans.basis.z = v_up * -1
	trans.basis.x = trans.basis.z.cross(trans.basis.y).normalized()
	# Recompute z = y cross X
	trans.basis.z = trans.basis.y.cross(trans.basis.x).normalized()
	trans.basis.x = trans.basis.x * -1
	trans.basis = trans.basis.orthonormalized() # make sure it is valid
	return trans

func look_at_with_z(trans, new_z, v_up):
	# Y vector
	trans.basis.z = new_z.normalized()
	trans.basis.y = v_up * 1
	trans.basis.x = trans.basis.y.cross(trans.basis.z).normalized()
	# Recompute z = y cross X
	trans.basis.y = trans.basis.z.cross(trans.basis.x).normalized()
	trans.basis.x = trans.basis.x * -1
	trans.basis = trans.basis.orthonormalized() # make sure it is valid
	return trans
