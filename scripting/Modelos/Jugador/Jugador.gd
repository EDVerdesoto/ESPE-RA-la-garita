extends Node

signal sueldo_cambiado(nuevo_total)
signal reporte_generado(datos_reporte)

var dinero_total: float = 150.0 # Salario base inicial

func decidir_paso_npc(npc: AbstractNPC, decision: int):
	# 1. Obtenemos la evaluación del sistema
	var resultado = DetectorMentiras.evaluar_decision(npc, decision)
	
	# 2. Actualizamos el estado del jugador
	dinero_total += resultado.dinero
	
	# 3. Notificamos a los demás
	# Carlos usará esto para el HUD
	emit_signal("sueldo_cambiado", dinero_total) 
	
	# Joan usará esto para que el LLM reaccione al éxito/fracaso
	emit_signal("reporte_generado", resultado) 
	
	print("Balance actual: $", dinero_total)
