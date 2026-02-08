extends Control

# --- CONFIGURACIÓN DE RUTAS ---
# Asegúrate de que estas rutas sean las correctas en tu proyecto
var ruta_menu_principal = "res://scenes/ui/menus/menuPrincipal.tscn"
var ruta_opciones = "res://scenes/ui/menus/opciones.tscn"

# --- REFERENCIAS A LOS BOTONES ---
# Arrastra los nodos de los botones al script presionando CTRL si estas rutas fallan
@onready var btn_continuar = $ColorRect/VBoxContainer2/VBoxContainer/btnContinuar
@onready var btn_opciones = $ColorRect/VBoxContainer2/VBoxContainer/btnOpciones
@onready var btn_salir = $ColorRect/VBoxContainer2/VBoxContainer/btnSalirAlMenu

func _ready():
	# Nos aseguramos de conectar las señales cuando nace el menú
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_opciones.pressed.connect(_on_opciones_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)

func _on_continuar_pressed():
	# 1. Descongelamos el juego
	get_tree().paused = false
	# 2. Matamos este menú de pausa
	queue_free()

func _on_opciones_pressed():
	# Instanciamos la escena de opciones encima de esta
	var escena_opciones = load(ruta_opciones).instantiate()
	add_child(escena_opciones)
	# Opcional: Si quieres ocultar los botones de pausa mientras estás en opciones:
	# $ColorRect.visible = false 

func _on_salir_pressed():
	# ¡IMPORTANTE! Siempre descongelar antes de cambiar de escena
	# Si no lo haces, el menú principal cargará congelado
	get_tree().paused = false
	
	# Cambiamos a la escena del menú principal
	get_tree().change_scene_to_file(ruta_menu_principal)

# Esta función detecta si aplastan ESC de nuevo para cerrar
func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pausa"):
		# Llamamos a la misma función de continuar
		_on_continuar_pressed()
