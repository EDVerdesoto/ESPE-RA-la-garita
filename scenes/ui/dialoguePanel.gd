## Panel de diálogos estilo chat: NPC a la izquierda, Guardia a la derecha
extends Control

signal decision_tomada(decision: int)
signal respuesta_guardia_seleccionada(indice: int, texto: String)
signal incidencia_reportada(campo: int)

@onready var fondo_dialogo: PanelContainer = $FondoDialogo
@onready var lbl_nombre_npc: Label = $FondoDialogo/MarginContainer/VBoxPrincipal/LblNombreNPC
@onready var scroll_chat: ScrollContainer = $FondoDialogo/MarginContainer/VBoxPrincipal/ScrollChat
@onready var chat_container: VBoxContainer = $FondoDialogo/MarginContainer/VBoxPrincipal/ScrollChat/ChatContainer
@onready var contenedor_opciones: VBoxContainer = $FondoDialogo/MarginContainer/VBoxPrincipal/ContenedorOpciones
@onready var btn_aprobar: Button = $PanelDecision/BtnAprobar
@onready var btn_rechazar: Button = $PanelDecision/BtnRechazar
@onready var panel_decision: HBoxContainer = $PanelDecision
@onready var lbl_feedback: Label = $LblFeedback
@onready var panel_reporte: PanelContainer = $PanelReporte
@onready var contenedor_incidencias: VBoxContainer = $PanelReporte/VBox/ContenedorIncidencias

var npc_actual: AbstractNPC = null
var dialogos_actuales: Dictionary = {}
var esperando_respuesta: bool = false

# Colores para las burbujas
const COLOR_NPC = Color(0.18, 0.22, 0.35, 1.0)
const COLOR_GUARDIA = Color(0.12, 0.38, 0.18, 1.0)
const COLOR_TEXTO_NPC = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_TEXTO_GUARDIA = Color(0.85, 1.0, 0.85, 1.0)

func _ready():
	if btn_aprobar:
		btn_aprobar.pressed.connect(_on_aprobar)
	if btn_rechazar:
		btn_rechazar.pressed.connect(_on_rechazar)
	ocultar_todo()

## Crea una burbuja de mensaje estilo chat
func _crear_burbuja(texto: String, es_npc: bool) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_FILL
	
	# Spacer para alinear el mensaje
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2(60, 0)
	
	# Panel burbuja
	var burbuja = PanelContainer.new()
	burbuja.size_flags_horizontal = Control.SIZE_SHRINK_END if not es_npc else Control.SIZE_SHRINK_BEGIN
	burbuja.custom_minimum_size = Vector2(100, 0)
	
	# Estilizar la burbuja
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_NPC if es_npc else COLOR_GUARDIA
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 4 if es_npc else 12
	style.corner_radius_bottom_right = 12 if es_npc else 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	burbuja.add_theme_stylebox_override("panel", style)
	
	# Contenido de la burbuja
	var vbox = VBoxContainer.new()
	
	# Etiqueta de quién habla
	var lbl_quien = Label.new()
	lbl_quien.text = npc_actual.nombre if es_npc else "🛡️ Guardia"
	lbl_quien.add_theme_font_size_override("font_size", 11)
	lbl_quien.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1) if es_npc else Color(0.6, 1.0, 0.7, 1))
	vbox.add_child(lbl_quien)
	
	# Texto del mensaje
	var lbl_msg = Label.new()
	lbl_msg.text = texto
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.custom_minimum_size = Vector2(80, 0)
	lbl_msg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl_msg.add_theme_color_override("font_color", COLOR_TEXTO_NPC if es_npc else COLOR_TEXTO_GUARDIA)
	vbox.add_child(lbl_msg)
	
	burbuja.add_child(vbox)
	
	# NPC a la izquierda, Guardia a la derecha
	if es_npc:
		hbox.add_child(burbuja)
		hbox.add_child(spacer)
	else:
		hbox.add_child(spacer)
		hbox.add_child(burbuja)
	
	if chat_container:
		chat_container.add_child(hbox)
	
	# Auto-scroll hacia abajo
	await get_tree().process_frame
	if scroll_chat:
		scroll_chat.scroll_vertical = scroll_chat.get_v_scroll_bar().max_value

## Agrega un mensaje del NPC al chat
func agregar_mensaje_npc(texto: String) -> void:
	_crear_burbuja(texto, true)

