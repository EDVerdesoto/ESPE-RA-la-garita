# NPCGenerico.gd
class_name NPCGenerico
extends AbstractNPC

var carrera: String

func post_accion():
	print(nombre, " entra tranquilamente a la ESPE.")
