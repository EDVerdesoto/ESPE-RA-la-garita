extends Sprite2D

# Variables configurables desde el Inspector
@export_group("Coordenadas")
@export var x_inicio: float = 3583.0
@export var x_ventanilla: float = 2963.0
@export var x_salida_aceptado: float = 2151.0
@export var y_base: float = 591.0

@export_group("Movimiento")
@export var velocidad: float = 300.0
@export var altura_bote: float = 10.0
@export var frecuencia_bote: float = 15.0

# Referencia al nodo del Carnet (debe estar en la misma escena)
@onready var carnet_node = get_parent().get_node("Carnet")

enum State { ENTRANDO, EN_VENTANILLA, SALIENDO }
var estado_actual = State.ENTRANDO
var tiempo_transcurrido: float = 0.0

func _ready():
	# Posicionamiento inicial fuera de cámara
	global_position = Vector2(x_inicio, y_base)
	if carnet_node:
		carnet_node.visible = false

func _process(delta):
	match estado_actual:
		State.ENTRANDO:
			mover_hacia(x_ventanilla, delta)
			if global_position.x <= x_ventanilla:
				llegar_a_ventanilla()
		
		State.SALIENDO:
			mover_hacia(x_salida_aceptado, delta)
			if global_position.x <= x_salida_aceptado:
				# El personaje desaparece al salir
				queue_free()

func mover_hacia(objetivo_x: float, delta: float):
	# Movimiento horizontal simple
	var direccion = -1 if objetivo_x < global_position.x else 1
	global_position.x += direccion * velocidad * delta
	
	# Efecto de bote (caminata fake)
	tiempo_transcurrido += delta
	var offset_y = abs(sin(tiempo_transcurrido * frecuencia_bote)) * -altura_bote
	global_position.y = y_base + offset_y

func llegar_a_ventanilla():
	estado_actual = State.EN_VENTANILLA
	global_position = Vector2(x_ventanilla, y_base)
	if carnet_node:
		carnet_node.visible = true
	# Avisar al HUD que empiece el conteo 
	get_node("../HUD").empezar_conteo()

# Esta función es la que deben llamar el botón o el temporizador
func iniciar_salida():
	if estado_actual == State.EN_VENTANILLA:
		if carnet_node:
			carnet_node.visible = false
		estado_actual = State.SALIENDO
		tiempo_transcurrido = 0.0 # Reiniciar para el bote al salir
