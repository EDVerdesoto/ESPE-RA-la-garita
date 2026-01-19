extends Node

# Señal que emite cuando Gemini termina de procesar el lote y devuelve el JSON
# Devuelve un Array de Diccionarios con la estructura de diálogos
signal batch_completed(dialogos_array: Array)
signal error_ocurred(mensaje: String)

# CONFIGURACIÓN
const API_KEY = "TU_API_KEY_AQUI" 
const URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + API_KEY

@onready var http_request = HTTPRequest.new()

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# --- FUNCIÓN PRINCIPAL ---
# Recibe un Array de objetos NPC (AbstractNPC) y el String del clima
func solicitar_dialogos_batch(lista_npcs: Array, clima_actual: String):
	
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
		elif npc.incidencia != null and npc.incidencia != "":
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
		"generationConfig": {
			"responseMimeType": "application/json", # FORZAMOS JSON PURO
			"temperature": 1.0 # Creatividad alta para variedad de excusas
		}
	})
	
	var headers = ["Content-Type: application/json"]
	
	# 4. Enviar
	var error = http_request.request(URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		emit_signal("error_ocurred", "Fallo al conectar con Gemini")

# --- CONSTRUCTOR DEL PROMPT ---
func _construir_prompt(datos_npcs: Array, clima: String) -> String:
	return """
	Eres el guionista de un videojuego ambientado en Ecuador (Universidad ESPE).
	
	CONTEXTO AMBIENTAL:
	El clima actual es: %s. (Esto debe afectar el humor del saludo: si llueve, tienen prisa/frío; si hay sol, calor/sed).
	
	TAREA:
	Genera los diálogos para los siguientes %d personajes basándote en su "VERDAD" y "PERSONALIDAD".
	Usa jerga ecuatoriana natural.
	
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
	if response_code != 200:
		printerr("Error API Gemini: ", response_code)
		print(body.get_string_from_utf8())
		emit_signal("error_ocurred", "Error API: " + str(response_code))
		return

	# Parsear respuesta de la API
	var response_string = body.get_string_from_utf8()
	var json_api = JSON.parse_string(response_string)
	
	if json_api and "candidates" in json_api:
		var contenido_texto = json_api["candidates"][0]["content"]["parts"][0]["text"]
		
		# Parsear el texto interno (que es el JSON de diálogos)
		var dialogos_finales = JSON.parse_string(contenido_texto)
		
		if dialogos_finales is Array:
			print("¡Lote de diálogos recibido correctamente!")
			emit_signal("batch_completed", dialogos_finales)
		else:
			printerr("Gemini no devolvió un Array. Recibido: ", dialogos_finales)
			emit_signal("error_ocurred", "Formato JSON inválido")
	else:
		emit_signal("error_ocurred", "Respuesta vacía o malformada")
