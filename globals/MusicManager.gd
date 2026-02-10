## MusicManager: Autoload global que maneja la música de fondo
## La música persiste entre cambios de escena hasta que se pida detener
extends Node

var reproductor: AudioStreamPlayer = null
var cancion_actual: String = ""

func _ready():
	reproductor = AudioStreamPlayer.new()
	reproductor.bus = "Master"
	add_child(reproductor)

## Reproduce una canción. Si ya está sonando la misma, no reinicia.
func reproducir(ruta: String, volumen_db: float = 0.0) -> void:
	if cancion_actual == ruta and reproductor.playing:
		return  # Ya está sonando esta canción
	var stream = load(ruta)
	if stream:
		reproductor.stream = stream
		reproductor.volume_db = volumen_db
		reproductor.play()
		cancion_actual = ruta
		print("[MusicManager] Reproduciendo: ", ruta)
	else:
		push_warning("[MusicManager] No se pudo cargar: " + ruta)

## Detiene la música actual
func detener() -> void:
	reproductor.stop()
	cancion_actual = ""
	print("[MusicManager] Música detenida")

## Cambia el volumen sin reiniciar la canción
func set_volumen(db: float) -> void:
	reproductor.volume_db = db
