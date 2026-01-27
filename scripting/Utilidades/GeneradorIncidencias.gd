class_name GeneradorIncidencias
extends Node

const PROBABILIDAD_INCIDENCIA_GENERIC = 0.65
const PROBABILIDAD_INCIDENCIA_DELINCUENTE = 0.95

static func generar_incidencias(
	npc: AbstractNPC, 
	cedula_config : CedulaNPCConfig,
	carnet_universitario_config : CarnetUniversitarioNPCConfig,
	pase_visitante_config : PaseVisitanteNPCConfig
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
		if _es_fecha_valida_para_expirar(cedula_config.fecha_expiracion_cedula):
			cedula_config.fecha_expiracion_cedula = _generar_fecha_invalida_real()
		else:
			# Es false: Recalculamos la incidencia omitiendo la fecha
			_recalcular_incidencia_sin_fecha(npc)
	
	# Construcción de los objetos con las fechas finales
	_construir_documentos(npc, cedula_config, carnet_universitario_config, pase_visitante_config)

# --- MÉTODOS DE LÓGICA DE FECHAS ---

static func _es_fecha_valida_para_expirar(fecha: String) -> bool:
	# Si no hay fecha, asumimos que podemos generar una inválida desde cero
	if fecha == null: return true

	var partes = str(fecha).split("/")
	if partes.size() < 3: return true 

	var f_dia = int(partes[0])
	var f_mes = int(partes[1])
	var f_anio = int(partes[2])
	
	# 1. Comparación de Año
	if f_anio > FechaGlobal.anio: return true
	if f_anio < FechaGlobal.anio: return false

	# 2. Si el año es el mismo, comparamos Mes
	if f_mes > FechaGlobal.mes: return true
	if f_mes < FechaGlobal.mes: return false
	
	# 3. Si año y mes son iguales, el Día decide
	# Si el día de la cédula es hoy o después, la fecha aún es válida (se puede caducar)
	return f_dia >= FechaGlobal.dia

static func _generar_fecha_invalida_real() -> String:
	# Generamos una fecha del año pasado respecto al juego para que sea INVÁLIDA
	var anio_pasado = FechaGlobal.anio - 1
	var mes_random = randi() % 12 + 1
	var dia_random = randi() % 28 + 1
	return "%02d/%02d/%d" % [dia_random, mes_random, anio_pasado]

static func _generar_fecha_valida_real() -> String:
	# Generamos una fecha a 5 años en el futuro para que sea VÁLIDA
	# Las cédulas en Ecuador suelen durar 10 años, usamos 5 para seguridad
	var anio_futuro = FechaGlobal.anio + 5
	var mes_random = randi() % 12 + 1
	var dia_random = randi() % 28 + 1
	return "%02d/%02d/%d" % [dia_random, mes_random, anio_futuro]

# --- CONSTRUCCIÓN Y ASIGNACIÓN ---

static func _asignar_error_por_tipo(npc: AbstractNPC) -> void:
	if npc is NPCDelincuente:
		npc.incidencia = GlobalEnums.Incidencia.SOSPECHOSO
		npc.carnet = null
	else:
		var opciones = [
			GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
			GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE,
			GlobalEnums.Incidencia.FECHA_CEDULA_CADUCADA,
			GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE
		]
		npc.incidencia = opciones.pick_random()

static func _recalcular_incidencia_sin_fecha(npc: AbstractNPC) -> void:
	var incidencias = [
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE,
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE,
		GlobalEnums.Incidencia.FOTO_CARNET_DIFERENTE
	]
	npc.incidencia = incidencias.pick_random()

static func _construir_documentos(
	npc : AbstractNPC, 
	cedula_config : CedulaNPCConfig,
	carnet_universitario_config : CarnetUniversitarioNPCConfig,
	pase_visitante_config : PaseVisitanteNPCConfig
) -> void:

	# Cédula
	var nom_ced = npc.nombre
	var apellido_ced = npc.apellido
	var ruta_sprite_ced = cedula_config.ruta_sprite_cedula
	var fecha_final_cedula = cedula_config.fecha_expiracion
	
	# Carnet
	var nom_car = npc.nombre
	var apellido_car = npc.apellido
	var carrera = npc.carrera
	var ruta_sprite_car = carnet_universitario_config.ruta_sprite_carnet_universitario
	
	# Pase Visitante
	var nom_pase = npc.nombre
	var apellido_pase = npc.apellido
	var ruta_sprite_pase = pase_visitante_config.ruta_sprite_pase_visitante
	var razon = "Que te importa pues"


	var nombres_aleatorios : Array[String] = ["Juan", "María", "Carlos", "Ana", "Pedro", "Lucía", "José", "Valentina", "Diego", "Sofía"]
	var apellidos_aleatorios : Array[String] = ["Pérez", "Gómez", "Rodríguez", "Martínez", "López", "Hernández", "Torres", "Ramírez", "Vargas", "Flores"]
	var carreras_aleatorias : Array[String] = ["Ingeniería en Software", "Biotecnología", "Economía", "Fisioterapia", "Derecho"]

	# Aplicar discrepancias según incidencia con filtrado para asegurar el error
	match npc.incidencia:
		GlobalEnums.Incidencia.NOMBRE_CEDULA_DIFERENTE:
			# Filtramos la lista para que el nombre elegido sea distinto al real del NPC
			nom_ced = nombres_aleatorios.filter(func(n): return n != npc.nombre).pick_random()
			apellido_ced = apellidos_aleatorios.filter(func(a): return a != npc.apellido).pick_random()
			
		GlobalEnums.Incidencia.NOMBRE_CARNET_DIFERENTE:
			# Lo mismo para el carnet universitario
			nom_car = nombres_aleatorios.filter(func(n): return n != npc.nombre).pick_random()
			apellido_car = apellidos_aleatorios.filter(func(a): return a != npc.apellido).pick_random()
			
		GlobalEnums.Incidencia.NOMBRE_PASE_DIFERENTE:
			# Lo mismo para el carnet universitario
			nom_pase = nombres_aleatorios.filter(func(n): return n != npc.nombre).pick_random()
			apellido_pase = apellidos_aleatorios.filter(func(a): return a != npc.apellido).pick_random()
			
		GlobalEnums.Incidencia.CARRERA_DIFERENTE:
			# Aseguramos que la carrera en el carnet no sea la real (ej. Ingeniería de Software )
			carrera = carreras_aleatorias.filter(func(c): return c != npc.carrera).pick_random()
		
		
	# Si la fecha es nula tras las validaciones, asegurar una válida
	if fecha_final_cedula == null:
		fecha_final_cedula = _generar_fecha_valida_real()

	npc.documentos = Array[AbstractDocumentoNPC].new()

	# Creación de documentos si no son la incidencia olvidada
	if npc.incidencia != GlobalEnums.Incidencia.CEDULA_OLVIDADA:
		var p_cedula_config = CedulaNPCConfig.new(
			nom_ced,
			apellido_ced,
			ruta_sprite_ced,
			cedula_config.numero_cedula,
			cedula_config.fecha_emision,
			fecha_final_cedula
		)

		var p_cedula = DocumentoNpcFactoryProvider.get_factory("cedula").crear_documento(p_cedula_config)
		npc.documentos.append(p_cedula)
		
	if npc.incidencia != GlobalEnums.Incidencia.CARNET_OLVIDADO:
		var p_carnet_config = CarnetUniversitarioNPCConfig.new(
			nom_car,
			apellido_car,
			ruta_sprite_car,
			carrera,
			"estudiante"	# TO CHECK
		)

		var p_carnet = DocumentoNpcFactoryProvider.get_factory("carnet_universitario").crear_documento(p_carnet_config)
		npc.documentos.append(p_carnet)
	
	# Solo visitantes pueden tener pase, sería ilógico que un estudiante tenga un pase de visitante,
	# o depende si luego queremos hacerlo así
	if npc.incidencia != GlobalEnums.Incidencia.PASE_VISITANTE_OLVIDADO && !npc is NPCGenerico:
		var p_pase_config = PaseVisitanteNPCConfig.new(
			nom_pase,
			apellido_pase,
			ruta_sprite_pase,
			razon
		)

		var p_pase = DocumentoNpcFactoryProvider.get_factory("pase_visitante").crear_documento(p_pase_config)
		npc.documentos.append(p_pase)
