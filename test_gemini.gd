extends Node

# Script de prueba para verificar conexión con Gemini
# Para usar: Adjunta este script a cualquier nodo y ejecuta la escena

func _ready():
	print("=== INICIANDO TEST DE GEMINI ===")
	
	# Conectar señales
	GeminiManager.batch_completed.connect(_on_test_success)
	GeminiManager.error_ocurred.connect(_on_test_error)
	
	# Crear un NPC de prueba
	var npc_test = NPCGenerico.new()
	npc_test.id = "test_001"
	npc_test.nombre = "Juan"
	npc_test.apellido = "Pérez"
	npc_test.rol = "Estudiante"
	npc_test.personalidad = "Nervioso"
	npc_test.incidencia = GlobalEnums.Incidencia.NINGUNA
	
	# Hacer la prueba
	await get_tree().create_timer(1.0).timeout
	print("\n--- Enviando solicitud de prueba a Gemini ---")
	GeminiManager.solicitar_dialogos_batch([npc_test], "Soleado")
	
	# Esperar 10 segundos y reportar
	await get_tree().create_timer(10.0).timeout
	print("\n=== TIMEOUT - Si no viste respuesta, revisa tu API key ===")

func _on_test_success(dialogos: Array):
	print("\n✅ ¡CONEXIÓN EXITOSA CON GEMINI!")
	print("Diálogos recibidos: ", dialogos.size())
	print("Ejemplo de diálogo: ", JSON.stringify(dialogos[0], "\t"))
	print("\n=== TEST COMPLETADO CON ÉXITO ===")

func _on_test_error(mensaje: String):
	print("\n❌ ERROR EN CONEXIÓN CON GEMINI")
	print("Mensaje: ", mensaje)
	print("\nPosibles causas:")
	print("1. API Key inválida o expirada")
	print("2. Sin conexión a internet")
	print("3. Límite de solicitudes excedido")
	print("4. API de Gemini no disponible")
	print("\n=== TEST FALLÓ ===")
