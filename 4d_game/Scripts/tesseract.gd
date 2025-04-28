extends MeshInstance3D

@export var size: float = 1.0
@export var rotation_speed: float = 1.0
var toggle_rotation_dir = false

var vertices: Array = []
var edges: Array = []
var rotation_angles := {
	"xy": 0.0,
	"xz": 0.0,
	"xw": 0.0,
	"yz": 0.0,
	"yw": 0.0,
	"zw": 0.0,
}

func _ready():
	create_tesseract()

func create_tesseract():
	vertices.clear()
	edges.clear()
	
	for i in range(16):
		var v = Vector4(
			(i & 1) * size - size * 0.5,
			(i >> 1 & 1) * size - size * 0.5,
			(i >> 2 & 1) * size - size * 0.5,
			(i >> 3 & 1) * size - size * 0.5
		)
		vertices.append(v)
	
	for i in range(16):
		for j in range(i + 1, 16):
			var diff = i ^ j
			if diff and (diff & (diff - 1)) == 0:
				edges.append([i, j])

func _process(delta):
	handle_input(delta)
	update_mesh()
	
	if Input.is_action_just_pressed("toggle_rot") and toggle_rotation_dir == false:
		toggle_rotation_dir = true
		rotation_speed *= -1
	elif Input.is_action_just_pressed("toggle_rot") and toggle_rotation_dir == true:
		toggle_rotation_dir = false
		rotation_speed *= -1

func handle_input(delta):
	if Input.is_action_pressed("rotate_xy"):
		rotation_angles["xy"] += rotation_speed * delta
	if Input.is_action_pressed("rotate_xz"):
		rotation_angles["xz"] += rotation_speed * delta
	if Input.is_action_pressed("rotate_xw"):
		rotation_angles["xw"] += rotation_speed * delta
	if Input.is_action_pressed("rotate_yz"):
		rotation_angles["yz"] += rotation_speed * delta
	if Input.is_action_pressed("rotate_yw"):
		rotation_angles["yw"] += rotation_speed * delta
	if Input.is_action_pressed("rotate_zw"):
		rotation_angles["zw"] += rotation_speed * delta

func rotate_2d(a: float, b: float, angle: float) -> Array:
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	return [a * cos_a - b * sin_a, a * sin_a + b * cos_a]

func update_mesh():
	var m_mesh = ArrayMesh.new()
	var arrays = []
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var projected = []
	for v in vertices:
		var v_rot = v
		
		var res = rotate_2d(v_rot.x, v_rot.y, rotation_angles["xy"])
		v_rot.x = res[0]
		v_rot.y = res[1]
		
		res = rotate_2d(v_rot.x, v_rot.z, rotation_angles["xz"])
		v_rot.x = res[0]
		v_rot.z = res[1]
		
		res = rotate_2d(v_rot.x, v_rot.w, rotation_angles["xw"])
		v_rot.x = res[0]
		v_rot.w = res[1]
		
		res = rotate_2d(v_rot.y, v_rot.z, rotation_angles["yz"])
		v_rot.y = res[0]
		v_rot.z = res[1]
		
		res = rotate_2d(v_rot.y, v_rot.w, rotation_angles["yw"])
		v_rot.y = res[0]
		v_rot.w = res[1]
		
		res = rotate_2d(v_rot.z, v_rot.w, rotation_angles["zw"])
		v_rot.z = res[0]
		v_rot.w = res[1]
		
		var distance = 4.0
		var w = 1.0 / (distance - v_rot.w)
		var projected3d = Vector3(v_rot.x, v_rot.y, v_rot.z) * w
		projected.append(projected3d)
	
	for edge in edges:
		verts.append(projected[edge[0]])
		verts.append(projected[edge[1]])
	
	for i in range(verts.size()):
		indices.append(i)
	
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_LINES)
	
	for vtx in verts:
		surface.add_vertex(vtx)
	
	m_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	mesh = m_mesh
