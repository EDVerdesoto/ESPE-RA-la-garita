## Panel de diálogos y decisión del guardia
## Muestra los diálogos del NPC y las opciones de respuesta/decisión
extends Control

signal decision_tomada(decision: int)
signal respuesta_guardia_seleccionada(indice: int, texto: String)
signal incidencia_reportada(campo: int)

@onready var panel_dialogo: PanelContainer = $PanelDialogo
@onready var lbl_nombre_npc: Label = $PanelDialogo/VBox/LblNombreNPC
@onready var lbl_dialogo: RichTextLabel = $PanelDialogo/VBox/LblDialogo
@onready var contenedor_opciones: VBoxContainer = $PanelDialogo/VBox/ContenedorOpciones
@onready var btn_aprobar: Button = $PanelDecision/HBox/BtnAprobar
@onready var btn_rechazar: Button = $PanelDecision/HBox/BtnRechazar
@onready var panel_decision: HBoxContainer = $PanelDecision/HBox
@onready var lbl_feedback: Label = $LblFeedback

## Panel de reporte de incidencia
@onready var panel_reporte: PanelContainer = $PanelReporte
@onready var contenedor_incidencias: VBoxContainer = $PanelReporte/VBox/ContenedorIncidencias

var npc_actual: AbstractNPC = null
var dialogos_actuales: Dictionary = {}
var esperando_respuesta: bool = false

func _ready():
	if btn_aprobar:
		btn_aprobar.pressed.connect(_on_aprobar)
	if btn_rechazar:
		btn_rechazar.pressed.connect(_on_rechazar)
	ocultar_todo()

## Inicializa el panel con los datos del NPC
func configurar_npc(npc: AbstractNPC) -> void:
	npc_actual = npc
	dialogos_actuales = npc.dialogos_ia if npc.dialogos_ia else {}
	
	if lbl_nombre_npc:
		lbl_nombre_npc.text = npc.nombre + " " + npc.apellido
	
	# Mostrar saludo inicial
	mostrar_saludo()
	mostrar_botones_decision(true)

## Muestra el saludo/diálogo inicial del NPC
func mostrar_saludo() -> void:
	if panel_dialogo:
		panel_dialogo.visible = true
	# El saludo viene de los diálogos generados por IA
	var saludo = ""
	if dialogos_actuales.has("saludo"):
		saludo = dialogos_actuales["saludo"]
	elif dialogos_actuales.has("respuesta_aprobado"):
		saludo = "Buenos días, aquí tiene mi carnet."
	else:
		saludo = "Buenas, vengo a entrar."
	
	if lbl_dialogo:
		lbl_dialogo.text = saludo

## Muestra el diálogo cuando el guardia detecta una incidencia correctamente
func mostrar_dialogo_incidencia_correcta() -> void:
	if not dialogos_actuales.has("respuesta_incidencia_correcta"):
		_mostrar_texto("¿Qué? ¿Hay algún problema?")
		return
	
	var resp = dialogos_actuales["respuesta_incidencia_correcta"]
	var mensaje = resp.get("mensaje", "...")
	_mostrar_texto(mensaje)
	
	# Mostrar opciones de respuesta del guardia
	_limpiar_opciones()
	var opciones_guardia = [
		resp.get("posible_res_guardia1", {}),
		resp.get("posible_res_guardia2", {}),
		resp.get("posible_res_guardia3", {}),
	]
	
	for i in range(opciones_guardia.size()):
		var opcion = opciones_guardia[i]
		if opcion.is_empty():
			continue
		var btn = Button.new()
		btn.text = opcion.get("mensaje", "...")
		var idx = i
		var resp_npc = opcion.get("respuesta_npc", "...")
		btn.pressed.connect(func():
			_mostrar_texto(resp_npc)
			_limpiar_opciones()
			respuesta_guardia_seleccionada.emit(idx, btn.text)
		)
		if contenedor_opciones:
			contenedor_opciones.add_child(btn)
	
	esperando_respuesta = true

## Muestra diálogos de incidencia incorrecta (el guardia acusó algo equivocado)
func mostrar_dialogo_incidencia_incorrecta() -> void:
	if not dialogos_actuales.has("respuestas_incidencia_incorrecta"):
		_mostrar_texto("¡Oye! ¿De qué hablas? Mis papeles están en orden.")
		return
	
	var respuestas: Array = dialogos_actuales["respuestas_incidencia_incorrecta"]
	if respuestas.size() > 0:
		_mostrar_texto(respuestas.pick_random())
	else:
		_mostrar_texto("¡No sé de qué me habla!")

