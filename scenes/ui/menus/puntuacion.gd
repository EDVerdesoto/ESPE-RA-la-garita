extends Control

# Rutas basadas en tu imagen del árbol de nodos (image_fca207.png)
@onready var lbl_titulo = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblTitulo
@onready var lbl_dia = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblDiaActual
@onready var lbl_dinero_total = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblDineroTotal
@onready var lbl_aciertos_num = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblAciertos
@onready var lbl_aciertos_plata = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblAciertosDinero
@onready var lbl_errores_num = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblErrores
@onready var lbl_descuentos = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblDescuentos
@onready var lbl_balance_mensaje = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblBalanceMensaje
@onready var lbl_balance_dinero = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblBalanceDinero
@onready var btn_continuar = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/Button

func _ready():
	# 1. FORZAR CARGA DEL SLOT 1
	# Como dijiste, siempre coge la partida del primer slot para mostrar estadísticas
	GlobalGameManager.slot_actual = 1
	SaveManager.cargar_partida()
	
	# 2. Configurar Textos Estáticos
	lbl_titulo.text = "PUNTUACIÓN"
	lbl_dia.visible = false # Ocultamos el día actual
	lbl_balance_mensaje.text = "BALANCE TOTAL:"
	
	# 3. Mostrar Datos Totales (Históricos)
	actualizar_interfaz()
	
	# 4. Conectar botón
	btn_continuar.pressed.connect(_on_btn_continuar_pressed)

func actualizar_interfaz():
	# Dinero Total Acumulado (Arriba)
	lbl_dinero_total.text = "%.2f" % GlobalGameManager.dinero
	
	# Aciertos Totales
	var aciertos = GlobalGameManager.aciertos_totales
	var plata_aciertos = aciertos * GlobalGameManager.pago_por_acierto
	lbl_aciertos_num.text = "(%d):" % aciertos
	lbl_aciertos_plata.text = "%.2f" % plata_aciertos
	
	# Errores Totales
	var errores = GlobalGameManager.errores_totales
	var plata_errores = errores * GlobalGameManager.multa_por_error
	lbl_errores_num.text = "(%d):" % errores
	lbl_descuentos.text = "%.2f" % plata_errores
	
	# Balance Total (Es lo mismo que el dinero total, pero abajo en grande)
	lbl_balance_dinero.text = "$%.2f" % GlobalGameManager.dinero
	
	# Color del balance
	if GlobalGameManager.dinero >= 0:
		lbl_balance_dinero.modulate = Color.GREEN
	else:
		lbl_balance_dinero.modulate = Color.RED

func _on_btn_continuar_pressed():
	# Regresar al Menú Principal
	get_tree().change_scene_to_file("res://scenes/ui/menus/menuPrincipal.tscn")
