## UI: Panel unificado — HUD + Diálogos + Decisiones + Reporte
## Layout: TopBar | Chat(izq) + Opciones(der) | Botones en esquinas
extends CanvasLayer

signal decision_tomada(decision: int)
signal respuesta_guardia_seleccionada(indice: int, texto: String)
signal incidencia_reportada(campo: int)

# --- TOP BAR / HUD ---
@onready var main_layout: Control = $MainLayout
@onready var top_bar_texture: TextureRect = $MainLayout/TopBar/TopBarTexture
@onready var lbl_dia: Label = $MainLayout/TopBar/TopBarMargin/TopBarHBox/LblDia
@onready var lbl_dinero: Label = $MainLayout/TopBar/TopBarMargin/TopBarHBox/LblDinero
@onready var lbl_aciertos: Label = $MainLayout/TopBar/TopBarMargin/TopBarHBox/LblAciertos
@onready var lbl_errores: Label = $MainLayout/TopBar/TopBarMargin/TopBarHBox/LblErrores

# --- Chat flotante (izquierda) ---
@onready var chat_panel: PanelContainer = $MainLayout/ChatPanel
@onready var lbl_nombre_npc: Label = $MainLayout/ChatPanel/ChatMargin/ChatVBox/LblNombreNPC
@onready var scroll_chat: ScrollContainer = $MainLayout/ChatPanel/ChatMargin/ChatVBox/ScrollChat
@onready var chat_container: VBoxContainer = $MainLayout/ChatPanel/ChatMargin/ChatVBox/ScrollChat/ChatContainer

# --- Opciones flotante (derecha) ---
@onready var options_panel: PanelContainer = $MainLayout/OptionsPanel
@onready var contenedor_opciones: VBoxContainer = $MainLayout/OptionsPanel/OptionsMargin/OptionsVBox/ContenedorOpciones

# --- Botones de acción (esquinas inferiores) ---
@onready var btn_aprobar: TextureButton = $MainLayout/BtnAprobar
@onready var btn_rechazar: TextureButton = $MainLayout/BtnRechazar

# --- Reporte ---
@onready var panel_reporte: PanelContainer = $MainLayout/PanelReporte
@onready var contenedor_incidencias: VBoxContainer = $MainLayout/PanelReporte/ReporteMargin/VBox/ContenedorIncidencias

# --- Feedback ---
@onready var lbl_feedback: Label = $MainLayout/LblFeedback

# --- Estado ---
var npc_actual: AbstractNPC = null
var dialogos_actuales: Dictionary = {}
var esperando_respuesta: bool = false

# Colores para las burbujas
const COLOR_NPC = Color(0.15, 0.18, 0.28, 1.0)
const COLOR_GUARDIA = Color(0.1, 0.3, 0.15, 1.0)
const COLOR_TEXTO_NPC = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_TEXTO_GUARDIA = Color(0.85, 1.0, 0.85, 1.0)

func _ready():
	if btn_aprobar:
		btn_aprobar.pressed.connect(_on_aprobar)
	if btn_rechazar:
		btn_rechazar.pressed.connect(_on_rechazar)
	main_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ocultar_todo()

# =====================================================
# HUD
# =====================================================

func actualizar(datos: Dictionary) -> void:
	if lbl_dia:
		lbl_dia.text = "DÍA " + str(datos.get("dia", 1))
	if lbl_dinero:
		lbl_dinero.text = "$" + str(datos.get("dinero", 0.0))
	if lbl_aciertos:
		lbl_aciertos.text = "✓ " + str(datos.get("aciertos", 0))
	if lbl_errores:
		lbl_errores.text = "✗ " + str(datos.get("errores", 0))

# =====================================================
# BURBUJAS DE CHAT (panel izquierdo)
# =====================================================

func _crear_burbuja(texto: String, es_npc: bool) -> void:
	_limpiar_chat()
	var burbuja = PanelContainer.new()
	burbuja.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_NPC if es_npc else COLOR_GUARDIA
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 4 if es_npc else 10
	style.corner_radius_bottom_right = 10 if es_npc else 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	burbuja.add_theme_stylebox_override("panel", style)

	var lbl_msg = Label.new()
	lbl_msg.text = texto
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_msg.add_theme_color_override("font_color", COLOR_TEXTO_NPC if es_npc else COLOR_TEXTO_GUARDIA)
	burbuja.add_child(lbl_msg)

	if chat_container:
		chat_container.add_child(burbuja)

	await get_tree().process_frame
	if scroll_chat:
		scroll_chat.scroll_vertical = scroll_chat.get_v_scroll_bar().max_value

func agregar_mensaje_npc(texto: String) -> void:
	_crear_burbuja(texto, true)

func agregar_mensaje_guardia(texto: String) -> void:
	_crear_burbuja(texto, false)

func _limpiar_chat() -> void:
	if chat_container:
		for child in chat_container.get_children():
			child.queue_free()

# =====================================================
# CONFIGURACIÓN DE NPC
# =====================================================

