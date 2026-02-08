## DailyManager: Genera la lista de NPCs para cada día de juego
class_name DailyManager extends RefCounted

const DB_PATH = "res://data/npc_catalog.json"

func cargar_base_datos() -> Array:
	if not FileAccess.file_exists(DB_PATH):
		printerr("¡ERROR! No existe npc_catalog.json")
		return []
	var content = FileAccess.get_file_as_string(DB_PATH)
	var parsed = JSON.parse_string(content)
	if parsed == null:
		printerr("¡ERROR! npc_catalog.json tiene formato inválido")
		return []
	return parsed

func generar_npcs_para_hoy(cantidad: int) -> Array:
	var bdd_visuales = cargar_base_datos()
	if bdd_visuales.is_empty():
		printerr("¡ERROR! Base de datos de NPCs vacía")
		return []
	bdd_visuales.shuffle()
	
	var lista_final: Array = []
	
	# Decidir cuántos delincuentes habrá hoy (0-1 por día, según el día)
	var incluir_delincuente = randf() < min(0.1 + GlobalGameManager.dia_actual * 0.05, 0.4)
	
	for i in range(cantidad):
		var visual_data = bdd_visuales[i % bdd_visuales.size()]
		
		# Elegir factory según tipo
		var factory_tipo = "generico"
		if incluir_delincuente and i == cantidad - 1:  # El último NPC puede ser delincuente
			factory_tipo = "delincuente"
		
		var factory = NpcFactoryProvider.get_factory(factory_tipo)
		
		var nombre = visual_data.get("nombre_base", "Juan")
		var apellido = visual_data.get("apellido", "Pérez")
		var personalidad = visual_data.get("personalidad", "Tranquilo")
		var sprite_path = visual_data.get("sprite_path", "res://assets/personajes/NPCs/NPC-estudiante-1.png")
		var carrera = visual_data.get("carrera", "Ingeniería en Software")
		var cara_path = visual_data.get("cara_path", "res://assets/personajes/caras/cara_001.png")
		var num_cedula = visual_data.get("numero_cedula", "17" + str(randi() % 100000000).pad_zeros(8))
		
		# Crear configs de documentos
		var cedula_config = CedulaNPCConfig.new(
			nombre, apellido,
			"res://assets/objetos/cedula.png",
			num_cedula,
			ProgresoGlobal.obtener_fecha_actual(),
			ProgresoGlobal.obtener_fecha_futura(365)
		)
		
		var carnet_config = CarnetUniversitarioNPCConfig.new(
			nombre, apellido,
			"res://assets/objetos/carnet.png",
			carrera,
			visual_data.get("rol_base", "Estudiante"),
			"",  # codigo_carnet - se genera en GeneradorIncidencias
			cara_path  # foto_path - cara real por defecto, puede cambiar con incidencia
		)
		
		var pase_config = PaseVisitanteNPCConfig.new(
			nombre, apellido,
			"res://assets/objetos/carnet.png",
			"Visita académica"
		)
		
		# Crear NPC (la factory llama a GeneradorIncidencias internamente)
		var npc_obj = factory.crear_npc(
			nombre, apellido, personalidad,
			sprite_path, carrera,
			cedula_config, carnet_config, pase_config
		)
		
		if npc_obj == null:
			printerr("¡ERROR! Factory retornó null para NPC ", i)
			continue
		
		# Pegar datos visuales y de identidad al NPC
		npc_obj.id = visual_data.get("id", "npc_" + str(i))
		npc_obj.rol = visual_data.get("rol_base", "Estudiante")
		npc_obj.sprite_path = sprite_path
		npc_obj.cara_path = cara_path
		npc_obj.numero_cedula = num_cedula
		
		lista_final.append(npc_obj)
	
	print("[DAILY] Generados ", lista_final.size(), " NPCs para hoy (Día ", GlobalGameManager.dia_actual, ")")
	return lista_final
