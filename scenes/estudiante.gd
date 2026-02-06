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

# Referencia al nodo del Carnet
@onready var carnet_node = get_parent().get_node("Carnet")

# Añadimos el estado ESPERANDO para controlar la pausa
enum State { ENTRANDO, EN_VENTANILLA, SALIENDO, ESPERANDO }
var estado_actual = State.ENTRANDO
var tiempo_transcurrido: float = 0.0

func _ready():
	reiniciar_personaje()

func _process(delta):
	match estado_actual:
		State.ENTRANDO:
			mover_hacia(x_ventanilla, delta)
			if global_position.x <= x_ventanilla:
				llegar_a_ventanilla()
		
		State.SALIENDO:
			mover_hacia(x_salida_aceptado, delta)
			if global_position.x <= x_salida_aceptado:
				esperar_y_regresar()
		
		State.ESPERANDO:
			# Aquí no hace nada, solo se queda quieto o invisible
			pass

func mover_hacia(objetivo_x: float, delta: float):
	var direccion = -1 if objetivo_x < global_position.x else 1
	global_position.x += direccion * velocidad * delta
	
	tiempo_transcurrido += delta
	var offset_y = abs(sin(tiempo_transcurrido * frecuencia_bote)) * -altura_bote
	global_position.y = y_base + offset_y

func llegar_a_ventanilla():
	estado_actual = State.EN_VENTANILLA
	global_position = Vector2(x_ventanilla, y_base)
	if carnet_node:
		carnet_node.visible = true
	get_node("../HUD").empezar_conteo()

func iniciar_salida():
	if estado_actual == State.EN_VENTANILLA:
		if carnet_node:
			carnet_node.visible = false
		estado_actual = State.SALIENDO
		tiempo_transcurrido = 0.0

# Esta es la lógica nueva para el ciclo
func esperar_y_regresar():
	estado_actual = State.ESPERANDO
	visible = false # Lo ocultamos mientras espera
	
	# Esperamos 2 segundos
	await get_tree().create_timer(2.0).timeout
	
	# Lo reseteamos todo para que vuelva a entrar
	reiniciar_personaje()

func reiniciar_personaje():
	global_position = Vector2(x_inicio, y_base)
	visible = true
	estado_actual = State.ENTRANDO
	tiempo_transcurrido = 0.0
	if carnet_node:
		carnet_node.visible = false
