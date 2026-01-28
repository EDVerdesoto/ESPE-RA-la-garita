# MesaPrincipal.gd
extends Node2D

# Referencias a nodos de la escena
@onready var sprite_npc = $Estudiante
@onready var camera = $Camera2D

# UI Elements (crearemos estos nodos después)
var label_nombre: Label
var label_info: Label
var label_dialogo: RichTextLabel
var btn_aprobar: Button
var btn_denegar: Button
var btn_siguiente: Button
var panel_documentos: Control

# Control del flujo
var npc_actual: AbstractNPC = null
var index_actual: int = 0

func _ready():
	_crear_ui_basica()
	_cargar_primer_npc()

func _crear_ui_basica():
	# Crear CanvasLayer para UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UI"
	add_child(canvas_layer)
	
	# Panel principal de información
	var panel_info = PanelContainer.new()
	panel_info.position = Vector2(20, 20)
	panel_info.custom_minimum_size = Vector2(400, 200)
	canvas_layer.add_child(panel_info)
	
	var vbox_info = VBoxContainer.new()
	panel_info.add_child(vbox_info)
	
	# Label del nombre
	label_nombre = Label.new()
	label_nombre.add_theme_font_size_override("font_size", 24)
	vbox_info.add_child(label_nombre)
	
	# Label de info básica
	label_info = Label.new()
	label_info.add_theme_font_size_override("font_size", 16)
	vbox_info.add_child(label_info)
	
	# Panel de diálogo
	var panel_dialogo = PanelContainer.new()
	panel_dialogo.position = Vector2(20, 240)
	panel_dialogo.custom_minimum_size = Vector2(600, 300)
	canvas_layer.add_child(panel_dialogo)
	
	label_dialogo = RichTextLabel.new()
	label_dialogo.bbcode_enabled = true
	label_dialogo.fit_content = true
	panel_dialogo.add_child(label_dialogo)
	
	# Botones de decisión
	var hbox_botones = HBoxContainer.new()
	hbox_botones.position = Vector2(20, 560)
	hbox_botones.add_theme_constant_override("separation", 20)
	canvas_layer.add_child(hbox_botones)
	
	btn_aprobar = Button.new()
	btn_aprobar.text = "✓ APROBAR ENTRADA"
	btn_aprobar.custom_minimum_size = Vector2(200, 50)
	btn_aprobar.add_theme_font_size_override("font_size", 18)
	btn_aprobar.pressed.connect(_on_aprobar_pressed)
	hbox_botones.add_child(btn_aprobar)
	
	btn_denegar = Button.new()
	btn_denegar.text = "✗ DENEGAR ENTRADA"
	btn_denegar.custom_minimum_size = Vector2(200, 50)
	btn_denegar.add_theme_font_size_override("font_size", 18)
	btn_denegar.pressed.connect(_on_denegar_pressed)
	hbox_botones.add_child(btn_denegar)
	
	btn_siguiente = Button.new()
	btn_siguiente.text = "→ SIGUIENTE NPC"
	btn_siguiente.custom_minimum_size = Vector2(200, 50)
	btn_siguiente.add_theme_font_size_override("font_size", 18)
	btn_siguiente.visible = false
	btn_siguiente.pressed.connect(_on_siguiente_pressed)
	hbox_botones.add_child(btn_siguiente)
	
	# Panel de documentos (a la derecha)
	panel_documentos = Control.new()
	panel_documentos.position = Vector2(640, 20)
	canvas_layer.add_child(panel_documentos)
	
	var label_docs = Label.new()
	label_docs.text = "DOCUMENTOS:"
	label_docs.add_theme_font_size_override("font_size", 20)
	panel_documentos.add_child(label_docs)

func _cargar_primer_npc():
	if GlobalGameManager.npcs_del_dia.is_empty():
		label_nombre.text = "NO HAY NPCs GENERADOS"
		label_info.text = "La pantalla de carga no generó NPCs correctamente."
		label_dialogo.text = "[color=red]Error: Lista de NPCs vacía. Reinicia el juego.[/color]"
		btn_aprobar.disabled = true
		btn_denegar.disabled = true
		return
	
	index_actual = GlobalGameManager.npc_actual_index
	_mostrar_npc_actual()

func _mostrar_npc_actual():
	if index_actual >= GlobalGameManager.npcs_del_dia.size():
		_mostrar_fin_del_dia()
		return
	
	npc_actual = GlobalGameManager.npcs_del_dia[index_actual]
	
	# Actualizar información básica
	label_nombre.text = "%s %s" % [npc_actual.nombre, npc_actual.apellido]
	label_info.text = "Rol: %s | Carrera: %s\nPersonalidad: %s" % [
		npc_actual.rol,
		npc_actual.carrera,
		npc_actual.personalidad
	]
	
	# Mostrar diálogo inicial
	_mostrar_dialogo_inicial()
	
	# Mostrar documentos
	_mostrar_documentos()
	
	# Actualizar sprite si es posible
	if npc_actual.sprite_path and ResourceLoader.exists(npc_actual.sprite_path):
		sprite_npc.texture = load(npc_actual.sprite_path)
	
	# Habilitar botones
	btn_aprobar.disabled = false
	btn_denegar.disabled = false
	btn_aprobar.visible = true
	btn_denegar.visible = true
	btn_siguiente.visible = false

