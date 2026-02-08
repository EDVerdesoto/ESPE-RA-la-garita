extends Node

# Señal que emite cuando Gemini termina de procesar el lote y devuelve el JSON
# Devuelve un Array de Diccionarios con la estructura de diálogos
signal batch_completed(dialogos_array: Array)
signal error_ocurred(mensaje: String)

# CONFIGURACIÓN
var API_KEY: String = ""
var URL: String = ""

@onready var http_request = HTTPRequest.new()

func _ready():
	# Cargar la API key desde el archivo .env
	_cargar_api_key()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Función para leer el archivo .env y cargar la API key
func _cargar_api_key():
	var env_path = "res://.env"
	var file = FileAccess.open(env_path, FileAccess.READ)
	
	if file == null:
		push_error("[GEMINI] No se encontró el archivo .env en la raíz del proyecto")
		error_ocurred.emit("No se encontró el archivo .env")
		return
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		# Ignorar líneas vacías y comentarios
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# Buscar la variable GEMINI_API_KEY
		if line.begins_with("GEMINI_API_KEY="):
			API_KEY = line.replace("GEMINI_API_KEY=", "")
			URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + API_KEY
			print("[GEMINI] API Key cargada correctamente")
			break
	
	file.close()
	
	if API_KEY.is_empty():
		push_error("[GEMINI] No se encontró GEMINI_API_KEY en el archivo .env")
		error_ocurred.emit("No se encontró GEMINI_API_KEY en .env")

