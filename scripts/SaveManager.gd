extends Node

# Construimos la ruta según el slot elegido en el Global
func get_ruta_archivo() -> String:
	return "user://slot_" + str(GlobalGameManager.slot_actual) + ".save"

func guardar_partida():
	var ruta = get_ruta_archivo()
	print("--- GUARDANDO EN SLOT ", GlobalGameManager.slot_actual, " ---")
	
	# Armamos el diccionario maestro
	var datos_a_guardar = {
		"fecha": Time.get_datetime_string_from_system(),
		"progreso": {
			"dia": GlobalGameManager.dia_actual,
			"dinero": GlobalGameManager.dinero
		},
		"sesion": {
			"npc_index": GlobalGameManager.npc_actual_index,
			"npcs_data": GlobalGameManager.npcs_del_dia,
			"dialogos": GlobalGameManager.dialogos_del_dia_cache
		}
	}
	
	# Escribimos el archivo
	var file = FileAccess.open(ruta, FileAccess.WRITE)
	file.store_var(datos_a_guardar)
	file.close()
	print("Guardado exitoso.")

func cargar_partida():
	var ruta = get_ruta_archivo()
	if not FileAccess.file_exists(ruta):
		print("No existe archivo en este slot.")
		return
	
	print("Cargando partida...")
	var file = FileAccess.open(ruta, FileAccess.READ)
	var datos = file.get_var()
	file.close()
	
	# Le mandamos los datos al cerebro para que se actualice
	GlobalGameManager.cargar_datos_desde_save(datos)

# Función rápida para ver qué hay en el slot (para el menú de selección)
func obtener_info_resumida(num_slot: int) -> String:
	var ruta = "user://slot_" + str(num_slot) + ".save"
	if FileAccess.file_exists(ruta):
		var file = FileAccess.open(ruta, FileAccess.READ)
		var datos = file.get_var()
		file.close()
		if datos.has("progreso"):
			return "DÍA " + str(datos.progreso.dia) + " | $" + str(datos.progreso.dinero)
	return "VACÍO"
