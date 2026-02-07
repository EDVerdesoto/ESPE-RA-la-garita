## NPC Visual: Maneja la representación visual del NPC en la ventanilla
## Incluye sprite del cuerpo, cara clickeable, y carnet como hijo
extends Area2D

<<<<<<< HEAD
signal llego_a_ventanilla
signal cruzo_limite_spawn # Esta llama al siguiente
signal npc_salio_del_todo

@export_group("Coordenadas")
@export var x_inicio: float = 3583.0
@export var x_ventanilla: float = 2963.0
@export var x_limite_spawn: float = 1990.0 # Aquí nace el otro
@export var x_salida_final: float = 500.0  # Aquí muere este
=======
signal npc_llego_a_ventanilla(npc_data: AbstractNPC)
signal npc_salio()
signal cara_clickeada(foto_real_path: String)
signal carnet_campo_clickeado(campo: int, valor: String)
signal carnet_escaneado(datos_carnet: Dictionary)

## Nodos del NPC visual
@onready var sprite_cuerpo: Sprite2D = $SpriteCuerpo
@onready var sprite_cara: Sprite2D = $SpriteCuerpo/SpriteCara
@onready var click_cara: Area2D = $ClickCara
@onready var carnet_visual: CarnetVisual = $CarnetVisual

## Configuración de movimiento
@export_group("Coordenadas")
@export var x_inicio: float = 3583.0
@export var x_ventanilla: float = 2963.0
@export var x_salida_aceptado: float = 2151.0
@export var x_salida_rechazado: float = 3700.0
>>>>>>> ea7c6d2892cba18be21429e471ea651a102a8f25
@export var y_base: float = 591.0

@export_group("Movimiento")
@export var velocidad: float = 300.0
@export var altura_bote: float = 10.0
@export var frecuencia_bote: float = 15.0

<<<<<<< HEAD
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
=======
## Estado del NPC
enum State { INACTIVO, ENTRANDO, EN_VENTANILLA, SALIENDO_APROBADO, SALIENDO_RECHAZADO, ESPERANDO }
var estado_actual: State = State.INACTIVO
var tiempo_transcurrido: float = 0.0

## Datos lógicos del NPC
var npc_data: AbstractNPC = null
var decision_tomada: int = GlobalEnums.DecisionGuardia.PENDIENTE

func _ready():
	visible = false
	if click_cara:
		click_cara.input_event.connect(_on_click_cara)
	if carnet_visual:
		carnet_visual.campo_clickeado.connect(_on_carnet_campo_click)
		carnet_visual.carnet_escaneado.connect(_on_carnet_escaneo)
		carnet_visual.visible = false

func _process(delta: float) -> void:
	match estado_actual:
		State.ENTRANDO:
			_mover_hacia(x_ventanilla, delta)
			if global_position.x <= x_ventanilla:
				_llegar_a_ventanilla()
		State.SALIENDO_APROBADO:
			_mover_hacia(x_salida_aceptado, delta)
			if global_position.x <= x_salida_aceptado:
				_npc_fuera_de_escena()
		State.SALIENDO_RECHAZADO:
			_mover_hacia(x_salida_rechazado, delta)
			if global_position.x >= x_salida_rechazado:
				_npc_fuera_de_escena()

## Carga un AbstractNPC y configura el visual
func cargar_npc(data: AbstractNPC) -> void:
	npc_data = data
	decision_tomada = GlobalEnums.DecisionGuardia.PENDIENTE
	
	# Configurar sprite del cuerpo
	if sprite_cuerpo and data.ruta_sprite_npc:
		var tex = load(data.ruta_sprite_npc)
		if tex:
			sprite_cuerpo.texture = tex
	
	# Configurar cara real del NPC
	if sprite_cara and data.cara_path:
		var tex = load(data.cara_path)
		if tex:
			sprite_cara.texture = tex
	
	# Configurar carnet visual (buscar el CarnetUniversitario en los documentos)
	_configurar_carnet_desde_documentos(data)
	
	# Posicionar fuera de escena
	global_position = Vector2(x_inicio, y_base)
	visible = true
	if carnet_visual:
		carnet_visual.visible = false
	
	# Iniciar entrada
	estado_actual = State.ENTRANDO
	tiempo_transcurrido = 0.0