func _mostrar_dialogo_inicial():
	# El diálogo viene del JSON de Gemini
	var dialogo_texto = "[b]NPC:[/b] Buenas, vengo a ingresar al campus.\n\n"
	
	if npc_actual.dialogos.has("saludo_inicial"):
		dialogo_texto += npc_actual.dialogos["saludo_inicial"]
	else:
		# Fallback si no hay diálogo de IA
		dialogo_texto += "[i](Este NPC no tiene diálogos de IA generados)[/i]\n"
		dialogo_texto += "Motivo de visita: %s" % npc_actual.carrera
	
	# Mostrar incidencia (solo para debug - en producción esto estaría oculto)
	if npc_actual.incidencia != GlobalEnums.Incidencia.NINGUNA:
		dialogo_texto += "\n\n[color=yellow][DEBUG] Incidencia: %s[/color]" % _nombre_incidencia(npc_actual.incidencia)
	
	label_dialogo.text = dialogo_texto

func _mostrar_documentos():
	# Limpiar panel anterior
	for child in panel_documentos.get_children():
		if child.name != "Label":
			child.queue_free()
	
	var y_offset = 40
	var doc_index = 1
	
	for doc in npc_actual.documentos:
		var label = Label.new()
		label.position = Vector2(0, y_offset)
		
		if doc is Cedula:
			var config = doc.configuracion as CedulaNPCConfig
			label.text = "📋 Cédula: %s %s\nNúmero: %s\nVence: %s" % [config.nombre, config.apellido, config.numero_cedula, config.fecha_expiracion]
		elif doc is CarnetUniversitario:
			var config = doc.configuracion as CarnetUniversitarioNPCConfig
			label.text = "🎓 Carnet: %s %s\nCarrera: %s\nRol: %s" % [config.nombre, config.apellido, config.carrera, config.rol]
		elif doc is PaseVisitante:
			var config = doc.configuracion as PaseVisitanteNPCConfig
			label.text = "👤 Pase Visitante: %s %s\nRazón: %s" % [config.nombre, config.apellido, config.razon]
		else:
			label.text = "📄 Documento %d" % doc_index
		
		panel_documentos.add_child(label)
		y_offset += 80
		doc_index += 1

func _on_aprobar_pressed():
	_procesar_decision(GlobalEnums.NPCState.APROBADO)

func _on_denegar_pressed():
	_procesar_decision(GlobalEnums.NPCState.DESAPROBADO)

func _procesar_decision(decision: int):
	npc_actual.estado = decision
	
	# Evaluar si la decisión fue correcta
	var es_correcto = _evaluar_decision(decision)
	
	# Mostrar resultado
	var resultado_texto = ""
	if es_correcto:
		resultado_texto = "[color=green][b]✓ DECISIÓN CORRECTA[/b][/color]\n\n"
	else:
		resultado_texto = "[color=red][b]✗ DECISIÓN INCORRECTA[/b][/color]\n\n"
	
	# Agregar diálogo de respuesta del NPC si existe
	if npc_actual.dialogos.has("respuesta_decision"):
		resultado_texto += npc_actual.dialogos["respuesta_decision"]
	else:
		if decision == GlobalEnums.NPCState.APROBADO:
			resultado_texto += "Muchas gracias, que tenga buen día."
		else:
			resultado_texto += "¿Por qué me niega la entrada? Esto es indignante."
	
	label_dialogo.text = resultado_texto
	
	# Ocultar botones de decisión, mostrar siguiente
	btn_aprobar.visible = false
	btn_denegar.visible = false
	btn_siguiente.visible = true

func _evaluar_decision(decision: int) -> bool:
	# Lógica simple: si tiene incidencia, debe ser denegado
	var tiene_incidencia = npc_actual.incidencia != GlobalEnums.Incidencia.NINGUNA
	
	if tiene_incidencia:
		return decision == GlobalEnums.NPCState.DESAPROBADO
	else:
		return decision == GlobalEnums.NPCState.APROBADO

func _on_siguiente_pressed():
	index_actual += 1
	GlobalGameManager.npc_actual_index = index_actual
	_mostrar_npc_actual()

func _mostrar_fin_del_dia():
	label_nombre.text = "FIN DEL DÍA"
	label_info.text = "Has procesado todos los NPCs de hoy"
	label_dialogo.text = "[center][b]¡Buen trabajo![/b]\n\nHas terminado tu turno.\n\n[i]Aquí iría el resumen de estadísticas[/i][/center]"
	btn_aprobar.visible = false
	btn_denegar.visible = false
	btn_siguiente.visible = false
	sprite_npc.visible = false

func _nombre_incidencia(inc: int) -> String:
	match inc:
		GlobalEnums.Incidencia.NINGUNA: return "Ninguna"
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE: return "Nombre en cédula diferente"
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE: return "Nombre en carnet diferente"
		GlobalEnums.Incidencia.NOMBRE_PASE_DIFERENTE: return "Nombre en pase diferente"
		GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA: return "Cédula caducada"
		GlobalEnums.Incidencia.CEDULA_OLVIDADA: return "Cédula olvidada"
		GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE: return "Foto de carnet diferente"
		GlobalEnums.Incidencia.CARNET_OLVIDADO: return "Carnet olvidado"
		GlobalEnums.Incidencia.CARRERA_DIFERENTE: return "Carrera diferente"
		GlobalEnums.Incidencia.PASE_VISITANTE_OLVIDADO: return "Pase olvidado"
		GlobalEnums.Incidencia.SOSPECHOSO: return "Sospechoso"
		_: return "Desconocida"