func configurar_npc(npc: AbstractNPC) -> void:
	npc_actual = npc
	dialogos_actuales = npc.dialogos_ia if npc.dialogos_ia else {}

	if lbl_nombre_npc:
		lbl_nombre_npc.text = npc.nombre + " " + npc.apellido

	_limpiar_chat()
	_limpiar_opciones()

	# Mostrar chat flotante, opciones ocultas hasta incidencia
	if chat_panel:
		chat_panel.visible = true
	if options_panel:
		options_panel.visible = false

	mostrar_saludo()
	mostrar_botones_decision(true)

func mostrar_saludo() -> void:
	var saludo = ""
	if dialogos_actuales.has("saludo"):
		saludo = dialogos_actuales["saludo"]
	elif dialogos_actuales.has("respuesta_aprobado"):
		saludo = "Buenos días, aquí tiene mi carnet."
	else:
		saludo = "Buenas, vengo a entrar."

	agregar_mensaje_npc(saludo)

# =====================================================
# COMPARACIONES: FEEDBACK VISUAL Y DIÁLOGOS
# =====================================================

## Muestra feedback cuando una comparación de campos COINCIDE (no hay discrepancia)
## El guardia verifica y el NPC responde brevemente con actitud
func mostrar_comparacion_coincide(campo: int) -> void:
	agregar_mensaje_npc(_obtener_respuesta_campo_ok())

## Muestra feedback cuando se encuentra una DISCREPANCIA entre carnet y sistema
## El guardia confronta → NPC reacciona → aparecen opciones de respuesta del guardia
func mostrar_discrepancia_encontrada(campo: int, val_carnet: String, val_sistema: String) -> void:
	mostrar_dialogo_incidencia_correcta()

func _obtener_respuesta_campo_ok() -> String:
	# Usar diálogos de IA si están disponibles
	if dialogos_actuales.has("respuestas_incidencia_incorrecta"):
		var respuestas: Array = dialogos_actuales["respuestas_incidencia_incorrecta"]
		if respuestas.size() > 0:
			return respuestas.pick_random()
	# Respuestas por defecto si no hay IA
	var defaults = [
		"¿Ve? Todo en orden, jefe.",
		"Eso está bien, ¿no? Revise nomás.",
		"¿Algún problema con eso?",
		"Todo correcto ahí, siga revisando.",
		"Ahí no hay nada raro, ¿o sí?",
	]
	return defaults.pick_random()

func _nombre_campo_comparacion(campo: int) -> String:
	match campo:
		GlobalEnums.CampoComparacion.NOMBRE: return "NOMBRE"
		GlobalEnums.CampoComparacion.APELLIDO: return "APELLIDO"
		GlobalEnums.CampoComparacion.FOTO: return "FOTO"
		GlobalEnums.CampoComparacion.CODIGO_CARNET: return "CÓDIGO"
		GlobalEnums.CampoComparacion.CARRERA: return "CARRERA"
		GlobalEnums.CampoComparacion.NUMERO_CEDULA: return "CÉDULA"
		GlobalEnums.CampoComparacion.FECHA_EXPIRACION: return "FECHA"
	return "CAMPO"

# =====================================================
# DIÁLOGOS DE INCIDENCIA
# =====================================================

func mostrar_dialogo_incidencia_correcta() -> void:
	if not dialogos_actuales.has("respuesta_incidencia_correcta"):
		agregar_mensaje_npc("¿Qué? ¿Hay algún problema?")
		_mostrar_opciones_default()
		return

	var resp = dialogos_actuales["respuesta_incidencia_correcta"]
	var mensaje = resp.get("mensaje", "...")
	agregar_mensaje_npc(mensaje)

	# Mostrar panel de opciones a la derecha
	_limpiar_opciones()
	if options_panel:
		options_panel.visible = true

	var opciones_guardia = [
		resp.get("posible_res_guardia1", {}),
		resp.get("posible_res_guardia2", {}),
		resp.get("posible_res_guardia3", {}),
	]

	for i in range(opciones_guardia.size()):
		var opcion = opciones_guardia[i]
		if opcion.is_empty():
			continue
		var btn = _crear_boton_opcion(opcion.get("mensaje", "..."))
		var idx = i
		var texto_guardia = opcion.get("mensaje", "...")
		var resp_npc = opcion.get("respuesta_npc", "...")
		btn.pressed.connect(func():
			agregar_mensaje_guardia(texto_guardia)
			agregar_mensaje_npc(resp_npc)
			_limpiar_opciones()
			if options_panel:
				options_panel.visible = false
			respuesta_guardia_seleccionada.emit(idx, texto_guardia)
		)
		if contenedor_opciones:
			contenedor_opciones.add_child(btn)

	esperando_respuesta = true

