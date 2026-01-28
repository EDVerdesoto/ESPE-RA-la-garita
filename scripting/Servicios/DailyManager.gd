# DailyManager.gd
class_name DailyManager extends RefCounted # RefCounted para que se limpie solo de memoria

# Ruta a tu base de datos
const DB_PATH = "res://data/npc_catalog.json"

func cargar_bdd() -> Array:
	if not FileAccess.file_exists(DB_PATH):
		printerr("¡ERROR! No existe npc_catalog.json")
		return []
	
	var file = FileAccess.open(DB_PATH, FileAccess.READ)
	var content = file.get_as_text()
	return JSON.parse_string(content)

# Esta función devuelve los NPCs "crudos" (con datos, pero sin dialogo IA aún)
func preparar_npcs_para_hoy(cantidad: int) -> Array:
	var bdd = cargar_bdd()
	var npcs_generados = []
	
	# Mezclamos la BDD para que no salgan siempre los mismos
	bdd.shuffle()
	
	var factory = NpcFactoryProvider.get_factory("generico")
	
	for i in range(cantidad):
		# 1. Tomamos un 'cascarón' visual de la BDD
		# Usamos modulo % por si pides 10 NPCs y solo tienes 5 en BDD (se repiten visuales)
		var data_visual = bdd[i % bdd.size()] 
		
		# 2. Creamos configs para los documentos
		var cedula_config = CedulaNPCConfig.new(
			data_visual.get("nombre_base", "Juan"),
			data_visual.get("apellido", "Pérez"),
			"res://assets/documentos/cedula.png",
			"1234567890",
			FechaGlobal.obtener_fecha_actual(),
			FechaGlobal.obtener_fecha_futura(365)
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
		
		npcs_generados.append(npc_obj)
		
	return npcs_generados
