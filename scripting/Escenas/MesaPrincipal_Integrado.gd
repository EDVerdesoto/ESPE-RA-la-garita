# MesaPrincipal_Integrado.gd - Versión integrada con InterfazJuego visual
extends Node2D

# Referencias a nodos de la escena
@onready var sprite_npc = $Estudiante if has_node("Estudiante") else null
@onready var camera = $Camera2D if has_node("Camera2D") else null
var interfaz_juego: CanvasLayer = null

# UI Elements adicionales (para información extendida)
var label_dialogo: RichTextLabel
var panel_documentos: Control

# Control del flujo
var npc_actual: AbstractNPC = null
var index_actual: int = 0
var dinero_acumulado: float = 0.0
var tiempo_restante: int = 480  # 8 horas en minutos
var decisiones_correctas: int = 0
var decisiones_totales: int = 0

func _ready():
	_cargar_interfaz_visual()
	_crear_ui_adicional()
	_cargar_primer_npc()

# Cargar la interfaz visual que creaste
func _cargar_interfaz_visual():
	var interfaz_scene = load("res://escenas/InterfazJuego.tscn")
	if interfaz_scene:
		var instancia = interfaz_scene.instantiate()
		add_child(instancia)
		interfaz_juego = instancia.get_node("InterfazJuego")
		
		# Conectar señales
		interfaz_juego.decision_tomada.connect(_on_decision_tomada)
		interfaz_juego.siguiente_npc_solicitado.connect(_on_siguiente_npc)
		
		print("MesaPrincipal: Interfaz visual cargada correctamente")
	else:
		push_error("No se pudo cargar InterfazJuego.tscn")

func _crear_ui_adicional():
	# Crear CanvasLayer para UI adicional (diálogos y documentos)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UI_Adicional"
	canvas_layer.layer = 2  # Por encima de la interfaz visual
	add_child(canvas_layer)
	
	# Panel de diálogo (arriba)
	var panel_dialogo_container = PanelContainer.new()
	panel_dialogo_container.position = Vector2(20, 20)
	panel_dialogo_container.custom_minimum_size = Vector2(600, 150)
	canvas_layer.add_child(panel_dialogo_container)
	
	label_dialogo = RichTextLabel.new()
	label_dialogo.bbcode_enabled = true
	label_dialogo.fit_content = true
	panel_dialogo_container.add_child(label_dialogo)
	
	# Panel de documentos (derecha)
	panel_documentos = Control.new()
	panel_documentos.position = Vector2(850, 20)
	canvas_layer.add_child(panel_documentos)
	
	var label_docs = Label.new()
	label_docs.text = "DOCUMENTOS:"
	label_docs.add_theme_font_size_override("font_size", 20)
	panel_documentos.add_child(label_docs)

func _cargar_primer_npc():
	if GlobalGameManager.npcs_del_dia.is_empty():
		if interfaz_juego:
			interfaz_juego.ocultar_mesa()
		_mostrar_error_sin_npcs()
		return
	
	index_actual = GlobalGameManager.npc_actual_index
	_mostrar_npc_actual()

func _mostrar_npc_actual():
	if index_actual >= GlobalGameManager.npcs_del_dia.size():
		_mostrar_fin_del_dia()
		return
	
	npc_actual = GlobalGameManager.npcs_del_dia[index_actual]
	
	# Mostrar NPC en la interfaz visual
	if interfaz_juego:
		interfaz_juego.mostrar_npc(npc_actual)
		interfaz_juego.actualizar_reloj(tiempo_restante)
		interfaz_juego.actualizar_dinero(dinero_acumulado)
	
	# Mostrar diálogo inicial
	_mostrar_dialogo_inicial()
	
	# Mostrar documentos
	_mostrar_documentos()
	
	# Actualizar sprite si es posible
	if sprite_npc and npc_actual.sprite_path and ResourceLoader.exists(npc_actual.sprite_path):
		sprite_npc.texture = load(npc_actual.sprite_path)

