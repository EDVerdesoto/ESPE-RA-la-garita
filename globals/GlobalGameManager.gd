extends Node

# --- CONFIGURACIÓN DE SISTEMA ---
# Aquí guardamos a dónde volver si das clic en "Regresar" (Menú Principal por defecto)
var escena_retorno: String = "res://scenes/ui/menus/menuPrincipal.tscn"

# --- SISTEMA DE GUARDADO ---
# ¿En qué carpeta (slot) estamos jugando? (1, 2 o 3)
var slot_actual: int = 1

# --- DATOS DEL JUEGO (Lo que se guarda) ---
var dia_actual: int = 1

# --- ECONOMÍA --- 
var dinero: float = 0.0
var sueldo_base: float = 20.0       # Lo que gana por asomar la nariz
var pago_por_acierto: float = 5.0   # Bono por dejar pasar bien
var multa_por_error: float = 10.0   # Multa por dejar pasar un narco/erroneo
var arriendo_diario: float = 15.0   # Gastos fijos (comida, arriendo)

# Contadores de la sesión (se reinician cada día)
var aciertos_hoy: int = 0
var errores_hoy: int = 0
# Aquí puedes sumar más cosas (reputación, mejoras compradas, etc.)

# --- DATOS DE LA SESIÓN (Memoria RAM del nivel) ---
# Esto es lo que NO queremos perder si cerramos el juego a medias
var npc_actual_index: int = 0
var npcs_del_dia: Array = []       # La lista de estudiantes generados
var dialogos_del_dia_cache: Array = [] # Lo que escribió Gemini (para no gastar tokens)

# --- FUNCIONES ---

# Llama a esto cuando empieces una NUEVA partida para limpiar todo
func reiniciar_datos():
	dia_actual = 1
	dinero = 0.0
	resetear_sesion_diaria()

# Llama a esto cuando empiece un NUEVO DÍA (limpia los NPCs viejos)
func resetear_sesion_diaria():
	npc_actual_index = 0
	npcs_del_dia = []
	dialogos_del_dia_cache = []

# Esta función recibe los datos cargados desde el archivo
func cargar_datos_desde_save(datos: Dictionary):
	# 1. Recuperamos progreso general
	if datos.has("progreso"):
		dia_actual = datos.progreso.dia
		dinero = datos.progreso.dinero
	
	# 2. Recuperamos la sesión interrumpida (si existe)
	if datos.has("sesion"):
		npc_actual_index = datos.sesion.npc_index
		npcs_del_dia = datos.sesion.npcs_data
		dialogos_del_dia_cache = datos.sesion.dialogos
		
		
func calcular_fin_de_dia():
	print("--- CERRANDO CAJA DEL DÍA ", dia_actual, " ---")
	
	# 1. Calculamos ingresos y egresos
	var ingresos = sueldo_base + (aciertos_hoy * pago_por_acierto)
	var multas = errores_hoy * multa_por_error
	var gastos = arriendo_diario
	
	var total_dia = ingresos - multas - gastos
	
	# 2. Actualizamos la billetera real
	dinero += total_dia
	
	print("Ganaste: $", ingresos)
	print("Perdiste: $", multas + gastos)
	print("Total Neto: $", total_dia)
	print("Nueva Billetera: $", dinero)
	
	# 3. Avanzamos al siguiente día
	dia_actual += 1
	
	# 4. ¡GUARDAMOS AUTOMÁTICAMENTE!
	# Aquí es donde la persistencia cobra vida.
	SaveManager.guardar_partida()
	
	# 5. Limpiamos contadores para mañana
	resetear_sesion_diaria()