## Muestra diálogo de aprobación
func mostrar_dialogo_aprobado() -> void:
	var texto = dialogos_actuales.get("respuesta_aprobado", "Gracias, que tenga buen día.")
	_mostrar_texto(texto)

## Muestra diálogo de rechazo
func mostrar_dialogo_rechazado() -> void:
	var texto = dialogos_actuales.get("respuesta_rechazado", "¡Esto es injusto! Voy a hablar con el decano.")
	_mostrar_texto(texto)

## Muestra feedback al guardia sobre si su decisión fue correcta
func mostrar_feedback(resultado: Dictionary) -> void:
	if not lbl_feedback:
		return
	lbl_feedback.visible = true
	if resultado.get("correcta", false):
		lbl_feedback.text = "✓ DECISIÓN CORRECTA (+$%.0f)" % GlobalGameManager.pago_por_acierto
		lbl_feedback.modulate = Color(0.2, 1.0, 0.2)
	else:
		var incidencia_real = resultado.get("incidencia_real", 0)
		lbl_feedback.text = "✗ DECISIÓN INCORRECTA (-$%.0f)" % GlobalGameManager.multa_por_error
		if incidencia_real != GlobalEnums.Incidencia.NINGUNA:
			lbl_feedback.text += "\nIncidencia: " + _nombre_incidencia(incidencia_real)
		lbl_feedback.modulate = Color(1.0, 0.2, 0.2)

## Muestra el panel de reporte donde el guardia selecciona qué incidencia encontró
func mostrar_panel_reporte() -> void:
	if not panel_reporte:
		return
	panel_reporte.visible = true
	_limpiar_incidencias()
	
	# Crear botones para cada tipo de incidencia reportable
	var incidencias_reportables = [
		{ "id": GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE, "texto": "Nombre en cédula no coincide" },
		{ "id": GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE, "texto": "Nombre en carnet no coincide" },
		{ "id": GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA, "texto": "Cédula caducada" },
		{ "id": GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE, "texto": "Foto del carnet no coincide" },
		{ "id": GlobalEnums.Incidencia.CARRERA_DIFERENTE, "texto": "Carrera no coincide" },
		{ "id": GlobalEnums.Incidencia.SOSPECHOSO, "texto": "Persona sospechosa" },
	]
	
	for inc in incidencias_reportables:
		var btn = Button.new()
		btn.text = inc["texto"]
		var inc_id = inc["id"]
		btn.pressed.connect(func():
			incidencia_reportada.emit(inc_id)
			panel_reporte.visible = false
		)
		if contenedor_incidencias:
			contenedor_incidencias.add_child(btn)

func mostrar_botones_decision(mostrar: bool) -> void:
	if panel_decision:
		panel_decision.visible = mostrar

func ocultar_todo() -> void:
	if panel_dialogo: panel_dialogo.visible = false
	if panel_decision: panel_decision.visible = false
	if panel_reporte: panel_reporte.visible = false
	if lbl_feedback: lbl_feedback.visible = false
	esperando_respuesta = false

func _mostrar_texto(texto: String) -> void:
	if lbl_dialogo:
		lbl_dialogo.text = texto

func _limpiar_opciones() -> void:
	if contenedor_opciones:
		for child in contenedor_opciones.get_children():
			child.queue_free()

func _limpiar_incidencias() -> void:
	if contenedor_incidencias:
		for child in contenedor_incidencias.get_children():
			child.queue_free()

func _on_aprobar() -> void:
	mostrar_botones_decision(false)
	decision_tomada.emit(GlobalEnums.DecisionGuardia.APROBADO)

func _on_rechazar() -> void:
	mostrar_botones_decision(false)
	# Antes de rechazar, mostrar panel de reporte para que elija el motivo
	mostrar_panel_reporte()

func _nombre_incidencia(inc: int) -> String:
	match inc:
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE: return "Nombre cédula diferente"
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE: return "Nombre carnet diferente"
		GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA: return "Cédula caducada"
		GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE: return "Foto no coincide"
		GlobalEnums.Incidencia.CARRERA_DIFERENTE: return "Carrera diferente"
		GlobalEnums.Incidencia.CARNET_OLVIDADO: return "No tiene carnet"
		GlobalEnums.Incidencia.CEDULA_OLVIDADA: return "No tiene cédula"
		GlobalEnums.Incidencia.SOSPECHOSO: return "Sospechoso"
	return "Desconocida"
