## PC / Monitor del guardia
## Muestra los datos del sistema (cédula/registro) cuando se escanea un carnet
## Los campos son clickeables para comparar con los del carnet físico
extends Area2D

signal campo_monitor_clickeado(campo: int, valor: String)
signal monitor_encendido()
signal monitor_apagado()

## Estado del monitor
var esta_encendido: bool = false
var datos_mostrados: Dictionary = {}
var campo_seleccionado: int = GlobalEnums.CampoComparacion.NINGUNO

## Referencia al nodo visual del monitor (SubViewport o Control overlay)
@onready var pantalla: Control = $PantallaMonitor
@onready var lbl_titulo: Label = $PantallaMonitor/LblTitulo
@onready var lbl_nombre_sistema: Label = $PantallaMonitor/LblNombreSistema
@onready var lbl_apellido_sistema: Label = $PantallaMonitor/LblApellidoSistema
@onready var lbl_cedula_sistema: Label = $PantallaMonitor/LblCedulaSistema
@onready var lbl_fecha_exp: Label = $PantallaMonitor/LblFechaExp
@onready var lbl_carrera_sistema: Label = $PantallaMonitor/LblCarreraSistema
@onready var lbl_codigo_sistema: Label = $PantallaMonitor/LblCodigoSistema
@onready var foto_sistema: Sprite2D = $PantallaMonitor/FotoSistema

## Áreas clickeables del monitor
@onready var click_nombre_m: Area2D = $PantallaMonitor/ClickNombreM
@onready var click_apellido_m: Area2D = $PantallaMonitor/ClickApellidoM
@onready var click_cedula_m: Area2D = $PantallaMonitor/ClickCedulaM
@onready var click_fecha_m: Area2D = $PantallaMonitor/ClickFechaM
@onready var click_carrera_m: Area2D = $PantallaMonitor/ClickCarreraM
@onready var click_codigo_m: Area2D = $PantallaMonitor/ClickCodigoM
@onready var click_foto_m: Area2D = $PantallaMonitor/ClickFotoM

## Colores
var COLOR_NORMAL := Color(0.0, 1.0, 0.0, 1.0)   # Verde terminal
var COLOR_RESALTADO := Color(1.0, 1.0, 0.0, 1.0)  # Amarillo seleccionado
var COLOR_ERROR := Color(1.0, 0.2, 0.2, 1.0)
var COLOR_OK := Color(0.2, 1.0, 0.2, 1.0)
var COLOR_APAGADO := Color(0.1, 0.1, 0.1, 1.0)

func _ready():
	apagar_monitor()
	_conectar_clicks()

func _conectar_clicks():
	if click_nombre_m:
		click_nombre_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.NOMBRE, "nombre"))
	if click_apellido_m:
		click_apellido_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.APELLIDO, "apellido"))
	if click_cedula_m:
		click_cedula_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.NUMERO_CEDULA, "numero_cedula"))
	if click_fecha_m:
		click_fecha_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.FECHA_EXPIRACION, "fecha_expiracion"))
	if click_carrera_m:
		click_carrera_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.CARRERA, "carrera"))
	if click_codigo_m:
		click_codigo_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.CODIGO_CARNET, "codigo_carnet"))
	if click_foto_m:
		click_foto_m.input_event.connect(func(_vp, ev, _idx):
			_handle_click(ev, GlobalEnums.CampoComparacion.FOTO, "foto_sistema"))

