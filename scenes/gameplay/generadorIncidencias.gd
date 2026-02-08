class_name GeneradorIncidencias
extends Node

const PROBABILIDAD_INCIDENCIA_GENERIC = 0.65
const PROBABILIDAD_INCIDENCIA_DELINCUENTE = 0.95

## Pool de fotos alternativas para cuando la foto del carnet no coincide
const FOTOS_ALTERNATIVAS: Array[String] = [
	"res://assets/personajes/caras/cara_001.png",
	"res://assets/personajes/caras/cara_002.png",
	"res://assets/personajes/caras/cara_003.png",
	"res://assets/personajes/caras/cara_004.png",
	"res://assets/personajes/caras/cara_005.png",
]

static func generar_incidencias(
	npc: AbstractNPC, 
	cedula_config: CedulaNPCConfig,
	carnet_universitario_config: CarnetUniversitarioNPCConfig,
	pase_visitante_config: PaseVisitanteNPCConfig
) -> void:
	
	var probabilidad_base: float = 0.0
	if npc is NPCDelincuente:
		probabilidad_base = PROBABILIDAD_INCIDENCIA_DELINCUENTE
	elif npc is NPCGenerico:
		probabilidad_base = PROBABILIDAD_INCIDENCIA_GENERIC

	if randf() < probabilidad_base:
		_asignar_error_por_tipo(npc)
	else:
		npc.incidencia = GlobalEnums.Incidencia.NINGUNA

	# Lógica específica para FECHA_CEDULA_CADUCADA
	if npc.incidencia == GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA:
		if _es_fecha_valida_para_expirar(cedula_config.fecha_expiracion):
			cedula_config.fecha_expiracion = _generar_fecha_invalida_real()
		else:
			_recalcular_incidencia_sin_fecha(npc)
	
	# Asignar foto al carnet (puede ser diferente si hay incidencia FOTO_CARNET_DIFERENTE)
	_asignar_foto_carnet(npc, carnet_universitario_config)
	
	# Generar código de carnet
	_generar_codigo_carnet(npc, carnet_universitario_config)
	
	# Construir documentos, datos del sistema (cédula → monitor) y aplicar discrepancias
	_construir_documentos(npc, cedula_config, carnet_universitario_config, pase_visitante_config)

# --- FOTO Y CÓDIGO ---

static func _asignar_foto_carnet(npc: AbstractNPC, carnet_config: CarnetUniversitarioNPCConfig) -> void:
	# carnet_config.foto_path was set to the REAL face by DailyManager
	# npc.cara_path is still empty at this point, so we initialize it here
	var cara_real = carnet_config.foto_path
	npc.cara_path = cara_real  # Store real face on NPC for later use
	
	if npc.incidencia == GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE:
		# Elegir una foto DIFERENTE a la cara real del NPC
		var fotos_disponibles = FOTOS_ALTERNATIVAS.filter(
			func(f): return f != cara_real
		)
		if fotos_disponibles.size() > 0:
			npc.foto_carnet_path = fotos_disponibles.pick_random()
		else:
			npc.foto_carnet_path = FOTOS_ALTERNATIVAS[0]
		carnet_config.foto_path = npc.foto_carnet_path
	else:
		# Foto correcta: la foto del carnet ES la cara real
		npc.foto_carnet_path = cara_real
		# carnet_config.foto_path is already set to cara_real, no overwrite needed

static func _generar_codigo_carnet(npc: AbstractNPC, carnet_config: CarnetUniversitarioNPCConfig) -> void:
	var anio = 2020 + randi() % 6  # 2020-2025
	var secuencia = randi() % 99999
	var codigo = "ESPE-%d-%05d" % [anio, secuencia]
	npc.codigo_carnet = codigo
	carnet_config.codigo_carnet = codigo

# --- MÉTODOS DE LÓGICA DE FECHAS ---

static func _es_fecha_valida_para_expirar(fecha: String) -> bool:
	if fecha == null: return true
	var partes = str(fecha).split("/")
	if partes.size() < 3: return true 
	var f_dia = int(partes[0])
	var f_mes = int(partes[1])
	var f_anio = int(partes[2])
	if f_anio > ProgresoGlobal.anio: return true
	if f_anio < ProgresoGlobal.anio: return false
	if f_mes > ProgresoGlobal.mes: return true
	if f_mes < ProgresoGlobal.mes: return false
	return f_dia >= ProgresoGlobal.dia

static func _generar_fecha_invalida_real() -> String:
	var anio_pasado = ProgresoGlobal.anio - 1
	var mes_random = randi() % 12 + 1
	var dia_random = randi() % 28 + 1
	return "%02d/%02d/%d" % [dia_random, mes_random, anio_pasado]

static func _generar_fecha_valida_real() -> String:
	var anio_futuro = ProgresoGlobal.anio + 5
	var mes_random = randi() % 12 + 1
	var dia_random = randi() % 28 + 1
	return "%02d/%02d/%d" % [dia_random, mes_random, anio_futuro]

# --- CONSTRUCCIÓN Y ASIGNACIÓN ---

