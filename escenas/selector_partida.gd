extends Control

# --- REFERENCIAS A LOS BOTONES (Para detectar el clic) ---
@onready var btn_slot_1 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot1
@onready var btn_slot_2 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot2
@onready var btn_slot_3 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot3
@onready var btn_regresar = $ColorRect/VBoxContainer/MarginContainer/btn_regresar

# --- REFERENCIAS A LOS TEXTOS (Para cambiar lo que dicen) ---
@onready var titulo_1 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot1/MarginContainer/MarginContainer/VBoxContainer/lblTitulo
@onready var detalle_1 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot1/MarginContainer/MarginContainer/VBoxContainer/lblDetalles

@onready var titulo_2 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot2/MarginContainer/MarginContainer/VBoxContainer/lblTitulo
@onready var detalle_2 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot2/MarginContainer/MarginContainer/VBoxContainer/lblDetalles

@onready var titulo_3 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot3/MarginContainer/MarginContainer/VBoxContainer/lblTitulo
@onready var detalle_3 = $ColorRect/VBoxContainer/HBoxContainer/BtnSlot3/MarginContainer/MarginContainer/VBoxContainer/lblDetalles

func _ready():
	actualizar_info_visual(1, titulo_1, detalle_1)
	actualizar_info_visual(2, titulo_2, detalle_2)
	actualizar_info_visual(3, titulo_3, detalle_3)
	
	# Conectamos las señales de clic
	btn_slot_1.pressed.connect(func(): _jugar_slot(1))
	btn_slot_2.pressed.connect(func(): _jugar_slot(2))
	btn_slot_3.pressed.connect(func(): _jugar_slot(3))
	
	# Conectar regresar (si no existe el nodo te dará error, ¡créalo!)
	if btn_regresar:
		btn_regresar.pressed.connect(func(): get_tree().change_scene_to_file("res://escenas/menu_principal.tscn"))

func actualizar_info_visual(num_slot, lbl_tit, lbl_det):
	var info = SaveManager.obtener_info_resumida(num_slot)
	
	if info == "VACÍO":
		lbl_tit.text = "VACÍO"
		lbl_det.text = "Nueva partida"
		# Aquí podrías cambiar el color si quieres que se vea apagado
	else:
		lbl_tit.text = "ARCHIVO " + str(num_slot)
		lbl_det.text = info # Ej: "DÍA 5 | $120"

func _jugar_slot(num: int):
	GlobalGameManager.slot_actual = num
	var info = SaveManager.obtener_info_resumida(num)
	
	if info == "VACÍO":
		print("Creando nueva partida en slot ", num)
		GlobalGameManager.reiniciar_datos()
		SaveManager.guardar_partida()
	else:
		print("Cargando partida existente...")
		SaveManager.cargar_partida()
	
	get_tree().change_scene_to_file("res://escenas/mesa principal.tscn")