func _handle_click(event: InputEvent, campo: int, key: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not esta_encendido:
			return
		resaltar_campo(campo)
		campo_monitor_clickeado.emit(campo, datos_mostrados.get(key, ""))

## Recibe los datos del sistema del NPC y los muestra en pantalla
## Se llama cuando el carnet es escaneado
func mostrar_datos_sistema(datos_sistema: Dictionary) -> void:
	datos_mostrados = datos_sistema
	esta_encendido = true
	
	if pantalla:
		pantalla.visible = true
	
	# Rellenar los labels con los datos del sistema
	if lbl_titulo:
		lbl_titulo.text = "=== SISTEMA ESPE ==="
		lbl_titulo.modulate = COLOR_NORMAL
	if lbl_nombre_sistema:
		lbl_nombre_sistema.text = "NOMBRE: " + datos_sistema.get("nombre", "N/A")
		lbl_nombre_sistema.modulate = COLOR_NORMAL
	if lbl_apellido_sistema:
		lbl_apellido_sistema.text = "APELLIDO: " + datos_sistema.get("apellido", "N/A")
		lbl_apellido_sistema.modulate = COLOR_NORMAL
	if lbl_cedula_sistema:
		lbl_cedula_sistema.text = "CÉDULA: " + datos_sistema.get("numero_cedula", "N/A")
		lbl_cedula_sistema.modulate = COLOR_NORMAL
	if lbl_fecha_exp:
		lbl_fecha_exp.text = "EXPIRA: " + datos_sistema.get("fecha_expiracion", "N/A")
		lbl_fecha_exp.modulate = COLOR_NORMAL
	if lbl_carrera_sistema:
		lbl_carrera_sistema.text = "CARRERA: " + datos_sistema.get("carrera", "N/A")
		lbl_carrera_sistema.modulate = COLOR_NORMAL
	if lbl_codigo_sistema:
		lbl_codigo_sistema.text = "CÓDIGO: " + datos_sistema.get("codigo_carnet", "N/A")
		lbl_codigo_sistema.modulate = COLOR_NORMAL
	
	# Cargar foto del sistema
	if foto_sistema:
		var foto_path = datos_sistema.get("foto_sistema", "")
		if foto_path and not foto_path.is_empty():
			var tex = load(foto_path)
			if tex:
				foto_sistema.texture = tex
	
	print("[MONITOR] Datos del sistema cargados para: ", datos_sistema.get("nombre", "?"))
	monitor_encendido.emit()

## Resalta un campo en el monitor
func resaltar_campo(campo: int, color: Color = COLOR_RESALTADO) -> void:
	_resetear_resaltados()
	campo_seleccionado = campo
	var label_target: Label = null
	match campo:
		GlobalEnums.CampoComparacion.NOMBRE:
			label_target = lbl_nombre_sistema
		GlobalEnums.CampoComparacion.APELLIDO:
			label_target = lbl_apellido_sistema
		GlobalEnums.CampoComparacion.NUMERO_CEDULA:
			label_target = lbl_cedula_sistema
		GlobalEnums.CampoComparacion.FECHA_EXPIRACION:
			label_target = lbl_fecha_exp
		GlobalEnums.CampoComparacion.CARRERA:
			label_target = lbl_carrera_sistema
		GlobalEnums.CampoComparacion.CODIGO_CARNET:
			label_target = lbl_codigo_sistema
		GlobalEnums.CampoComparacion.FOTO:
			if foto_sistema:
				foto_sistema.modulate = color
	if label_target:
		label_target.modulate = color

## Muestra resultado de comparación
func mostrar_resultado(campo: int, resultado: int) -> void:
	var color = COLOR_OK if resultado == GlobalEnums.ResultadoComparacion.COINCIDE else COLOR_ERROR
	resaltar_campo(campo, color)

func _resetear_resaltados() -> void:
	campo_seleccionado = GlobalEnums.CampoComparacion.NINGUNO
	for lbl in [lbl_nombre_sistema, lbl_apellido_sistema, lbl_cedula_sistema, 
				lbl_fecha_exp, lbl_carrera_sistema, lbl_codigo_sistema]:
		if lbl:
			lbl.modulate = COLOR_NORMAL
	if foto_sistema:
		foto_sistema.modulate = Color.WHITE

func apagar_monitor() -> void:
	esta_encendido = false
	datos_mostrados = {}
	campo_seleccionado = GlobalEnums.CampoComparacion.NINGUNO
	if pantalla:
		pantalla.visible = false
	monitor_apagado.emit()

func resetear() -> void:
	apagar_monitor()
