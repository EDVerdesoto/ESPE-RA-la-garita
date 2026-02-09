extends Control

# Pon aquí la ruta EXACTA de tu menú principal
var ruta_menu_principal = "res://scenes/ui/menus/menuPrincipal.tscn"

# Referencias (Ajusta las rutas si cambias algo en el árbol)
@onready var slider_volumen = $ColorRect2/VBoxContainer/VBox_Titulo/VBoxVolumen/slider_volumen
@onready var check_pantalla = $ColorRect2/VBoxContainer/VBox_Titulo/HBoxContainer/chck_full
@onready var btn_regresar = $ColorRect2/VBoxContainer/VBox_Titulo/btn_regresar

func _ready():
	# IMPORTANTE: Esto permite que funcione aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	btn_regresar.pressed.connect(_on_regresar_pressed)
	slider_volumen.value_changed.connect(_on_volumen_changed)
	check_pantalla.toggled.connect(_on_pantalla_toggled)
	
	# Configurar estado visual inicial
	check_pantalla.button_pressed = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
	var bus_index = AudioServer.get_bus_index("Master")
	slider_volumen.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func _on_regresar_pressed():
	# --- AQUÍ ESTÁ LA MAGIA INTELIGENTE ---
	
	# Preguntamos: "¿Quién es mi papá?"
	# Si mi papá es el "root" (la raíz del juego), significa que yo soy la escena principal.
	# (Esto pasa cuando vienes del Menú Principal con change_scene)
	if get_parent() == get_tree().root:
		# Entonces, tengo que cargar de nuevo el menú principal
		get_tree().change_scene_to_file(ruta_menu_principal)
		
	else:
		# Si mi papá NO es el root (es el menú de pausa o un CanvasLayer),
		# significa que soy una ventana emergente.
		# (Esto pasa cuando vienes del Menú Pausa con add_child)
		queue_free() # Solo me muero y muestro lo que hay abajo

func _on_volumen_changed(valor):
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))

func _on_pantalla_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
