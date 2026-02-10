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
	
	# --------------------------------------------------
	# Separar catálogo en 3 grupos (militares excluidos)
	# --------------------------------------------------
	var estudiantes: Array = []
	var profesores: Array = []
	var atacantes_pool: Array = []
	for entry in bdd_visuales:
		match entry.get("rol_base", "Estudiante"):
			"Profesor":
				profesores.append(entry)
			"Atacante":
				atacantes_pool.append(entry)
			_:
				estudiantes.append(entry)
	estudiantes.shuffle()
	profesores.shuffle()
	atacantes_pool.shuffle()
	
	# --------------------------------------------------
	# Decidir composición del día
	# --------------------------------------------------
	var incluir_atacante = randf() < min(0.1 + GlobalGameManager.dia_actual * 0.05, 0.4)
	var cant_atacantes = 1 if (incluir_atacante and atacantes_pool.size() > 0) else 0
	
	var plazas_regulares = cantidad - cant_atacantes
	var cant_profesores = clampi(ceili(plazas_regulares * 0.25), 0, mini(profesores.size(), plazas_regulares - 1))
	var cant_estudiantes = plazas_regulares - cant_profesores
	
	var seleccion: Array = []
	for i in range(cant_estudiantes):
		seleccion.append(estudiantes[i % estudiantes.size()])
	for i in range(cant_profesores):
		seleccion.append(profesores[i % profesores.size()])
	seleccion.shuffle()
	
	# Insertar atacante en posición aleatoria (nunca el primero)
	if cant_atacantes > 0:
		var pos_atk = randi_range(2, maxi(2, seleccion.size()))
		seleccion.insert(pos_atk, atacantes_pool[0])
	
	# --------------------------------------------------
	# Crear objetos NPC
	# --------------------------------------------------
	var lista_final: Array = []
	
	for i in range(seleccion.size()):
		var visual_data = seleccion[i]
		var rol = visual_data.get("rol_base", "Estudiante")
		var sprite_path = visual_data.get("sprite_path", "")
		var cara_path = visual_data.get("cara_path", "")
		var nombre = visual_data.get("nombre_base", "NPC")
		var apellido = visual_data.get("apellido", "")
		var personalidad = visual_data.get("personalidad", "Tranquilo")
		var carrera = visual_data.get("carrera", "")
		var num_cedula = visual_data.get("numero_cedula", "")
		
		# ---- ATACANTE: sin documentos, solo visual ----
		if rol == "Atacante":
			var atk = NPCGenerico.new()
			atk.id = visual_data.get("id", "atk_" + str(i))
			atk.nombre = nombre
			atk.apellido = apellido
			atk.personalidad = personalidad
			atk.ruta_sprite_npc = sprite_path
			atk.sprite_path = sprite_path
			atk.cara_path = cara_path
			atk.carrera = ""
			atk.rol = "Atacante"
			atk.tipo_npc = "atacante"
			atk.incidencia = GlobalEnums.Incidencia.ATAQUE
			lista_final.append(atk)
			continue
		
		# ---- ESTUDIANTE / PROFESOR: pipeline normal ----
		if num_cedula.is_empty():
			num_cedula = "17" + str(randi() % 100000000).pad_zeros(8)
		
		var factory = NpcFactoryProvider.get_factory("generico")
		
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
			rol,
			"",
			cara_path
		)
		
		var pase_config = PaseVisitanteNPCConfig.new(
			nombre, apellido,
			"res://assets/objetos/carnet.png",
			"Visita académica"
		)
		
		var npc_obj = factory.crear_npc(
			nombre, apellido, personalidad,
			sprite_path, carrera,
			cedula_config, carnet_config, pase_config
		)
		
		if npc_obj == null:
			printerr("¡ERROR! Factory retornó null para NPC ", i)
			continue
		
		npc_obj.id = visual_data.get("id", "npc_" + str(i))
		npc_obj.rol = rol
		npc_obj.sprite_path = sprite_path
		npc_obj.cara_path = cara_path
		npc_obj.numero_cedula = num_cedula
		npc_obj.tipo_npc = "profesor" if sprite_path.find("profesor") != -1 else "estudiante"
		
		lista_final.append(npc_obj)
	
	print("[DAILY] Generados ", lista_final.size(), " NPCs para hoy (Día ",
		GlobalGameManager.dia_actual, ") — ",
		cant_estudiantes, " est, ", cant_profesores, " prof, ", cant_atacantes, " atk")
	return lista_final
