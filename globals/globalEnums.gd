extends Node

class_name GlobalEnums

enum NPCState { NUEVO, APROBADO, EN_VALIDACION, DESAPROBADO }

enum Incidencia { 
	NINGUNA, 
	NOMBRE_CEDULA_DIFERENTE, NOMBRE_CARNET_DIFERENTE, NOMBRE_PASE_DIFERENTE,
	FECHA_CEDULA_CADUCADA, CEDULA_OLVIDADA,
	FOTO_CARNET_DIFERENTE, CARNET_OLVIDADO, CARRERA_DIFERENTE,
	PASE_VISITANTE_OLVIDADO,
	ATAQUE 
}

## Campos que el jugador puede comparar entre carnet, monitor y NPC
enum CampoComparacion {
	NINGUNO,
	NOMBRE,
	APELLIDO,
	FOTO,
	CODIGO_CARNET,
	CARRERA,
	NUMERO_CEDULA,
	FECHA_EXPIRACION,
	CARA_NPC
}

## Resultado de una comparación entre dos campos
enum ResultadoComparacion {
	COINCIDE,
	NO_COINCIDE,
	DATO_FALTANTE
}

## Decisión final del guardia
enum DecisionGuardia {
	PENDIENTE,
	APROBADO,
	RECHAZADO
}