func _mostrar_dialogo_inicial():
	if not label_dialogo:
		return
		
	# El diálogo viene del JSON de Gemini
	var dialogo_texto = "[b]NPC:[/b] Buenas, vengo a ingresar al campus.\n\n"
	
	if npc_actual.dialogos.has("saludo_inicial"):
		dialogo_texto += npc_actual.dialogos["saludo_inicial"]
	else:
		# Fallback si no hay diálogo de IA
		dialogo_texto += "[i](Este NPC no tiene diálogos de IA generados)[/i]\n"
		dialogo_texto += "Motivo de visita: %s" % npc_actual.carrera
	
	# Mostrar incidencia (solo para debug - en producción esto estaría oculto)
	if OS.is_debug_build() and npc_actual.incidencia != GlobalEnums.Incidencia.NINGUNA:
		dialogo_texto += "\n\n[color=yellow][DEBUG] Incidencia: %s[/color]" % _nombre_incidencia(npc_actual.incidencia)
	
	label_dialogo.text = dialogo_texto

func _mostrar_documentos():
	if not panel_documentos:
		return
		
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

# Señal recibida de la interfaz visual
func _on_decision_tomada(decision: GlobalEnums.NPCState):
	npc_actual.estado = decision
	decisiones_totales += 1
	
	# Evaluar si la decisión fue correcta
	var es_correcto = _evaluar_decision(decision)
	
	if es_correcto:
		decisiones_correctas += 1
		dinero_acumulado += 5.0  # Ganar $5 por decisión correcta
	else:
		dinero_acumulado -= 2.0  # Perder $2 por decisión incorrecta
	
	# Actualizar dinero en la interfaz
	if interfaz_juego:
		interfaz_juego.actualizar_dinero(dinero_acumulado)
		interfaz_juego.mostrar_feedback(es_correcto)
	
	# Mostrar resultado en el diálogo
	_mostrar_resultado_decision(es_correcto, decision)
	
	# Reducir tiempo
	tiempo_restante -= 5  # 5 minutos por decisión

func _mostrar_resultado_decision(es_correcto: bool, decision: GlobalEnums.NPCState):
	if not label_dialogo:
		return
		
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

func _evaluar_decision(decision: GlobalEnums.NPCState) -> bool:
	# Lógica simple: si tiene incidencia, debe ser denegado
	var tiene_incidencia = npc_actual.incidencia != GlobalEnums.Incidencia.NINGUNA
	
	if tiene_incidencia:
		return decision == GlobalEnums.NPCState.DESAPROBADO
	else:
		return decision == GlobalEnums.NPCState.APROBADO

# Señal recibida de la interfaz visual para pasar al siguiente NPC
func _on_siguiente_npc():
	index_actual += 1
	GlobalGameManager.npc_actual_index = index_actual
	_mostrar_npc_actual()

func _mostrar_fin_del_dia():
	if interfaz_juego:
		interfaz_juego.mostrar_fin_dia()
	
	if label_dialogo:
		var tasa_exito = (float(decisiones_correctas) / decisiones_totales * 100) if decisiones_totales > 0 else 0
		
		label_dialogo.text = "[center][b]¡FIN DEL DÍA![/b]\n\n"
		label_dialogo.text += "Has procesado %d NPCs\n" % decisiones_totales
		label_dialogo.text += "Decisiones correctas: %d\n" % decisiones_correctas
		label_dialogo.text += "Tasa de éxito: %.1f%%\n" % tasa_exito
		label_dialogo.text += "Dinero ganado: $%.2f\n\n" % dinero_acumulado
		label_dialogo.text += "[i]¡Buen trabajo![/i][/center]"
	
	if sprite_npc:
		sprite_npc.visible = false

func _mostrar_error_sin_npcs():
	if label_dialogo:
		label_dialogo.text = "[color=red][b]ERROR:[/b] No hay NPCs generados.\n\nLa pantalla de carga no generó NPCs correctamente.\nReinicia el juego.[/color]"

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
