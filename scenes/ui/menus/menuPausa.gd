extends Control

# --- CONFIGURACIÓN DE RUTAS ---
var ruta_menu_principal = "res://scenes/ui/menus/menuPrincipal.tscn"
var ruta_opciones = "res://scenes/ui/menus/opciones.tscn"
# ¡OJO! Asegúrate de crear esta escena y poner la ruta correcta aquí:
var ruta_confirmacion = "res://scenes/ui/menus/menuConfirmar.tscn"

# --- REFERENCIAS A LOS BOTONES ---
# Agregué la referencia al contenedor para poder ocultar TODO el bloque de botones
@onready var contenedor_botones = $ColorRect/VBoxContainer2
@onready var btn_continuar = $ColorRect/VBoxContainer2/VBoxContainer/btnContinuar
@onready var btn_opciones = $ColorRect/VBoxContainer2/VBoxContainer/btnOpciones
@onready var btn_salir = $ColorRect/VBoxContainer2/VBoxContainer/btnSalirAlMenu

# Variable para controlar si hay una sub-ventana abierta
var ventana_activa = null

func _ready():
	# Conectamos las señales
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_opciones.pressed.connect(_on_opciones_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)

func _on_continuar_pressed():
	get_tree().paused = false
	queue_free()

func _on_opciones_pressed():
	_abrir_ventana_encima(ruta_opciones)

# --- AQUÍ ESTÁ EL CAMBIO PEPOSO ---
func _on_salir_pressed():
	# En vez de irse de una, abrimos la confirmación
	_abrir_ventana_encima(ruta_confirmacion)

# Función auxiliar para no repetir código (sirve para Opciones y Confirmación)
func _abrir_ventana_encima(ruta_escena):
	if ventana_activa == null:
		# 1. Instanciamos la ventana nueva (opciones o confirmación)
		ventana_activa = load(ruta_escena).instantiate()
		add_child(ventana_activa)
		
		# 2. Ocultamos los botones del menú de pausa para que se vea limpio
		contenedor_botones.visible = false
		
		# 3. TRUCAZO: Detectamos cuando esa ventana se cierre (queue_free)
		# Cuando se cierre, volvemos a mostrar los botones automáticamente
		ventana_activa.tree_exited.connect(func():
			contenedor_botones.visible = true
			ventana_activa = null
		)

# Esta función detecta si aplastan ESC
func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pausa"):
		# Si hay una ventana abierta (opciones o confirmación), la cerramos primero
		if ventana_activa != null:
			ventana_activa.queue_free()
		else:
			# Si no hay nada abierto, continuamos el juego
			_on_continuar_pressed()
