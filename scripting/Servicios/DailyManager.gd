# DailyManager.gd
class_name DailyManager extends RefCounted # RefCounted para que se limpie solo de memoria

# Ruta a tu base de datos
const DB_PATH = "res://data/npc_catalog.json"

func cargar_base_datos() -> Array:
	if not FileAccess.file_exists(DB_PATH):
		printerr("¡ERROR! No existe npc_catalog.json")
		return []
	var content = FileAccess.get_file_as_string(DB_PATH)
	return JSON.parse_string(content)

func generar_npcs_para_hoy(cantidad: int) -> Array:
	var bdd_visuales = cargar_base_datos()
	# Mezclar para variedad visual
	bdd_visuales.shuffle()
	
	# Mezclamos la BDD para que no salgan siempre los mismos
	bdd.shuffle()
	
	var factory = NpcFactoryProvider.get_factory("generico")
	
	for i in range(cantidad):
		# Tomamos un visual de la base de datos (ciclando si faltan)
		var visual_data = bdd_visuales[i % bdd_visuales.size()]
		
		# 2. Creamos configs para los documentos
		var cedula_config = CedulaNPCConfig.new(
			data_visual.get("nombre_base", "Juan"),
			data_visual.get("apellido", "Pérez"),
			"res://assets/documentos/cedula.png",
			"1234567890",
			ProgresoGlobal.obtener_fecha_actual(),
			ProgresoGlobal.obtener_fecha_futura(365)
		)
		
		var carnet_config = CarnetUniversitarioNPCConfig.new(
			data_visual.get("nombre_base", "Juan"),
			data_visual.get("apellido", "Pérez"),
			"res://assets/documentos/carnet.png",
			data_visual.get("carrera", "Ingeniería"),
			data_visual.get("rol_base", "Estudiante")
		)
		
		var pase_config = PaseVisitanteNPCConfig.new(
			data_visual.get("nombre_base", "Juan"),
			data_visual.get("apellido", "Pérez"),
			"res://assets/documentos/pase.png",
			"Visita académica"
		)
		
		# 3. Usamos tu Factory para crear la lógica (Delincuente/Generico/Incidencias)
		var npc_obj = factory.crear_npc(
			data_visual.get("nombre_base", "Juan"),
			data_visual.get("apellido", "Pérez"),
			data_visual.get("personalidad", "Tranquilo"),
			data_visual.get("sprite_path", "res://assets/personajes/estudiante.png"),
			data_visual.get("carrera", "Ingeniería"),
			cedula_config,
			carnet_config,
			pase_config
		)
		
		# 4. HIBRIDACIÓN: Pegamos los datos visuales al objeto lógico
		npc_obj.id = data_visual.get("id", "npc_" + str(i))
		npc_obj.rol = data_visual.get("rol_base", "Estudiante")
		npc_obj.sprite_path = data_visual.get("sprite_path", "res://assets/personajes/estudiante.png")
		npc_obj.cara_path = data_visual.get("cara_path", "res://assets/personajes/cara.png")
		
	return lista_final
