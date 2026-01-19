class_name DelincuenteNPCFactory
extends INPCFactory

# Datos específicos para delincuentes o personas peligrosas
var nombres_peligrosos = [
	"'El Chamo'", "Alias 'Cuchillo'", "Infiltrado X", "Ex-estudiante Expulsado"
]
var motivos_sospechosos = [
	"Vengo a dejar un paquete", "Busco a un amigo", "Solo voy de paso"
]

func crear_npc(
	nombre:String, personalidad:String, ruta_sprite_npc:String,
	ruta_sprite_carnet:String, ruta_sprite_cedula:String,
	fecha_expiracion_cedula:Variant = null, carrera:Variant = null
) -> AbstractNPC:
	
	var nuevo_delincuente = NPCDelincuente.new()
	
	nuevo_delincuente.nombre = nombre
	nuevo_delincuente.personalidad = personalidad
	nuevo_delincuente.ruta_sprite_npc = ruta_sprite_npc
	
	# Generador de incidencias
	GeneradorIncidencias.generar_incidencias(nuevo_delincuente)
	
	return nuevo_delincuente
