extends CanvasLayer

# Señal que se emite cuando el tiempo se agota
signal tiempo_agotado

@onready var label = $TiempoLabel
@onready var timer = $Cronometro

func _process(_delta):
	if not timer.is_stopped():
		label.text = "Tiempo: " + str(int(timer.time_left))

# Función para que se llame (vía señal) cuando el NPC llegue a la ventanilla
func empezar_conteo():
	timer.start()

func _on_cronometro_timeout():
	label.text = "TIEMPO AGOTADO!!!! El estudiante entró sin autorización"
	tiempo_agotado.emit()