# --- FUNCIÓN PRINCIPAL ---
# Recibe un Array de objetos NPC (AbstractNPC) y el String del clima
func solicitar_dialogos_batch(lista_npcs: Array, clima_actual: String):
	print("[GEMINI] Iniciando solicitud para %d NPCs" % lista_npcs.size())
	
	# 1. Convertimos los objetos NPC a datos simples para el Prompt
	var datos_para_prompt = []
	
	for npc in lista_npcs:
		# Lógica para determinar el "Secreto" según si es Delincuente o no
		var verdad_oculta = ""
		var intencion = ""
		
		# Verificamos si es una instancia de la clase Delincuente
		# (Asumiendo que tienes la herencia configurada como hablamos)
		if "tipo_amenaza" in npc and npc.tipo_amenaza != "":
			verdad_oculta = "CRIMINAL PELIGROSO (%s). Incidencia técnica: %s" % [npc.tipo_amenaza, npc.incidencia]
			intencion = "HOSTIL/MENTIROSO. Miente. Si te descubren, ponte agresivo o intenta sobornar."
		elif npc.incidencia != GlobalEnums.Incidencia.NINGUNA:
			verdad_oculta = "Ciudadano despistado. Incidencia real: %s" % npc.incidencia
			intencion = "INOCENTE/NERVIOSO. No sabías del error. Reacciona con sorpresa o miedo."
		else:
			verdad_oculta = "Ciudadano Perfecto. Papeles en regla."
			intencion = "TRANQUILO/OFENDIDO. Si te acusan, oféndete."

		datos_para_prompt.append({
			"id_npc": npc.id,
			"nombre": npc.nombre,
			"rol": npc.rol,
			"personalidad": npc.personalidad,
			"verdad": verdad_oculta,
			"actitud_instruccion": intencion
		})

	# 2. Construimos el Prompt Maestro
	var prompt = _construir_prompt(datos_para_prompt, clima_actual)
	
	# 3. Configuramos el cuerpo JSON para la API de Google
	var body = JSON.stringify({
		"contents": [{
			"parts": [{"text": prompt}]
		}],
		"generation_config": {
			"temperature": 1.0,
			"top_k": 40,
			"top_p": 0.95,
			"max_output_tokens": 8192,
			"response_mime_type": "application/json"
		}
	})
	
	var headers = ["Content-Type: application/json"]
	
	# 4. Enviar
	print("[GEMINI] Enviando request a Gemini API...")
	var error = http_request.request(URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("[GEMINI ERROR] Fallo al enviar request: ", error)
		emit_signal("error_ocurred", "Fallo al conectar con Gemini")
	else:
		print("[GEMINI] Request enviado exitosamente, esperando respuesta...")

# --- CONSTRUCTOR DEL PROMPT ---
func _construir_prompt(datos_npcs: Array, clima: String) -> String:
	return """
	Eres el guionista de un videojuego ambientado en Ecuador (Universidad ESPE).
	
	CONTEXTO AMBIENTAL:
	El clima actual es: %s. (Esto debe afectar el humor del saludo: si llueve, tienen prisa/frío; si hay sol, calor/sed).
	
	TAREA:
	Genera los diálogos para los siguientes %d personajes basándote en su "VERDAD" y "PERSONALIDAD".
	Usa jerga ecuatoriana natural no forzada, y no dejes diálogos incompletos.
	
	DATOS DE LOS PERSONAJES:
	%s
	
	FORMATO DE SALIDA (JSON Array Estricto):
	Debes devolver un Array de objetos JSON. Cada objeto debe tener EXACTAMENTE esta estructura:
	
	[
		{
			"id_npc": "EL_ID_QUE_TE_PASE",
			"respuesta_incidencia_correcta": {
				"mensaje": "Lo que dice el NPC cuando el jugador descubre su error REAL.",
				"posible_res_guardia1": { 
					"mensaje": "Opción agresiva del jugador (ej: '¡Esto es falso!')", 
					"respuesta_npc": "Reacción del NPC a la agresión" 
				},
				"posible_res_guardia2": { 
					"mensaje": "Opción amable del jugador (ej: 'Disculpe, hay un error')", 
					"respuesta_npc": "Reacción del NPC a la amabilidad" 
				},
				"posible_res_guardia3": { 
					"mensaje": "Opción técnica del jugador (ej: 'El artículo 4 prohíbe...')", 
					"respuesta_npc": "Reacción del NPC a la burocracia" 
				}
			},
			"respuestas_incidencia_incorrecta": [
				"Excusa genérica 1 (cuando el jugador acusa algo que ESTÁ BIEN)",
				"Excusa genérica 2 (más molesta)",
				"Excusa genérica 3 (sarcástica)",
				"Excusa genérica 4 (confundida)"
			],
			"respuesta_aprobado": "Frase corta al entrar.",
			"respuesta_rechazado": "Frase corta al irse (insulto si es criminal, tristeza si es estudiante)."
		}
	]
	""" % [clima, datos_npcs.size(), JSON.stringify(datos_npcs)]

# --- MANEJO DE RESPUESTA ---
func _on_request_completed(result, response_code, headers, body):
	print("[GEMINI] Respuesta recibida - Código: %d, Result: %d" % [response_code, result])
	
	if response_code != 200:
		printerr("[GEMINI ERROR] Error API Gemini: ", response_code)
		var error_body = body.get_string_from_utf8()
		print("[GEMINI ERROR] Detalles: ", error_body)
		emit_signal("error_ocurred", "Error API: " + str(response_code))
		return

	# Parsear respuesta de la API
	var response_string = body.get_string_from_utf8()
	print("[GEMINI] Procesando respuesta...")
	var json_api = JSON.parse_string(response_string)
	
	if json_api and "candidates" in json_api:
		var contenido_texto = json_api["candidates"][0]["content"]["parts"][0]["text"]
		print("[GEMINI] Contenido recibido, parseando diálogos...")
		
		# Parsear el texto interno (que es el JSON de diálogos)
		var dialogos_finales = JSON.parse_string(contenido_texto)
		print(dialogos_finales)
		if dialogos_finales is Array:
			print("[GEMINI SUCCESS] ¡Lote de %d diálogos recibido correctamente!" % dialogos_finales.size())
			emit_signal("batch_completed", dialogos_finales)
		else:
			printerr("Gemini no devolvió un Array. Recibido: ", dialogos_finales)
			emit_signal("error_ocurred", "Formato JSON inválido")
	else:
		emit_signal("error_ocurred", "Respuesta vacía o malformada")
