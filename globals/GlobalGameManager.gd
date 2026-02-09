extends Node

# --- CONFIGURACIÓN DE SISTEMA ---
# Aquí guardamos a dónde volver si das clic en "Regresar" (Menú Principal por defecto)
var escena_retorno: String = "res://scenes/ui/menus/menuPrincipal.tscn"

# --- SISTEMA DE GUARDADO ---
# ¿En qué carpeta (slot) estamos jugando? (1, 2 o 3)
var slot_actual: int = 1

# --- DATOS DEL JUEGO (Lo que se guarda) ---
var dia_actual: int = 1

# --- ESTADÍSTICAS TOTALES (HISTORIAL DE VIDA) ---
# ¡NUEVO! Esto guarda el acumulado de toda la partida
var aciertos_totales: int = 0
var errores_totales: int = 0

# --- ECONOMÍA --- 
var dinero: float = 0.0
var sueldo_base: float = 20.0       # Recompensa fija por completar el día
var arriendo_diario: float = 15.0   # Gastos fijos (comida, arriendo)

# Contadores de la sesión (se reinician cada día)
var aciertos_hoy: int = 0
var errores_hoy: int = 0

# --- POST-ACCIONES DEL DÍA ---
# Cada entrada: { "texto": String, "valor": float, "categoria": String, "npc_nombre": String }
var post_actions_hoy: Array = []
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
	# Reiniciamos también los totales históricos
	aciertos_totales = 0
	errores_totales = 0
	resetear_sesion_diaria()

# Llama a esto cuando empiece un NUEVO DÍA (limpia los NPCs viejos)
func resetear_sesion_diaria():
	npc_actual_index = 0
	npcs_del_dia = []
	aciertos_hoy = 0
	errores_hoy = 0
	post_actions_hoy = []
	dialogos_del_dia_cache = []

## Registra una post-acción para el reporte de fin de día
func registrar_post_action(post_action: Dictionary) -> void:
	if post_action.is_empty():
		return
	post_actions_hoy.append(post_action)
	print("[POST-ACTION] ", post_action.get("categoria", "?"), ": ", post_action.get("texto", "?"))

# Esta función recibe los datos cargados desde el archivo
func cargar_datos_desde_save(datos: Dictionary):
	# 1. Recuperamos progreso general
	if datos.has("progreso"):
		dia_actual = datos.progreso.dia
		dinero = datos.progreso.dinero
	
	# 2. Recuperamos estadísticas totales (¡NUEVO!)
	if datos.has("estadisticas"):
		aciertos_totales = datos.estadisticas.aciertos
		errores_totales = datos.estadisticas.errores
	else:
		# Por si cargas un save viejo que no tenía esto
		aciertos_totales = 0
		errores_totales = 0
	
	# 3. Recuperamos la sesión interrumpida (si existe)
	if datos.has("sesion"):
		npc_actual_index = datos.sesion.npc_index
		npcs_del_dia = datos.sesion.npcs_data
		dialogos_del_dia_cache = datos.sesion.dialogos
		
		
## Calcula el resumen económico del día.
## Retorna un Dictionary con el desglose completo para mostrar en la UI.
## NO resetea la sesión — eso lo hace quien muestre el reporte después.
func calcular_fin_de_dia() -> Dictionary:
	print("--- CERRANDO CAJA DEL DÍA ", dia_actual, " ---")
	
	# 1. Sueldo base por completar el día
	var ingresos_base = sueldo_base
	
	# 2. Sumar/restar valores de todas las post-acciones
	var total_post_actions: float = 0.0
	var buenas: Array = []
	var malas: Array = []
	var graves: Array = []
	var rechazos_injustos: Array = []
	
	for pa in post_actions_hoy:
		var valor = pa.get("valor", 0.0)
		total_post_actions += valor
		match pa.get("categoria", ""):
			"buena": buenas.append(pa)
			"mala": malas.append(pa)
			"grave": graves.append(pa)
			"rechazo_injusto": rechazos_injustos.append(pa)
	
	# 3. Gastos fijos
	var gastos = arriendo_diario
	
	# 4. Total neto del día
	var total_dia = ingresos_base + total_post_actions - gastos
	
	# 5. Actualizar billetera
	dinero += total_dia
	
	# 6. Historial
	aciertos_totales += aciertos_hoy
	errores_totales += errores_hoy
	
	print("Sueldo base: $", ingresos_base)
	print("Post-acciones: $", total_post_actions)
	print("Gastos fijos: -$", gastos)
	print("Total Neto: $", total_dia)
	print("Nueva Billetera: $", dinero)
	
	# 7. Construir resumen para la UI
	var resumen = {
		"dia": dia_actual,
		"sueldo_base": ingresos_base,
		"gastos_fijos": gastos,
		"total_post_actions": total_post_actions,
		"total_dia": total_dia,
		"dinero_final": dinero,
		"aciertos": aciertos_hoy,
		"errores": errores_hoy,
		"buenas": buenas,
		"malas": malas,
		"graves": graves,
		"rechazos_injustos": rechazos_injustos,
		"todas_post_actions": post_actions_hoy,
	}
	
	# 8. Avanzar día y guardar
	dia_actual += 1
	SaveManager.guardar_partida()
	
	return resumen

## Llama después de que el jugador cierre el reporte de fin de día
func confirmar_fin_de_dia() -> void:
	resetear_sesion_diaria()
