extends Control

# Ruta al menú principal para irnos allá si dice que SIMÓN
var ruta_menu_principal = "res://scenes/ui/menus/menuPrincipal.tscn"

# Usa %NombreUnico si puedes, si no ajusta la ruta a tus botones
@onready var btn_si = $ColorRect/VBoxContainer/VBoxContainer2/btnSalir
@onready var btn_no = $ColorRect/VBoxContainer/VBoxContainer2/btnRegresar

func _ready():
	# Conectamos las señales
	btn_si.pressed.connect(_on_btn_si_pressed)
	btn_no.pressed.connect(_on_btn_no_pressed)

func _on_btn_si_pressed():
	# 1. ¡IMPORTANTE! Descongelamos el juego antes de irnos
	get_tree().paused = false
	
	# 2. Nos fuimos al menú principal
	get_tree().change_scene_to_file(ruta_menu_principal)

func _on_btn_no_pressed():
	# Si se arrepiente, solo matamos esta ventanita
	queue_free()
	# Al morirse, el script del menú de pausa detectará que se cerró
	# y volverá a mostrar los botones de pausa.
