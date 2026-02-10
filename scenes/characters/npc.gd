## NPC Visual: Maneja la representación visual del NPC en la ventanilla
## Incluye sprite del cuerpo, cara clickeable, y carnet como hijo
extends Area2D

signal npc_llego_a_ventanilla(npc_data: AbstractNPC)
signal npc_salio()
signal atacante_paso()  ## El atacante pasó de largo sin detenerse
signal cara_clickeada(foto_real_path: String)
signal carnet_campo_clickeado(campo: int, valor: String)
signal carnet_escaneado(datos_carnet: Dictionary)

## Nodos del NPC visual
@onready var sprite_cuerpo: Sprite2D = $SpriteCuerpo
@onready var sprite_cara: Sprite2D = $SpriteCuerpo/SpriteCara
@onready var click_cara: Area2D = $ClickCara
@onready var click_cara_col: CollisionShape2D = $ClickCara/CollisionShape2D
@onready var carnet_visual: CarnetVisual = $CarnetVisual

## Configuración de movimiento
@export_group("Coordenadas")
@export var x_inicio: float = 3583.0
@export var x_ventanilla: float = 2963.0
@export var x_salida_aceptado: float = 2151.0
@export var x_salida_rechazado: float = 3700.0
@export var x_atacante_destino: float = 900.0   ## Destino final del atacante

@export var y_base: float = 591.0

@export_group("Movimiento")
@export var velocidad: float = 300.0
@export var velocidad_atacante: float = 600.0   ## Los atacantes van al doble
@export var altura_bote: float = 10.0
@export var frecuencia_bote: float = 15.0

@export_group("Tamaño estandarizado")
## Ancho objetivo del cuerpo en píxeles de juego
@export var cuerpo_ancho_objetivo: float = 220.0
## Alto objetivo del cuerpo en píxeles de juego
@export var cuerpo_alto_objetivo: float = 614.0
## Tamaño de la cara al mostrarse (coincide con CollisionShape del ClickCara)
@export var cara_size_objetivo: Vector2 = Vector2(109.0, 109.0)

var _cara_visible: bool = false  ## Controla si la cara ampliada está mostrada

## Estado del NPC
enum State { INACTIVO, ENTRANDO, EN_VENTANILLA, SALIENDO_APROBADO, SALIENDO_RECHAZADO, ESPERANDO, ATACANTE_CORRIENDO, ATACANTE_DETENIDO }
var estado_actual: State = State.INACTIVO
var tiempo_transcurrido: float = 0.0
var _velocidad_actual: float = 300.0  ## Se ajusta según tipo de NPC

## Datos lógicos del NPC
var npc_data: AbstractNPC = null
var decision_tomada: int = GlobalEnums.DecisionGuardia.PENDIENTE

func _ready():
	visible = false
	# La cara empieza siempre oculta
	if sprite_cara:
		sprite_cara.visible = false
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
		State.ATACANTE_CORRIENDO:
			_mover_hacia(x_atacante_destino, delta)
			if global_position.x <= x_atacante_destino:
				_atacante_llego_a_destino()
		State.ATACANTE_DETENIDO:
			pass  # Se queda parado en X=900, visible

## Carga un AbstractNPC y configura el visual
func cargar_npc(data: AbstractNPC) -> void:
	npc_data = data
	decision_tomada = GlobalEnums.DecisionGuardia.PENDIENTE
	_cara_visible = false
	
	# Configurar sprite del cuerpo — escalar al tamaño estándar
	if sprite_cuerpo and data.ruta_sprite_npc:
		var tex = load(data.ruta_sprite_npc)
		if tex:
			sprite_cuerpo.texture = tex
			_ajustar_escala_cuerpo(tex)
	
	# Configurar cara — se carga pero permanece oculta
	if sprite_cara:
		sprite_cara.visible = false
		if data.cara_path and not data.cara_path.is_empty():
			var tex = load(data.cara_path)
			if tex:
				sprite_cara.texture = tex
				_ajustar_escala_cara(tex)
	
	# Posicionar fuera de escena
	global_position = Vector2(x_inicio, y_base)
	visible = true
	if carnet_visual:
		carnet_visual.visible = false
	tiempo_transcurrido = 0.0
	
	# ---- ATACANTE: sin carnet, velocidad alta, corre de largo ----
	if data.tipo_npc == "atacante":
		_velocidad_actual = velocidad_atacante
		estado_actual = State.ATACANTE_CORRIENDO
		print("[NPC] ¡ATACANTE detectado! Corriendo hacia X=", x_atacante_destino)
		return
	
	# ---- NPC NORMAL ----
	_velocidad_actual = velocidad
	_configurar_carnet_desde_documentos(data)
	estado_actual = State.ENTRANDO

## Ajusta el scale del SpriteCuerpo para que tenga un tamaño visual fijo
func _ajustar_escala_cuerpo(tex: Texture2D) -> void:
	var tex_w = float(tex.get_width())
	var tex_h = float(tex.get_height())
	if tex_w <= 0 or tex_h <= 0:
		return
	var sx = cuerpo_ancho_objetivo / tex_w
	var sy = cuerpo_alto_objetivo / tex_h
	# Usar el menor para mantener proporciones, centrado en ancho objetivo
	var s = min(sx, sy)
	sprite_cuerpo.scale = Vector2(s, s)

