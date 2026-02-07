extends Area2D

signal llego_a_ventanilla
signal cruzo_limite_spawn # Esta llama al siguiente
signal npc_salio_del_todo

@export_group("Coordenadas")
@export var x_inicio: float = 3583.0
@export var x_ventanilla: float = 2963.0
@export var x_limite_spawn: float = 1990.0 # Aquí nace el otro
@export var x_salida_final: float = 500.0  # Aquí muere este
@export var y_base: float = 591.0

@export_group("Movimiento")
@export var velocidad: float = 300.0
@export var altura_bote: float = 10.0
@export var frecuencia_bote: float = 15.0

@onready var carnet_node = $Carnet
@onready var sprite_cuerpo = $SpriteCuerpo # ¡Verifica que tengas este nodo!

enum State { ENTRANDO, EN_VENTANILLA, SALIENDO }
var estado_actual = State.ENTRANDO
var tiempo_transcurrido: float = 0.0
var ya_aviso_siguiente: bool = false
var ya_empezo_fade: bool = false # Nuevo candado para el fade

func _ready():
	global_position = Vector2(x_inicio, y_base)

func _process(delta):
	match estado_actual:
		State.ENTRANDO:
			if global_position.x > x_ventanilla:
				mover(-1, delta)
			else:
				llegar_a_ventanilla()
		
		State.SALIENDO:
			mover(-1, delta)
			
			# 1. EVENTO: Cruzar límite para llamar al siguiente (X=1990)
			if global_position.x <= x_limite_spawn and not ya_aviso_siguiente:
				ya_aviso_siguiente = true
				if carnet_node: carnet_node.visible = false
				print("NPC: ¡Crucé 1990! Llamando al relevo.")
				cruzo_limite_spawn.emit() # <--- ESTO DEBE ACTIVAR AL CONTROLLER
			
			# 2. EVENTO: Empezar a desaparecer (Un poco después, ej: X=1500)
			# Así no desaparece tan rápido.
			if global_position.x <= 1500.0 and not ya_empezo_fade:
				ya_empezo_fade = true
				comenzar_fade_out()

			# 3. EVENTO: Muerte definitiva (X=500)
			if global_position.x <= x_salida_final:
				print("NPC: Llegué al final. Bye bye.")
				queue_free()

func mover(direccion_x: float, delta: float):
	global_position.x += direccion_x * velocidad * delta
	tiempo_transcurrido += delta
	var offset_y = abs(sin(tiempo_transcurrido * frecuencia_bote)) * -altura_bote
	global_position.y = y_base + offset_y

func llegar_a_ventanilla():
	estado_actual = State.EN_VENTANILLA
	global_position = Vector2(x_ventanilla, y_base)
	if carnet_node: carnet_node.visible = true
	llego_a_ventanilla.emit()

func iniciar_salida():
	if estado_actual == State.EN_VENTANILLA:
		estado_actual = State.SALIENDO

func comenzar_fade_out():
	var tween = create_tween()
	# Que se demore 2.5 segundos en desaparecer (más lento)
	tween.tween_property(self, "modulate:a", 0.0, 2.5)
	# ¡YA NO LLAMAMOS A QUEUE_FREE AQUÍ! Dejamos que _process lo mate por posición.

func configurar_visual(textura_nueva: Texture2D):
	if sprite_cuerpo: sprite_cuerpo.texture = textura_nueva
