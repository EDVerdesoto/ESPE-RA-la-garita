extends CanvasLayer

# Rutas según tu foto image_f96180.png
@onready var lbl_cargando = $ColorRect/lbl_cargando
@onready var anim_player = $AnimationPlayer
@onready var icono_carga = $ColorRect/iconoCarga # Referencia al icono

# Las frases del guardia
var frases = [
	"Buscando las llaves del portón principal...",
	"Preparando el café para aguantar el frío...",
	"Revisando la bitácora de novedades...",
	"Lustrando las botas para la inspección...",
	"Verificando que llevaste el almuerzo...",
	"Analizando la foto del gato...",
	"Viendo las baterias de la radio...",
	"Rezando para que no lleguen los de PAFDE...",
	"Conectando al Wi-Fi de la U...",
	"Conversando con la seño de los sánduches...",
	"¿Si leyeron todo?",
	"Repasando los 10 mandamientos del guardia de garita...",
	"Practicando mi cara de 'Tenga la bondad joven'...",
	"Agarrando la plata que es para el papel...",
	"¿Neblina? No, es el alma de los que perdieron el semestre flotando por el campus"
]

var frases_disponibles: Array = []

func _ready():
	# 1. Animamos el ícono de carga para que gire siempre
	# Creamos una interpolación simple (Tween) para rotar
	var tween = create_tween().set_loops()
	tween.tween_property(icono_carga, "rotation_degrees", 360, 1.2).from(0.0)
	frases_disponibles = frases.duplicate()
	
	# 2. Iniciamos el sistema de frases
	cambiar_frase()
	anim_player.play("cambio_frase")
	
	# Conectamos la señal para saber cuando termina la animación
	anim_player.animation_finished.connect(_on_animation_finished)

func cambiar_frase():
	if frases_disponibles.is_empty():
		frases_disponibles = frases.duplicate()
	
	var frase_elegida = frases_disponibles.pick_random()
	
	frases_disponibles.erase(frase_elegida)
	
	lbl_cargando.text = frase_elegida

func _on_animation_finished(anim_name):
	# Si terminó la animación (el texto ya se hizo invisible)...
	if anim_name == "cambio_frase":
		cambiar_frase()      # Cambiamos el texto
		anim_player.play("cambio_frase") # Reproducimos de nuevo
