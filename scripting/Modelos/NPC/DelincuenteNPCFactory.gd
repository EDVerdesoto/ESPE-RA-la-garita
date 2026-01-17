class_name DelincuenteNPCFactory
extends INPCFactory

# Datos específicos para delincuentes o personas peligrosas
var nombres_peligrosos = [
	"'El Chamo'", "Alias 'Cuchillo'", "Infiltrado X", "Ex-estudiante Expulsado"
]
var motivos_sospechosos = [
	"Vengo a dejar un paquete", "Busco a un amigo", "Solo voy de paso"
]

func crear_npc() -> AbstractNPC:
	var nuevo_delincuente = NPCDelincuente.new()
	
	nuevo_delincuente.personalidad = [
		"Agresivo", "Demasiado Amable", "Callado"
	].pick_random()
	
	# Ruben, aquí podrías luego conectar esto con el sistema de motivos de los civiles
	
	# Generador de nombres
	GeneradorNombres.generar_nombre(nuevo_delincuente)
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(nuevo_delincuente)
	
	return nuevo_delincuente
