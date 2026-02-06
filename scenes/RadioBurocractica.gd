extends Area2D

@onready var reproductor = get_node("../../../ReproductorMusica")
var lista_canciones = []
var cancion_actual = 0
var ruta_musica = "res://music/"

func _ready():
	cargar_canciones_automaticamente()
	if lista_canciones.size() > 0:
		# Generar un índice aleatorio entre 0 y el total de canciones disponibles
		cancion_actual = randi() % lista_canciones.size()
		reproducir_cancion(cancion_actual)

func cargar_canciones_automaticamente():
	var dir = DirAccess.open(ruta_musica)
	if dir:
		dir.list_dir_begin()
		var nombre_archivo = dir.get_next()
		while nombre_archivo != "":
			if not dir.current_is_dir() and (nombre_archivo.ends_with(".mp3") or nombre_archivo.ends_with(".ogg")):
				lista_canciones.append(ruta_musica + nombre_archivo)
			nombre_archivo = dir.get_next()
		dir.list_dir_end()

func reproducir_cancion(indice):
	cancion_actual = indice
	var stream = load(lista_canciones[cancion_actual])
	reproductor.stream = stream
	reproductor.play()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Clic izquierdo: Siguiente canción
			cancion_actual = (cancion_actual + 1) % lista_canciones.size()
			reproducir_cancion(cancion_actual)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Clic derecho: Detener o Reanudar
			if reproductor.playing:
				reproductor.stop()
			else:
				reproductor.play()

# Para que cambie sola cuando termine
func _on_reproductor_musica_finished():
	cancion_actual = (cancion_actual + 1) % lista_canciones.size()
	reproducir_cancion(cancion_actual)
