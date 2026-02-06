extends CanvasLayer

@onready var label = $TiempoLabel
@onready var timer = $Cronometro
@onready var estudiante = $"../Estudiante" # Ajusta la ruta si es necesario

func _process(_delta):
	if not timer.is_stopped():
		# Actualiza el texto del label con el tiempo que queda
		label.text = "Tiempo: " + str(int(timer.time_left))

# Función para que el NPC llame cuando llegue a la ventanilla
func empezar_conteo():
	timer.start()

func _on_cronometro_timeout():
	# Cuando el tiempo llega a cero, el NPC se va
	if estudiante:
		estudiante.iniciar_salida()
	label.text = "TIEMPO AGOTADO!!!! El estudiante entró sin autorización"
