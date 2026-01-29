extends Node

signal datos_actualizados(fecha_actual, dinero_actual)

# Variables de estado persistentes
var dia : int = 1
var mes : int = 1
var anio : int = 2026
var dinero : float = 150.0 # Salario base inicial 

# Configuración del tiempo
@export var segundos_por_dia : float = 60.0
var _acumulador : float = 0.0

func _ready():
	cargar_progreso()
	emit_signal("datos_actualizados", get_fecha_string(), dinero)

func cargar_progreso():
	if not FileAccess.file_exists("user://savegame.save"):
		_inicializar_desde_sistema()
		return

	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var data = file.get_var()
	file.close()

	# Cargamos datos de fecha
	dia = data.get("dia", 1)
	mes = data.get("mes", 1)
	anio = data.get("anio", 2026)
	
	# Cargamos el dinero (si no existe, se queda con el valor por defecto)
	dinero = data.get("dinero", 150.0)

func guardar_progreso():
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var data = {
		"dia": dia,
		"mes": mes,
		"anio": anio,
		"dinero": dinero
	}
	file.store_var(data)
	file.close()

func actualizar_dinero(cantidad: float):
	dinero += cantidad
	guardar_progreso() # Guardado automático tras cada cambio económico
	emit_signal("datos_actualizados", get_fecha_string(), dinero)

func avanzar_dia():
	dia += 1
	_normalizar_fecha()
	guardar_progreso() 
	emit_signal("datos_actualizados", get_fecha_string(), dinero)

# --- LÓGICA INTERNA DE FECHAS (Tu implementación) ---

func _inicializar_desde_sistema():
	var fecha = Time.get_datetime_dict_from_system()
	dia = fecha.day
	mes = fecha.month
	anio = fecha.year
	dinero = 150.0 # Reset de dinero si es partida nueva
	guardar_progreso()

func _process(delta):
	_acumulador += delta
	if _acumulador >= segundos_por_dia:
		_acumulador = 0.0
		avanzar_dia()

func _normalizar_fecha():
	var dias_mes = _dias_del_mes(mes, anio)
	if dia > dias_mes:
		dia = 1
		mes += 1
		if mes > 12:
			mes = 1
			anio += 1

func _dias_del_mes(p_mes:int, p_anio:int) -> int:
	match p_mes:
		1,3,5,7,8,10,12: return 31
		4,6,9,11: return 30
		2: return 29 if _es_bisiesto(p_anio) else 28
	return 30

func _es_bisiesto(p_anio:int) -> bool:
	return (p_anio % 4 == 0 and p_anio % 100 != 0) or (p_anio % 400 == 0)

func get_fecha_string() -> String:
	return "%02d/%02d/%d" % [dia, mes, anio]
