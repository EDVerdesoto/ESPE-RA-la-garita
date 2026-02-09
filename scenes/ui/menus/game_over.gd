extends Control

const MAX_ERRORES_DIARIOS = 3

@onready var btn_regresar = $TextureRect/btn_regresar

func _ready():
	# Aseguramos que funcione aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	btn_regresar.pressed.connect(_on_regresar_pressed)

func _on_regresar_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/menus/menuPrincipal.tscn")
