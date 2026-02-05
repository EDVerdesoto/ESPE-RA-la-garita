extends Node

# Script para verificar qué modelos están disponibles para tu API Key
const API_KEY = "AIzaSyDFSNhslocEkwIS9Oy2lutuRxEMzwk2GqM" 
const URL_LIST = "https://generativelanguage.googleapis.com/v1beta/models?key=" + API_KEY

@onready var http = HTTPRequest.new()

func _ready():
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	
	print("--- CONSULTANDO MODELOS DISPONIBLES ---")
	print("Usando API Key: ...", API_KEY.right(5)) # Solo mostrar el final por seguridad
	
	var error = http.request(URL_LIST)
	if error != OK:
		print("Error al iniciar request: ", error)

func _on_request_completed(result, response_code, headers, body):
	print("Código de respuesta: ", response_code)
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("\n✅ API KEY VÁLIDA. Modelos disponibles:")
		if json and "models" in json:
			for model in json["models"]:
				# Filtramos solo los que sirven para 'generateContent'
				if "generateContent" in model.get("supportedGenerationMethods", []):
					print("- ", model["name"])
		else:
			print("JSON recibido pero sin lista de modelos: ", json)
	else:
		print("\n❌ ERROR CON LA API KEY O CONEXIÓN")
		print("Cuerpo del error: ", body.get_string_from_utf8())
