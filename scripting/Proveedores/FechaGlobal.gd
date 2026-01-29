# Autoload

extends Node

signal dia_avanzado(fecha_actual)

var dia : int = 1
var mes : int = 1
var anio : int = 2026

# Configuración del juego
@export var segundos_por_dia : float = 60.0
var _acumulador : float = 0.0

func _ready():
	cargar_fecha()
	emit_signal("dia_avanzado", get_fecha_dict())

func cargar_fecha():
	if not FileAccess.file_exists("user://savegame.save"):
		_inicializar_fecha_desde_sistema()
		return

	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var data = file.get_var()
	file.close()

	dia = data.dia
	mes = data.mes
	anio = data.anio


func avanzar_dia():
	dia += 1
	_normalizar_fecha()
	emit_signal("dia_avanzado", get_fecha_dict())
	guardar_fecha() 

func _inicializar_fecha_desde_sistema():
	var fecha = Time.get_datetime_dict_from_system()

	dia = fecha.day
	mes = fecha.month
	anio = fecha.year

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
		2:
			return 29 if _es_bisiesto(p_anio) else 28
	return 30

func _es_bisiesto(p_anio:int) -> bool:
	return (p_anio % 4 == 0 and p_anio % 100 != 0) or (p_anio % 400 == 0)


func get_fecha_dict() -> Dictionary:
	return {
		"dia": dia,
		"mes": mes,
		"anio": anio
	}

func get_fecha_string() -> String:
	return "%02d/%02d/%d" % [dia, mes, anio]

func obtener_fecha_actual() -> String:
	return get_fecha_string()

func obtener_fecha_futura(dias_adelante: int) -> String:
	var futuro_dia = dia + dias_adelante
	var futuro_mes = mes
	var futuro_anio = anio
	
	while futuro_dia > _dias_del_mes(futuro_mes, futuro_anio):
		futuro_dia -= _dias_del_mes(futuro_mes, futuro_anio)
		futuro_mes += 1
		if futuro_mes > 12:
			futuro_mes = 1
			futuro_anio += 1
	
	return "%02d/%02d/%d" % [futuro_dia, futuro_mes, futuro_anio]
	
func get_datos_a_guardar() -> Dictionary:
	return {
		"dia": dia,
		"mes": mes,
		"anio": anio
	}
	
func guardar_fecha():
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	file.store_var(get_datos_a_guardar())
	file.close()
