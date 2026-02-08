extends Control

# Referencias
@onready var slider_volumen = $ColorRect2/VBoxContainer/VBox_Titulo/VBoxVolumen/slider_volumen
@onready var check_pantalla = $ColorRect2/VBoxContainer/VBox_Titulo/HBoxContainer/chck_full
@onready var btn_regresar = $ColorRect2/VBoxContainer/VBox_Titulo/btn_regresar

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

func _on_pantalla_toggled(toggled_on):
	if toggled_on:
		# Cambiar a Pantalla Completa
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Regresar a Ventana
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Opcional: Centrar la ventana al salir
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