static func _asignar_error_por_tipo(npc: AbstractNPC) -> void:
	if npc is NPCDelincuente:
		npc.incidencia = GlobalEnums.Incidencia.SOSPECHOSO
	else:
		var opciones = [
			GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
			GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE,
			GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA,
			GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE,
			GlobalEnums.Incidencia.CARRERA_DIFERENTE,
		]
		npc.incidencia = opciones.pick_random()

static func _recalcular_incidencia_sin_fecha(npc: AbstractNPC) -> void:
	var incidencias = [
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE,
		GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE,
		GlobalEnums.Incidencia.CARRERA_DIFERENTE,
	]
	npc.incidencia = incidencias.pick_random()

static func _construir_documentos(
	npc: AbstractNPC, 
	cedula_config: CedulaNPCConfig,
	carnet_universitario_config: CarnetUniversitarioNPCConfig,
	pase_visitante_config: PaseVisitanteNPCConfig
) -> void:

	# --- Datos base (correctos, del NPC real) ---
	var nom_ced = npc.nombre
	var apellido_ced = npc.apellido
	var fecha_final_cedula = cedula_config.fecha_expiracion
	
	var nom_car = npc.nombre
	var apellido_car = npc.apellido
	var carrera = npc.carrera
	
	var nom_pase = npc.nombre
	var apellido_pase = npc.apellido
	var razon = "Visita académica"

	var nombres_aleatorios: Array[String] = ["Juan", "María", "Carlos", "Ana", "Pedro", "Lucía", "José", "Valentina", "Diego", "Sofía"]
	var apellidos_aleatorios: Array[String] = ["Pérez", "Gómez", "Rodríguez", "Martínez", "López", "Hernández", "Torres", "Ramírez", "Vargas", "Flores"]
	var carreras_aleatorias: Array[String] = ["Ingeniería en Software", "Biotecnología", "Economía", "Fisioterapia", "Derecho"]

	# Aplicar discrepancias según incidencia
	match npc.incidencia:
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE:
			# El sistema (cédula) tiene nombre diferente al real
			nom_ced = nombres_aleatorios.filter(func(n): return n != npc.nombre).pick_random()
			apellido_ced = apellidos_aleatorios.filter(func(a): return a != npc.apellido).pick_random()
			
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE:
			# El carnet tiene nombre diferente al real
			nom_car = nombres_aleatorios.filter(func(n): return n != npc.nombre).pick_random()
			apellido_car = apellidos_aleatorios.filter(func(a): return a != npc.apellido).pick_random()
			
		GlobalEnums.Incidencia.NOMBRE_PASE_DIFERENTE:
			nom_pase = nombres_aleatorios.filter(func(n): return n != npc.nombre).pick_random()
			apellido_pase = apellidos_aleatorios.filter(func(a): return a != npc.apellido).pick_random()
			
		GlobalEnums.Incidencia.CARRERA_DIFERENTE:
			carrera = carreras_aleatorias.filter(func(c): return c != npc.carrera).pick_random()
		
		# FOTO_CARNET_DIFERENTE ya se manejó en _asignar_foto_carnet()
		# FECHA_CEDULA_CADUCADA ya se manejó arriba

	if fecha_final_cedula == null or fecha_final_cedula.is_empty():
		fecha_final_cedula = _generar_fecha_valida_real()

	npc.documentos = []

	# --- DATOS DEL SISTEMA (lo que el monitor mostrará al escanear carnet) ---
	# Usa los valores de cédula (nom_ced, apellido_ced) que pueden tener discrepancias
	# para NOMBRE_CEDULA_DIFERENTE, o el valor correcto para otras incidencias.
	npc.datos_sistema = {
		"nombre": nom_ced,
		"apellido": apellido_ced,
		"numero_cedula": cedula_config.numero_cedula,
		"fecha_expiracion": fecha_final_cedula,
		"carrera": npc.carrera,          # Carrera del sistema siempre refleja la verdad
		"foto_sistema": npc.cara_path,   # Foto del registro oficial = cara real
		"codigo_carnet": npc.codigo_carnet,
	}

	# --- CARNET: es el documento principal que el NPC lleva físicamente ---
	if npc.incidencia != GlobalEnums.Incidencia.CARNET_OLVIDADO:
		var p_carnet_config = CarnetUniversitarioNPCConfig.new(
			nom_car, apellido_car,
			carnet_universitario_config.ruta_sprite,
			carrera, "Estudiante",
			carnet_universitario_config.codigo_carnet,
			carnet_universitario_config.foto_path
		)
		var p_carnet = DocumentoNpcFactoryProvider.get_factory("carnet_universitario").crear_documento(p_carnet_config)
		npc.documentos.append(p_carnet)
	
	# --- PASE VISITANTE: solo para no-estudiantes ---
	if npc.incidencia != GlobalEnums.Incidencia.PASE_VISITANTE_OLVIDADO and not (npc is NPCGenerico):
		var p_pase_config = PaseVisitanteNPCConfig.new(
			nom_pase, apellido_pase,
			pase_visitante_config.ruta_sprite,
			razon
		)
		var p_pase = DocumentoNpcFactoryProvider.get_factory("pase_visitante").crear_documento(p_pase_config)
		npc.documentos.append(p_pase)