## Agrega un mensaje del guardia al chat
func agregar_mensaje_guardia(texto: String) -> void:
	_crear_burbuja(texto, false)

## Limpia todo el historial del chat
func _limpiar_chat() -> void:
	if chat_container:
		for child in chat_container.get_children():
			child.queue_free()

## Inicializa el panel con los datos del NPC
func configurar_npc(npc: AbstractNPC) -> void:
	npc_actual = npc
	dialogos_actuales = npc.dialogos_ia if npc.dialogos_ia else {}
	
	if lbl_nombre_npc:
		lbl_nombre_npc.text = npc.nombre + " " + npc.apellido
	
	# Limpiar chat anterior
	_limpiar_chat()
	
	# Mostrar saludo inicial
	mostrar_saludo()
	mostrar_botones_decision(true)

## Muestra el saludo/diálogo inicial del NPC
func mostrar_saludo() -> void:
	if fondo_dialogo:
		fondo_dialogo.visible = true
	
	var saludo = ""
	if dialogos_actuales.has("saludo"):
		saludo = dialogos_actuales["saludo"]
	elif dialogos_actuales.has("respuesta_aprobado"):
		saludo = "Buenos días, aquí tiene mi carnet."
	else:
		saludo = "Buenas, vengo a entrar."
	
	agregar_mensaje_npc(saludo)

## Muestra el diálogo cuando el guardia detecta una incidencia correctamente
func mostrar_dialogo_incidencia_correcta() -> void:
	if not dialogos_actuales.has("respuesta_incidencia_correcta"):
		agregar_mensaje_npc("¿Qué? ¿Hay algún problema?")
		return
	
	var resp = dialogos_actuales["respuesta_incidencia_correcta"]
	var mensaje = resp.get("mensaje", "...")
	agregar_mensaje_npc(mensaje)
	
	# Mostrar opciones de respuesta del guardia como botones
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
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx = i
		var texto_guardia = opcion.get("mensaje", "...")
		var resp_npc = opcion.get("respuesta_npc", "...")
		btn.pressed.connect(func():
			# Agregar lo que dijo el guardia como burbuja
			agregar_mensaje_guardia(texto_guardia)
			# Agregar respuesta del NPC
			agregar_mensaje_npc(resp_npc)
			_limpiar_opciones()
			respuesta_guardia_seleccionada.emit(idx, texto_guardia)
		)
		if contenedor_opciones:
			contenedor_opciones.add_child(btn)
	
	esperando_respuesta = true

## Muestra diálogos de incidencia incorrecta
func mostrar_dialogo_incidencia_incorrecta() -> void:
	if not dialogos_actuales.has("respuestas_incidencia_incorrecta"):
		agregar_mensaje_npc("¡Oye! ¿De qué hablas? Mis papeles están en orden.")
		return
	
	var respuestas: Array = dialogos_actuales["respuestas_incidencia_incorrecta"]
	if respuestas.size() > 0:
		agregar_mensaje_npc(respuestas.pick_random())
	else:
		agregar_mensaje_npc("¡No sé de qué me habla!")

## Muestra diálogo de aprobación
func mostrar_dialogo_aprobado() -> void:
	agregar_mensaje_guardia("Puede pasar. Adelante.")
	var texto = dialogos_actuales.get("respuesta_aprobado", "Gracias, que tenga buen día.")
	agregar_mensaje_npc(texto)

## Muestra diálogo de rechazo
func mostrar_dialogo_rechazado() -> void:
	agregar_mensaje_guardia("Lo siento, no puede entrar.")
	var texto = dialogos_actuales.get("respuesta_rechazado", "¡Esto es injusto! Voy a hablar con el decano.")
	agregar_mensaje_npc(texto)

## Muestra feedback al guardia
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

## Muestra el panel de reporte
func mostrar_panel_reporte() -> void:
	if not panel_reporte:
		return
	panel_reporte.visible = true
	_limpiar_incidencias()
	
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
	if fondo_dialogo: fondo_dialogo.visible = false
	if panel_decision: panel_decision.visible = false
	if panel_reporte: panel_reporte.visible = false
	if lbl_feedback: lbl_feedback.visible = false
	_limpiar_chat()
	_limpiar_opciones()
	esperando_respuesta = false

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