## Ajusta el scale y posición del SpriteCara para que quepa en la CollisionShape (109×109)
## SpriteCara es hijo de SpriteCuerpo, así que hay que compensar el scale del padre
## La cara se posiciona exactamente donde está el CollisionShape de ClickCara
func _ajustar_escala_cara(tex: Texture2D) -> void:
	var tex_w = float(tex.get_width())
	var tex_h = float(tex.get_height())
	if tex_w <= 0 or tex_h <= 0:
		return
	# Scale global deseado de la cara
	var sx_global = cara_size_objetivo.x / tex_w
	var sy_global = cara_size_objetivo.y / tex_h
	var s_global = min(sx_global, sy_global)
	# Compensar el scale del padre (SpriteCuerpo)
	var parent_sx = sprite_cuerpo.scale.x if sprite_cuerpo.scale.x != 0 else 1.0
	var parent_sy = sprite_cuerpo.scale.y if sprite_cuerpo.scale.y != 0 else 1.0
	sprite_cara.scale = Vector2(s_global / parent_sx, s_global / parent_sy)
	
	# Posicionar la cara exactamente en la CollisionShape de ClickCara
	# click_cara_col.position está en espacio local del NPC
	# Convertir a espacio local del SpriteCuerpo (compensar offset y scale del padre)
	if click_cara_col:
		var pos_cara = Vector2(click_cara_col.position.x + 120, click_cara_col.position.y)
		var col_pos = pos_cara
		var body_pos = sprite_cuerpo.position          # (48, 33) en espacio NPC
		var offset_npc = col_pos - body_pos             # Diferencia en espacio NPC
		# SpriteCuerpo escala a sus hijos, compensar
		sprite_cara.position = Vector2(offset_npc.x / parent_sx, offset_npc.y / parent_sy)

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
	_ocultar_cara()
	_ocultar_carnet()
	estado_actual = State.SALIENDO_APROBADO
	tiempo_transcurrido = 0.0

## El guardia rechaza al NPC
func rechazar() -> void:
	if estado_actual != State.EN_VENTANILLA:
		return
	decision_tomada = GlobalEnums.DecisionGuardia.RECHAZADO
	npc_data.estado = GlobalEnums.NPCState.DESAPROBADO
	_ocultar_cara()
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
	global_position.x += direccion * _velocidad_actual * delta

	tiempo_transcurrido += delta
	var offset_y = abs(sin(tiempo_transcurrido * frecuencia_bote)) * -altura_bote
	global_position.y = y_base + offset_y

func _llegar_a_ventanilla() -> void:
	estado_actual = State.EN_VENTANILLA
	global_position = Vector2(x_ventanilla, y_base)
	
	# Mostrar carnet
	if carnet_visual and npc_data and npc_data.incidencia != GlobalEnums.Incidencia.CARNET_OLVIDADO:
		carnet_visual.visible = true
	
	npc_llego_a_ventanilla.emit(npc_data)

func _ocultar_cara() -> void:
	_cara_visible = false
	if sprite_cara:
		sprite_cara.visible = false

func _ocultar_carnet() -> void:
	if carnet_visual:
		carnet_visual.visible = false

func _npc_fuera_de_escena() -> void:
	estado_actual = State.ESPERANDO
	visible = false
	npc_salio.emit()

## Atacante llegó a X=900: se detiene visible y deja un sprite persistente
func _atacante_llego_a_destino() -> void:
	global_position = Vector2(x_atacante_destino, y_base)
	estado_actual = State.ATACANTE_DETENIDO
	print("[NPC] Atacante se detuvo en X=", x_atacante_destino)
	
	# Crear un sprite persistente para que siga visible al resetear el nodo NPC
	var sprite_clon = Sprite2D.new()
	sprite_clon.texture = sprite_cuerpo.texture
	sprite_clon.scale = sprite_cuerpo.scale  # Ya escalado al tamaño estándar
	sprite_clon.global_position = global_position
	sprite_clon.add_to_group("atacante_persistente")
	get_tree().current_scene.add_child(sprite_clon)
	
	# Emitir señales para que el gameplay continúe
	atacante_paso.emit()
	# También emitimos npc_salio para que el flujo avance al siguiente NPC
	npc_salio.emit()

## Resetea completamente el NPC visual
func resetear() -> void:
	estado_actual = State.INACTIVO
	npc_data = null
	decision_tomada = GlobalEnums.DecisionGuardia.PENDIENTE
	visible = false
	tiempo_transcurrido = 0.0
	_cara_visible = false
	if sprite_cara:
		sprite_cara.visible = false
	if carnet_visual:
		carnet_visual.resetear()
		carnet_visual.visible = false

# --- SEÑALES DE INTERACCIÓN ---

func _on_click_cara(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if estado_actual == State.EN_VENTANILLA and npc_data:
			# Toggle: mostrar/ocultar cara ampliada
			_cara_visible = not _cara_visible
			if sprite_cara:
				sprite_cara.visible = _cara_visible
			print("[NPC] Cara ", "mostrada" if _cara_visible else "ocultada")
			cara_clickeada.emit(npc_data.cara_path)

func _on_carnet_campo_click(campo: int, valor: String) -> void:
	carnet_campo_clickeado.emit(campo, valor)

func _on_carnet_escaneo(datos: Dictionary) -> void:
	carnet_escaneado.emit(datos)
