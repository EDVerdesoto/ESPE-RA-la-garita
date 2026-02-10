## GuardiaMilitar: Guardia que corre hacia el NPC cuando se activa la alarma
## Tiene dos sprites: normal (corriendo) y frame2 (al colisionar con NPC)
extends Area2D

signal guardia_llego_a_npc()       ## Se emite cuando este guardia colisiona con el NPC
signal guardia_salio_de_escena()   ## Se emite cuando el guardia sale del mapa

## Sprites del militar
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

## Configuración
@export var sprite_corriendo_path: String = ""   ## Ruta al sprite normal (corriendo)
@export var sprite_frame2_path: String = ""       ## Ruta al sprite al colisionar con NPC
@export var velocidad: float = 1000.0
@export var altura_bote: float = 12.0
@export var frecuencia_bote: float = 18.0

## Posiciones
@export var x_inicio: float = 3800.0             ## Posición inicial fuera de pantalla (derecha)
@export var y_base: float = 591.0

## Estado
enum Estado { INACTIVO, CORRIENDO_HACIA_NPC, EN_NPC, SALIENDO }
var estado: Estado = Estado.INACTIVO
var tiempo_transcurrido: float = 0.0
var objetivo_x: float = 0.0       ## Posición X del NPC objetivo
var x_salida: float = -500.0      ## Destino para salir de escena por la izquierda
var _npc_ref: Node = null          ## Referencia al nodo NPC

func _ready():
	visible = false
	# Conectar detección de colisión con áreas (el NPC es Area2D)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	# Actualizar objetivo en tiempo real para seguir al NPC si se mueve
	if estado == Estado.CORRIENDO_HACIA_NPC and _npc_ref and is_instance_valid(_npc_ref):
		objetivo_x = _npc_ref.global_position.x
	
	match estado:
		Estado.CORRIENDO_HACIA_NPC:
			_mover_hacia(objetivo_x, delta)
			# Si llegamos al NPC, forzar llegada
			if abs(global_position.x - objetivo_x) < 60:
				_llegar_a_npc()
		Estado.SALIENDO:
			_mover_hacia(x_salida, delta)
			if global_position.x <= x_salida:
				_fuera_de_escena()

## Inicia la carrera hacia el NPC
func activar_alarma(npc_node: Node) -> void:
	if estado != Estado.INACTIVO:
		return
	
	_npc_ref = npc_node
	objetivo_x = npc_node.global_position.x  ## Se actualiza en _process en tiempo real
	
	# Cargar sprite de corriendo
	if sprite_corriendo_path and not sprite_corriendo_path.is_empty():
		var tex = load(sprite_corriendo_path)
		if tex:
			sprite.texture = tex
			_ajustar_escala(tex)
	
	# Posicionar fuera de escena
	global_position = Vector2(x_inicio, y_base)
	visible = true
	tiempo_transcurrido = 0.0
	estado = Estado.CORRIENDO_HACIA_NPC
	print("[GUARDIA] ¡Corriendo hacia el NPC!")

## Movimiento con animación de bote (como el NPC)
func _mover_hacia(destino_x: float, delta: float) -> void:
	var direccion = -1.0 if destino_x < global_position.x else 1.0
	global_position.x += direccion * velocidad * delta
	
	# Animación de bote al caminar
	tiempo_transcurrido += delta
	var offset_y = abs(sin(tiempo_transcurrido * frecuencia_bote)) * -altura_bote
	global_position.y = y_base + offset_y

## Detecta colisión con el NPC (Area2D)
func _on_area_entered(area: Area2D) -> void:
	if estado == Estado.CORRIENDO_HACIA_NPC and area == _npc_ref:
		_llegar_a_npc()

## El guardia llegó al NPC
func _llegar_a_npc() -> void:
	if estado == Estado.EN_NPC:
		return  # Ya procesado
	estado = Estado.EN_NPC
	
	# Cambiar sprite a frame2 (agarrando)
	if sprite_frame2_path and not sprite_frame2_path.is_empty():
		var tex = load(sprite_frame2_path)
		if tex:
			sprite.texture = tex
			_ajustar_escala(tex)
	
	print("[GUARDIA] ¡Llegué al NPC! Sprite cambiado a frame2")
	guardia_llego_a_npc.emit()

## Ordena al guardia salir de la escena por la izquierda
func salir_de_escena() -> void:
	estado = Estado.SALIENDO
	tiempo_transcurrido = 0.0
	print("[GUARDIA] Saliendo de escena...")

func _fuera_de_escena() -> void:
	estado = Estado.INACTIVO
	visible = false
	guardia_salio_de_escena.emit()
	print("[GUARDIA] Fuera de escena")

## Ajusta la escala del sprite para un tamaño visual consistente
func _ajustar_escala(tex: Texture2D) -> void:
	var tex_w = float(tex.get_width())
	var tex_h = float(tex.get_height())
	if tex_w <= 0 or tex_h <= 0:
		return
	# Tamaño similar al NPC (220x614 es el estándar del NPC)
	var sx = 220.0 / tex_w
	var sy = 614.0 / tex_h
	var s = min(sx, sy)
	sprite.scale = Vector2(s, s)

## Resetear al estado inicial
func resetear() -> void:
	estado = Estado.INACTIVO
	visible = false
	tiempo_transcurrido = 0.0
	_npc_ref = null