## Opciones de respuesta por defecto si no hay diálogos de IA disponibles
func _mostrar_opciones_default() -> void:
	_limpiar_opciones()
	if options_panel:
		options_panel.visible = true
	var opciones_default = [
		{"mensaje": "¡Esto es falso! No puede pasar.", "respuesta": "¡No es falso! ¡Revise bien!"},
		{"mensaje": "Disculpe, hay un error en sus datos.", "respuesta": "¿Error? ¿Cómo así? Déjeme ver..."},
		{"mensaje": "Según el reglamento, esto no está en orden.", "respuesta": "¿Qué reglamento? Yo solo quiero entrar..."},
	]
	for i in range(opciones_default.size()):
		var opcion = opciones_default[i]
		var btn = _crear_boton_opcion(opcion["mensaje"])
		var idx = i
		var texto_g = opcion["mensaje"]
		var resp_n = opcion["respuesta"]
		btn.pressed.connect(func():
			agregar_mensaje_guardia(texto_g)
			agregar_mensaje_npc(resp_n)
			_limpiar_opciones()
			if options_panel:
				options_panel.visible = false
			respuesta_guardia_seleccionada.emit(idx, texto_g)
		)
		if contenedor_opciones:
			contenedor_opciones.add_child(btn)
	esperando_respuesta = true

## Crea un botón estilizado para las opciones de respuesta del guardia
func _crear_boton_opcion(texto: String) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 40)

	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.1, 0.22, 0.12, 0.9)
	style_n.corner_radius_top_left = 8
	style_n.corner_radius_top_right = 8
	style_n.corner_radius_bottom_left = 8
	style_n.corner_radius_bottom_right = 8
	style_n.content_margin_left = 10
	style_n.content_margin_right = 10
	style_n.content_margin_top = 8
	style_n.content_margin_bottom = 8
	style_n.border_width_left = 1
	style_n.border_width_top = 1
	style_n.border_width_right = 1
	style_n.border_width_bottom = 1
	style_n.border_color = Color(0.3, 0.6, 0.35, 0.5)
	btn.add_theme_stylebox_override("normal", style_n)

	var style_h = style_n.duplicate()
	style_h.bg_color = Color(0.15, 0.35, 0.18, 0.95)
	style_h.border_color = Color(0.4, 0.8, 0.45, 0.8)
	btn.add_theme_stylebox_override("hover", style_h)

	var style_p = style_n.duplicate()
	style_p.bg_color = Color(0.08, 0.18, 0.1, 0.95)
	btn.add_theme_stylebox_override("pressed", style_p)

	btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

	return btn

func mostrar_dialogo_incidencia_incorrecta() -> void:
	if not dialogos_actuales.has("respuestas_incidencia_incorrecta"):
		agregar_mensaje_npc("¡Oye! ¿De qué hablas? Mis papeles están en orden.")
		return

	var respuestas: Array = dialogos_actuales["respuestas_incidencia_incorrecta"]
	if respuestas.size() > 0:
		agregar_mensaje_npc(respuestas.pick_random())
	else:
		agregar_mensaje_npc("¡No sé de qué me habla!")

func mostrar_dialogo_aprobado() -> void:
	agregar_mensaje_guardia("Puede pasar. Adelante.")
	var texto = dialogos_actuales.get("respuesta_aprobado", "Gracias, que tenga buen día.")
	agregar_mensaje_npc(texto)

func mostrar_dialogo_rechazado() -> void:
	agregar_mensaje_guardia("Lo siento, no puede entrar.")
	var texto = dialogos_actuales.get("respuesta_rechazado", "¡Esto es injusto! Voy a hablar con el decano.")
	agregar_mensaje_npc(texto)

# =====================================================
# FEEDBACK Y REPORTE
# =====================================================

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
		var btn = _crear_boton_reporte(inc["texto"])
		var inc_id = inc["id"]
		btn.pressed.connect(func():
			incidencia_reportada.emit(inc_id)
			panel_reporte.visible = false
		)
		if contenedor_incidencias:
			contenedor_incidencias.add_child(btn)

## Crea un botón estilizado para el panel de reporte
func _crear_boton_reporte(texto: String) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 36)

	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.22, 0.1, 0.1, 0.9)
	style_n.corner_radius_top_left = 6
	style_n.corner_radius_top_right = 6
	style_n.corner_radius_bottom_left = 6
	style_n.corner_radius_bottom_right = 6
	style_n.content_margin_left = 8
	style_n.content_margin_right = 8
	style_n.content_margin_top = 6
	style_n.content_margin_bottom = 6
	style_n.border_width_left = 1
	style_n.border_width_top = 1
	style_n.border_width_right = 1
	style_n.border_width_bottom = 1
	style_n.border_color = Color(0.6, 0.2, 0.2, 0.5)
	btn.add_theme_stylebox_override("normal", style_n)

	var style_h = style_n.duplicate()
	style_h.bg_color = Color(0.35, 0.12, 0.12, 0.95)
	style_h.border_color = Color(0.8, 0.3, 0.3, 0.8)
	btn.add_theme_stylebox_override("hover", style_h)

	btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

	return btn

# =====================================================
# CONTROL DE VISIBILIDAD
# =====================================================

func mostrar_botones_decision(mostrar: bool) -> void:
	if btn_aprobar:
		btn_aprobar.visible = mostrar
	if btn_rechazar:
		btn_rechazar.visible = mostrar

func ocultar_todo() -> void:
	if chat_panel: chat_panel.visible = false
	if options_panel: options_panel.visible = false
	if btn_aprobar: btn_aprobar.visible = false
	if btn_rechazar: btn_rechazar.visible = false
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
