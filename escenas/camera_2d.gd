extends Camera2D

@export var ruta_panoramica: NodePath
@export var velocidad := 700.0
@export var tiempo_transicion := 0.9

@export var vista_afuera := Vector2(2885, 555)
@export var vista_adentro := Vector2(1325, 540)

@export var zoom_normal := Vector2(1.1, 1.1) 
@export var zoom_out := Vector2(0.85, 0.85)    

@export var permitir_paneo_libre := true

var rect_fondo: Rect2
var mitad_viewport_mundo := Vector2.ZERO
var tween_activo: Tween = null

func _ready():
	_actualizar_rect_fondo()
	_actualizar_mitad_viewport()
	
	global_position = _limitar_pos_actual(vista_afuera)
	zoom = zoom_normal 

func _process(delta):
	# Actualizamos esto constantemente para el paneo manual
	_actualizar_mitad_viewport()

	if permitir_paneo_libre and tween_activo == null:
		var direccion := Vector2(
			Input.get_action_strength("pan_derecha") - Input.get_action_strength("pan_izquierda"),
			Input.get_action_strength("pan_abajo")   - Input.get_action_strength("pan_arriba")
		)

		if direccion != Vector2.ZERO:
			print(global_position)
			global_position += direccion.normalized() * velocidad * delta
			# Aquí sí usamos el límite actual porque nos movemos con el zoom actual
			global_position = _limitar_pos_actual(global_position)

	if Input.is_action_just_pressed("mirar_adentro"):
		_ir_a(vista_adentro, zoom_out) 
	elif Input.is_action_just_pressed("mirar_afuera"):
		_ir_a(vista_afuera, zoom_normal)

func _ir_a(pos: Vector2, target_zoom: Vector2):
	if tween_activo:
		tween_activo.kill()

	# 1. Calculamos cuál será el limite permitido CON EL FUTURO ZOOM
	var limite_futuro = _calcular_limite_con_zoom(pos, target_zoom)

	tween_activo = create_tween()
	tween_activo.set_parallel(true) 
	
	# 2. Usamos ese límite futuro como destino final
	tween_activo.tween_property(
		self,
		"global_position",
		limite_futuro, 
		tiempo_transicion
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween_activo.tween_property(
		self,
		"zoom",
		target_zoom,
		tiempo_transicion
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween_activo.finished.connect(func():
		tween_activo = null
	)

# Función estándar que usa el zoom actual (para _process)
func _limitar_pos_actual(pos: Vector2) -> Vector2:
	if rect_fondo.size == Vector2.ZERO: return pos 
	return _aplicar_clamp(pos, mitad_viewport_mundo)

# NUEVA FUNCIÓN: Calcula el clamp simulando un zoom diferente
func _calcular_limite_con_zoom(pos: Vector2, zoom_simulado: Vector2) -> Vector2:
	if rect_fondo.size == Vector2.ZERO: return pos 
	
	var vp_size := get_viewport_rect().size
	# Calculamos la mitad del viewport hipotética con el zoom futuro
	var mitad_futura = (vp_size * 0.5) / zoom_simulado
	
	return _aplicar_clamp(pos, mitad_futura)

# Lógica del clamp extraída para reutilizar
func _aplicar_clamp(pos: Vector2, margen: Vector2) -> Vector2:
	return Vector2(
		clamp(
			pos.x,
			rect_fondo.position.x + margen.x,
			rect_fondo.position.x + rect_fondo.size.x - margen.x
		),
		clamp(
			pos.y,
			rect_fondo.position.y + margen.y,
			rect_fondo.position.y + rect_fondo.size.y - margen.y
		)
	)
# El resto de funciones (_actualizar_rect_fondo, etc) siguen igual...
func _actualizar_rect_fondo():
	var pano := get_node(ruta_panoramica) as Sprite2D
	if not pano: return 
	var tex_size := pano.texture.get_size()
	var escala := pano.global_transform.get_scale()
	var size_mundo := tex_size * escala
	var top_left_local := Vector2.ZERO
	if pano.centered:
		top_left_local = -tex_size * 0.5 + pano.offset
	else:
		top_left_local = pano.offset
	var top_left_global := pano.to_global(top_left_local)
	rect_fondo = Rect2(top_left_global, size_mundo)

func _actualizar_mitad_viewport():
	var vp_size := get_viewport_rect().size
	mitad_viewport_mundo = (vp_size * 0.5) / zoom
