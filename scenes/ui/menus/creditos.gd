extends Control
@onready var btn_regresar = $ColorRect/VBox_Principal/btnRegresar

func _ready ():
	if btn_regresar:
		btn_regresar.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/menus/menuPrincipal.tscn"))
