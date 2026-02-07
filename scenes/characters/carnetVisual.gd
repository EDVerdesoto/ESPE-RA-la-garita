## CarnetVisual: Representación visual del carnet universitario
## Es hijo del NPC y tiene campos clickeables para comparación
extends Area2D

class_name CarnetVisual

signal campo_clickeado(campo: int, valor: String)
signal carnet_escaneado(datos_carnet: Dictionary)

## Referencias a nodos visuales del carnet
@onready var sprite_fondo: Sprite2D = $SpriteFondo
@onready var foto_sprite: Sprite2D = $SpriteFondo/FotoSprite
@onready var lbl_nombre: Label = $SpriteFondo/LblNombre
@onready var lbl_apellido: Label = $SpriteFondo/LblApellido
@onready var lbl_carrera: Label = $SpriteFondo/LblCarrera
@onready var lbl_codigo: Label = $SpriteFondo/LblCodigo
@onready var lbl_rol: Label = $SpriteFondo/LblRol

## Áreas clickeables para cada campo
@onready var click_nombre: Area2D = $ClickNombre
@onready var click_apellido: Area2D = $ClickApellido
@onready var click_carrera: Area2D = $ClickCarrera
@onready var click_codigo: Area2D = $ClickCodigo
@onready var click_foto: Area2D = $ClickFoto

## Datos internos del carnet
var datos_carnet: Dictionary = {}
var esta_escaneado: bool = false
var campo_seleccionado: int = GlobalEnums.CampoComparacion.NINGUNO

## Colores para resaltado
var COLOR_NORMAL := Color(1, 1, 1, 1)
var COLOR_RESALTADO := Color(1, 0.85, 0.2, 1)  # Amarillo para campo seleccionado
var COLOR_ERROR := Color(1, 0.3, 0.3, 1)        # Rojo para discrepancia encontrada
var COLOR_OK := Color(0.3, 1, 0.3, 1)           # Verde para coincidencia

func _ready():
	# Conectar señales de click para cada campo
	if click_nombre:
		click_nombre.input_event.connect(_on_click_nombre)
	if click_apellido:
		click_apellido.input_event.connect(_on_click_apellido)
	if click_carrera:
		click_carrera.input_event.connect(_on_click_carrera)
	if click_codigo:
		click_codigo.input_event.connect(_on_click_codigo)
	if click_foto:
		click_foto.input_event.connect(_on_click_foto)
	
	# Click en el carnet completo = escanear
	input_event.connect(_on_carnet_input)

## Configura el carnet con los datos del CarnetUniversitarioNPCConfig
func configurar(config: CarnetUniversitarioNPCConfig) -> void:
	datos_carnet = {
		"nombre": config.nombre,
		"apellido": config.apellido,
		"carrera": config.carrera,
		"codigo_carnet": config.codigo_carnet,
		"rol": config.rol,
		"foto_path": config.foto_path,
	}
	
	# Actualizar labels
	if lbl_nombre:
		lbl_nombre.text = config.nombre
	if lbl_apellido:
		lbl_apellido.text = config.apellido
	if lbl_carrera:
		lbl_carrera.text = config.carrera
	if lbl_codigo:
		lbl_codigo.text = config.codigo_carnet
	if lbl_rol:
		lbl_rol.text = config.rol
	
	# Cargar foto del carnet
	if foto_sprite and config.foto_path and not config.foto_path.is_empty():
		var tex = load(config.foto_path)
		if tex:
			foto_sprite.texture = tex

## Escanear el carnet (click derecho o interacción especial)
func escanear() -> void:
	if esta_escaneado:
		return
	esta_escaneado = true
	print("[CARNET] Escaneado - enviando datos al monitor")
	carnet_escaneado.emit(datos_carnet)

## Resaltar un campo específico
func resaltar_campo(campo: int, color: Color = COLOR_RESALTADO) -> void:
	_resetear_resaltados()
	campo_seleccionado = campo
	match campo:
		GlobalEnums.CampoComparacion.NOMBRE:
			if lbl_nombre: lbl_nombre.modulate = color
		GlobalEnums.CampoComparacion.APELLIDO:
			if lbl_apellido: lbl_apellido.modulate = color
		GlobalEnums.CampoComparacion.CARRERA:
			if lbl_carrera: lbl_carrera.modulate = color
		GlobalEnums.CampoComparacion.CODIGO_CARNET:
			if lbl_codigo: lbl_codigo.modulate = color
		GlobalEnums.CampoComparacion.FOTO:
			if foto_sprite: foto_sprite.modulate = color

## Mostrar resultado de comparación en un campo
func mostrar_resultado(campo: int, resultado: int) -> void:
	var color = COLOR_OK if resultado == GlobalEnums.ResultadoComparacion.COINCIDE else COLOR_ERROR
	resaltar_campo(campo, color)

func _resetear_resaltados() -> void:
	campo_seleccionado = GlobalEnums.CampoComparacion.NINGUNO
	if lbl_nombre: lbl_nombre.modulate = COLOR_NORMAL
	if lbl_apellido: lbl_apellido.modulate = COLOR_NORMAL
	if lbl_carrera: lbl_carrera.modulate = COLOR_NORMAL
	if lbl_codigo: lbl_codigo.modulate = COLOR_NORMAL
	if foto_sprite: foto_sprite.modulate = COLOR_NORMAL

func resetear() -> void:
	_resetear_resaltados()
	esta_escaneado = false
	datos_carnet = {}

# --- INPUT HANDLERS ---

func _on_carnet_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			escanear()

func _on_click_nombre(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		resaltar_campo(GlobalEnums.CampoComparacion.NOMBRE)
		campo_clickeado.emit(GlobalEnums.CampoComparacion.NOMBRE, datos_carnet.get("nombre", ""))

func _on_click_apellido(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		resaltar_campo(GlobalEnums.CampoComparacion.APELLIDO)
		campo_clickeado.emit(GlobalEnums.CampoComparacion.APELLIDO, datos_carnet.get("apellido", ""))

func _on_click_carrera(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		resaltar_campo(GlobalEnums.CampoComparacion.CARRERA)
		campo_clickeado.emit(GlobalEnums.CampoComparacion.CARRERA, datos_carnet.get("carrera", ""))

func _on_click_codigo(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		resaltar_campo(GlobalEnums.CampoComparacion.CODIGO_CARNET)
		campo_clickeado.emit(GlobalEnums.CampoComparacion.CODIGO_CARNET, datos_carnet.get("codigo_carnet", ""))

func _on_click_foto(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		resaltar_campo(GlobalEnums.CampoComparacion.FOTO)
		campo_clickeado.emit(GlobalEnums.CampoComparacion.FOTO, datos_carnet.get("foto_path", ""))
