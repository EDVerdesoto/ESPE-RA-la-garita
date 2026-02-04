# DailyManager.gd
class_name DailyManager extends RefCounted # RefCounted para que se limpie solo de memoria

const DB_PATH = "res://data/npc_db.json"

func cargar_base_datos() -> Array:
	if not FileAccess.file_exists(DB_PATH):
		return []
	var content = FileAccess.get_file_as_string(DB_PATH)
	return JSON.parse_string(content)

func generar_npcs_para_hoy(cantidad: int) -> Array:
	var bdd_visuales = cargar_base_datos()
	# Mezclar para variedad visual
	bdd_visuales.shuffle()
	
	var lista_final = []
	var factory_generico = RandomNPCFactory.new()
	
	for i in range(cantidad):
		# Tomamos un visual de la base de datos (ciclando si faltan)
		var visual_data = bdd_visuales[i % bdd_visuales.size()]
		
		var npc: AbstractNPC
		npc = factory_generico.crear_npc(visual_data)
		
		lista_final.append(npc)
		
	return lista_final