## Busca el carnet en los documentos del NPC y configura el visual
func _configurar_carnet_desde_documentos(data: AbstractNPC) -> void:
	if not carnet_visual:
		return
	for doc in data.documentos:
		if doc is CarnetUniversitario and doc.configuracion is CarnetUniversitarioNPCConfig:
			carnet_visual.configurar(doc.configuracion as CarnetUniversitarioNPCConfig)
			return
	# Si no tiene carnet (CARNET_OLVIDADO), el carnet visual queda oculto
	carnet_visual.visible = false

## El guardia aprueba al NPC
func aprobar() -> void:
	if estado_actual != State.EN_VENTANILLA:
		return
	decision_tomada = GlobalEnums.DecisionGuardia.APROBADO
	npc_data.estado = GlobalEnums.NPCState.APROBADO
	_ocultar_carnet()
	estado_actual = State.SALIENDO_APROBADO
	tiempo_transcurrido = 0.0

## El guardia rechaza al NPC
func rechazar() -> void:
	if estado_actual != State.EN_VENTANILLA:
		return
	decision_tomada = GlobalEnums.DecisionGuardia.RECHAZADO
	npc_data.estado = GlobalEnums.NPCState.DESAPROBADO
	_ocultar_carnet()
	estado_actual = State.SALIENDO_RECHAZADO
	tiempo_transcurrido = 0.0

## Fuerza la salida si se acaba el tiempo
func forzar_salida() -> void:
	if estado_actual == State.EN_VENTANILLA:
		aprobar()  # Si no decide, el NPC pasa (como en Papers Please)

func esta_en_ventanilla() -> bool:
	return estado_actual == State.EN_VENTANILLA

# --- MOVIMIENTO ---

func _mover_hacia(objetivo_x: float, delta: float) -> void:
	var direccion = -1.0 if objetivo_x < global_position.x else 1.0
	global_position.x += direccion * velocidad * delta
>>>>>>> ea7c6d2892cba18be21429e471ea651a102a8f25
	tiempo_transcurrido += delta
	var offset_y = abs(sin(tiempo_transcurrido * frecuencia_bote)) * -altura_bote
	global_position.y = y_base + offset_y

<<<<<<< HEAD
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
=======
func _llegar_a_ventanilla() -> void:
	estado_actual = State.EN_VENTANILLA
	global_position = Vector2(x_ventanilla, y_base)
	
	# Mostrar carnet
	if carnet_visual and npc_data and npc_data.incidencia != GlobalEnums.Incidencia.CARNET_OLVIDADO:
		carnet_visual.visible = true
	
	npc_llego_a_ventanilla.emit(npc_data)

func _ocultar_carnet() -> void:
	if carnet_visual:
		carnet_visual.visible = false

func _npc_fuera_de_escena() -> void:
	estado_actual = State.ESPERANDO
	visible = false
	npc_salio.emit()

## Resetea completamente el NPC visual
func resetear() -> void:
	estado_actual = State.INACTIVO
	npc_data = null
	decision_tomada = GlobalEnums.DecisionGuardia.PENDIENTE
	visible = false
	tiempo_transcurrido = 0.0
	if carnet_visual:
		carnet_visual.resetear()
		carnet_visual.visible = false

# --- SEÑALES DE INTERACCIÓN ---

func _on_click_cara(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if estado_actual == State.EN_VENTANILLA and npc_data:
			print("[NPC] Cara clickeada - foto real: ", npc_data.cara_path)
			cara_clickeada.emit(npc_data.cara_path)

func _on_carnet_campo_click(campo: int, valor: String) -> void:
	carnet_campo_clickeado.emit(campo, valor)

func _on_carnet_escaneo(datos: Dictionary) -> void:
	carnet_escaneado.emit(datos)
>>>>>>> ea7c6d2892cba18be21429e471ea651a102a8f25
