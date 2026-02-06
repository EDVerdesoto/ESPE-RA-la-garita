extends Control

# --- REFERENCIAS A TUS NODOS (Rutas exactas según tu foto) ---
# Usamos el contenedor para ocultarlo si no hay partida y que no quede hueco
@onready var boton_continuar = $ColorRect/VBox_Principal/VBox_botones/btn_continuar

@onready var boton_nuevo_turno = $ColorRect/VBox_Principal/VBox_botones/Fila1/btn_nuevoTurno
@onready var boton_puntuacion = $ColorRect/VBox_Principal/VBox_botones/Fila1/btn_puntuacion

@onready var boton_opciones = $ColorRect/VBox_Principal/VBox_botones/Fila2/btn_opciones
@onready var boton_creditos = $ColorRect/VBox_Principal/VBox_botones/Fila2/btn_creditos
@onready var boton_salir = $ColorRect/VBox_Principal/VBox_botones/Fila2/btn_salir

# Ruta del archivo de guardado
const RUTA_GUARDADO = "user://guardado.save"

func _ready():
	# --- PRUEBA TEMPORAL ---
	if GlobalGameManager.dia_actual == 1:
		print("SIMULACIÓN")
		GlobalGameManager.aciertos_hoy = 5
		GlobalGameManager.calcular_fin_de_dia()
	verificar_partida_guardada()
	conectar_botones()
	

func verificar_partida_guardada():
	# Si existe el archivo de guardado...
	if FileAccess.file_exists(RUTA_GUARDADO):
		boton_continuar.visible = true # Mostramos el contenedor
		boton_continuar.disabled = false
	else:
		# Si NO hay partida, ocultamos todo el contenedor para que la lista suba
		boton_continuar.visible = false 

func conectar_botones():
	# Conectamos las señales de TODOS tus botones
	if boton_continuar: boton_continuar.pressed.connect(_on_continuar_pressed)
	boton_nuevo_turno.pressed.connect(_on_nuevo_turno_pressed)
	boton_puntuacion.pressed.connect(_on_puntuacion_pressed)
	boton_opciones.pressed.connect(_on_opciones_pressed)
	boton_creditos.pressed.connect(_on_creditos_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)

# --- FUNCIONES DE ACCIÓN ---

func _on_continuar_pressed():
	print("Continuando partida...")
	get_tree().change_scene_to_file("res://escenas/SelectorPartida.tscn")
	

func _on_nuevo_turno_pressed():
	print("Iniciando nuevo turno...")
	get_tree().change_scene_to_file("res://escenas/SelectorPartida.tscn")

func _on_puntuacion_pressed():
	print("Abriendo puntuación...")
	get_tree().change_scene_to_file("res://escenas/puntuacion.tscn")

func _on_opciones_pressed():
	print("Abriendo opciones...")
	get_tree().change_scene_to_file("res://escenas/opciones.tscn")

func _on_creditos_pressed():
	print("Mostrando créditos...")
	get_tree().change_scene_to_file("res://escenas/creditos.tscn")

func _on_salir_pressed():
	print("Saliendo del juego...")
	get_tree().quit()
