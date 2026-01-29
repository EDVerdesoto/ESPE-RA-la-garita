class_name DetectorMentiras
extends Node

# Definimos las recompensas y multas como constantes para fácil balanceo
const PAGO_EXITO = 10.0
const MULTA_ERROR_LEVE = 20.0
const MULTA_INFILTRADO_CRITICO = 100.0 # Dejar pasar a un delincuente es grave

static func evaluar_decision(npc: AbstractNPC, decision_jugador: int) -> Dictionary:
	var es_correcto: bool = false
	var mensaje: String = ""
	var impacto_economico: float = 0.0
	
	# La verdad absoluta del NPC
	var tiene_incidencia = (npc.incidencia != GlobalEnums.Incidencia.NINGUNA)
	
	# CASO 1: El jugador aprueba el paso
	if decision_jugador == GlobalEnums.NPCState.APROBADO:
		if not tiene_incidencia:
			es_correcto = true
			mensaje = "Correcto. El ciudadano cumple con los requisitos."
			impacto_economico = PAGO_EXITO
		else:
			es_correcto = false
			impacto_economico = -MULTA_ERROR_LEVE
			if npc is NPCDelincuente:
				mensaje = "¡PÉSIMO TRABAJO! Dejaste pasar a un infiltrado peligroso."
				impacto_economico = -MULTA_INFILTRADO_CRITICO
			else:
				mensaje = "Error. No detectaste el error: " + _obtener_nombre_error(npc.incidencia)

	# CASO 2: El jugador deniega el paso
	elif decision_jugador == GlobalEnums.NPCState.DESAPROBADO:
		if tiene_incidencia:
			es_correcto = true
			mensaje = "Bien hecho. Detectaste la incidencia: " + _obtener_nombre_error(npc.incidencia)
			impacto_economico = PAGO_EXITO
		else:
			es_correcto = false
			mensaje = "Injusto. Rechazaste a un ciudadano con papeles en regla."
			impacto_economico = -MULTA_ERROR_LEVE

	return {
		"es_correcto": es_correcto,
		"mensaje": mensaje,
		"dinero": impacto_economico,
		"incidencia_real": npc.incidencia
	}

static func _obtener_nombre_error(id_error: int) -> String:
	# Convertimos el enum a texto legible para el reporte
	return GlobalEnums.Incidencia.keys()[id_error].replace("_", " ").capitalize()
