extends Node2D

# Variables para arrastrar los nodos desde el Inspector
@export_group("Fondos Derecha")
@export var n_soleado: Sprite2D
@export var n_nublado: Sprite2D
@export var n_lluvioso: Sprite2D # El que tiene calles mojadas

@export_group("Fondos Izquierda")
@export var i_soleado: Sprite2D
@export var i_nublado: Sprite2D
@export var i_lluvioso: Sprite2D

@export_group("Efectos")
@export var lluvia_particulas: CPUParticles2D

# Estados del clima en orden lineal
enum Clima { SOLEADO, NUBLADO, LLUVIOSO, MOJADO }
var estado_actual: int

func _ready():
	# 1. Elegir un clima aleatorio para empezar de una
	estado_actual = randi() % 4 
	
	# 2. Configurar visuales iniciales sin transiciones (de golpe)
	aplicar_clima_instantaneo()
	
	# 3. Timer para "tirar el dado" cada 20 segundos
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(_intentar_cambio_clima)
	add_child(timer)

func _intentar_cambio_clima():
	# Tirar el dado (1 de 5 posibilidades)
	if randi_range(3, 3) == 3:
		avanzar_clima()

func avanzar_clima():
	# Flujo lineal: Soleado -> Nublado -> Lluvioso -> Mojado -> Soleado
	estado_actual = (estado_actual + 1) % 4
	transicion_suave_clima()

func aplicar_clima_instantaneo():
	# Apagamos todo de una para el inicio del juego
	for s in [n_soleado, n_nublado, n_lluvioso, i_soleado, i_nublado, i_lluvioso]:
		s.modulate.a = 0
	
	lluvia_particulas.emitting = (estado_actual == Clima.LLUVIOSO)
	
	# Prendemos los que corresponden al estado aleatorio inicial
	match estado_actual:
		Clima.SOLEADO:
			n_soleado.modulate.a = 1; i_soleado.modulate.a = 1
		Clima.NUBLADO:
			n_nublado.modulate.a = 1; i_nublado.modulate.a = 1
		Clima.LLUVIOSO, Clima.MOJADO:
			n_lluvioso.modulate.a = 1; i_lluvioso.modulate.a = 1

func transicion_suave_clima():
	var tween = create_tween().set_parallel(true)
	
	# Desvanecer todos los fondos actuales
	for s in [n_soleado, n_nublado, n_lluvioso, i_soleado, i_nublado, i_lluvioso]:
		tween.tween_property(s, "modulate:a", 0.0, 3.0)
	
	# Aparecer los nuevos fondos y activar/desactivar partículas
	match estado_actual:
		Clima.SOLEADO:
			tween.tween_property(n_soleado, "modulate:a", 1.0, 3.0)
			tween.tween_property(i_soleado, "modulate:a", 1.0, 3.0)
			lluvia_particulas.emitting = false
		Clima.NUBLADO:
			tween.tween_property(n_nublado, "modulate:a", 1.0, 3.0)
			tween.tween_property(i_nublado, "modulate:a", 1.0, 3.0)
		Clima.LLUVIOSO:
			tween.tween_property(n_lluvioso, "modulate:a", 1.0, 3.0)
			tween.tween_property(i_lluvioso, "modulate:a", 1.0, 3.0)
			lluvia_particulas.emitting = true
		Clima.MOJADO:
			tween.tween_property(n_lluvioso, "modulate:a", 1.0, 3.0)
			tween.tween_property(i_lluvioso, "modulate:a", 1.0, 3.0)
			lluvia_particulas.emitting = false
