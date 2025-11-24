extends Camera2D

@export var ruta_panoramica: NodePath
@export var velocidad := 700.0
@export var tiempo_transicion := 0.9

@export var vista_afuera := Vector2(5980, 2100)
@export var vista_adentro := Vector2(2000, 2100)
@export var permitir_paneo_libre := true

var rect_fondo: Rect2
var mitad_viewport_mundo := Vector2.ZERO
var tween_activo: Tween = null

func _ready():
	_actualizar_rect_fondo()
	_actualizar_mitad_viewport()

	global_position = _limitar_a_fondo(vista_afuera)

func _process(delta):
	# Si cambias zoom en runtime, recalcula
	_actualizar_mitad_viewport()

	if permitir_paneo_libre and tween_activo == null:
		var direccion := Vector2(
			Input.get_action_strength("pan_derecha") - Input.get_action_strength("pan_izquierda"),
			Input.get_action_strength("pan_abajo")   - Input.get_action_strength("pan_arriba")
		)

		if direccion != Vector2.ZERO:
			print(global_position)
			global_position += direccion.normalized() * velocidad * delta
			global_position = _limitar_a_fondo(global_position)

	if Input.is_action_just_pressed("mirar_adentro"):
		_ir_a(vista_adentro)
	elif Input.is_action_just_pressed("mirar_afuera"):
		_ir_a(vista_afuera)

func _ir_a(pos: Vector2):
	print(pos)
	if tween_activo:
		tween_activo.kill()

	tween_activo = create_tween()
	tween_activo.tween_property(
		self,
		"global_position",
		_limitar_a_fondo(pos),
		tiempo_transicion
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween_activo.finished.connect(func():
		tween_activo = null
	)

func _actualizar_rect_fondo():
	var pano := get_node(ruta_panoramica) as Sprite2D
	var tex_size := pano.texture.get_size()

	# Escala real en mundo (si escalaste el sprite)
	var escala := pano.global_transform.get_scale()
	var size_mundo := tex_size * escala

	# Top-left según centered
	var top_left_local := Vector2.ZERO
	if pano.centered:
		top_left_local = -tex_size * 0.5 + pano.offset
	else:
		top_left_local = pano.offset

	var top_left_global := pano.to_global(top_left_local)
	rect_fondo = Rect2(top_left_global, size_mundo)

func _actualizar_mitad_viewport():
	var vp_size := get_viewport_rect().size
	# Visible en mundo depende del zoom:
	# si zoom=2 ves la mitad del mundo, por eso se divide
	mitad_viewport_mundo = (vp_size * 0.5) / zoom

func _limitar_a_fondo(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(
			pos.x,
			rect_fondo.position.x + mitad_viewport_mundo.x,
			rect_fondo.position.x + rect_fondo.size.x - mitad_viewport_mundo.x
		),
		clamp(
			pos.y,
			rect_fondo.position.y + mitad_viewport_mundo.y,
			rect_fondo.position.y + rect_fondo.size.y - mitad_viewport_mundo.y
		)
	)
