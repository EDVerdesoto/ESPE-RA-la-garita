# DailyManager.gd
class_name DailyManager extends RefCounted # RefCounted para que se limpie solo de memoria

# Ruta a tu base de datos
const DB_PATH = "res://data/npc_db.json"

func cargar_bdd() -> Array:
	if not FileAccess.file_exists(DB_PATH):
		printerr("¡ERROR! No existe npc_db.json")
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
		
		# 2. Usamos tu Factory para crear la lógica (Delincuente/Generico/Incidencias)
		var npc_obj = factory.crear_npc() 
		
		# 3. HIBRIDACIÓN: Pegamos los datos visuales al objeto lógico
		npc_obj.id = data_visual["id"]
		npc_obj.nombre = data_visual["nombre"]
		npc_obj.rol = data_visual["rol"]
		npc_obj.personalidad = data_visual["personalidad"]
		npc_obj.sprite_path = data_visual["sprite_path"]
		npc_obj.cara_path = data_visual["cara_path"]
		
		npcs_generados.append(npc_obj)
		
	return npcs_generados
