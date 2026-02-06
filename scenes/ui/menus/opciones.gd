extends Control

# Referencias
@onready var slider_volumen = $ColorRect2/VBox_Principal/VBox_Titulo/slider_volumen
@onready var check_pantalla = $ColorRect2/VBox_Principal/VBox_Titulo/HBoxContainer/chck_full
@onready var btn_regresar = $ColorRect2/VBox_Principal/VBox_Titulo/btn_regresar

func _ready():
	# Conectamos señales
	btn_regresar.pressed.connect(_on_regresar_pressed)
	slider_volumen.value_changed.connect(_on_volumen_changed)
	check_pantalla.toggled.connect(_on_pantalla_toggled)
	
	# Poner el estado actual (para que el botón no mienta)
	check_pantalla.button_pressed = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
	
	# Poner volumen actual
	var bus_index = AudioServer.get_bus_index("Master")
	slider_volumen.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func _on_regresar_pressed():
	# Si tenemos guardado a donde volver, vamos allá
	if GlobalGameManager.escena_retorno != "":
		get_tree().change_scene_to_file(GlobalGameManager.escena_retorno)
	else:
		# Por si acaso, volvemos al menú
		get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")
		
func _on_volumen_changed(valor):
	# Convertimos de lineal (0 a 1) a Decibeles
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))

func _on_pantalla_toggled(esta_activo):
	var ventana = get_window()
	
	if esta_activo:
		# Intentamos Exclusive (el mejor), si falla, usa el Fullscreen normal
		ventana.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		if ventana.mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
			ventana.mode = Window.MODE_FULLSCREEN
	else:
		ventana.mode = Window.MODE_WINDOWED
