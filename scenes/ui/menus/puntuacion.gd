## Puntuación: Pantalla de Informe de Fin de Día
## Muestra el resumen basado en post-acciones del día
extends Control

signal continuar_pressed()  ## Se emite cuando el jugador cierra el reporte

# --- Referencias a los nodos del template visual ---
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

# Datos del resumen del día (se asignan desde fuera con configurar())
var resumen_data: Dictionary = {}
# Si true, se usa como pantalla de estadísticas globales (menú principal)
var modo_historico: bool = false

func _ready():
	btn_continuar.pressed.connect(_on_btn_continuar_pressed)
	
	if not resumen_data.is_empty():
		# Modo informe de fin de día (dentro del gameplay)
		_mostrar_resumen_dia()
	else:
		# Modo estadísticas globales (acceso desde menú principal)
		modo_historico = true
		GlobalGameManager.slot_actual = 1
		SaveManager.cargar_partida()
		_mostrar_historico()

## Configura el panel con los datos del resumen del día.
## Llamar ANTES de agregarlo al árbol o en _ready().
func configurar(resumen: Dictionary) -> void:
	resumen_data = resumen
	modo_historico = false
	# Si ya está en el árbol, actualizar inmediatamente
	if is_inside_tree():
		_mostrar_resumen_dia()

# =====================================================
# MODO INFORME DE FIN DE DÍA (Post-acciones)
# =====================================================

func _mostrar_resumen_dia() -> void:
	var dia = resumen_data.get("dia", 1)
	var sueldo = resumen_data.get("sueldo_base", 20.0)
	var gastos = resumen_data.get("gastos_fijos", 15.0)
	var total_dia = resumen_data.get("total_dia", 0.0)
	var dinero_final = resumen_data.get("dinero_final", 0.0)
	var aciertos = resumen_data.get("aciertos", 0)
	var errores = resumen_data.get("errores", 0)
	
	# Calcular totales por categoría de post-acción
	var total_buenas: float = 0.0
	var total_malas: float = 0.0  # malas + graves + rechazos
	var buenas: Array = resumen_data.get("buenas", [])
	var malas: Array = resumen_data.get("malas", [])
	var graves: Array = resumen_data.get("graves", [])
	var rechazos: Array = resumen_data.get("rechazos_injustos", [])
	
	for pa in buenas:
		total_buenas += pa.get("valor", 0.0)
	for pa in malas:
		total_malas += abs(pa.get("valor", 0.0))
	for pa in graves:
		total_malas += abs(pa.get("valor", 0.0))
	for pa in rechazos:
		total_malas += abs(pa.get("valor", 0.0))
	
	# También sumar los gastos fijos como descuento
	total_malas += gastos
	
	# --- Llenar labels ---
	lbl_titulo.text = "Informe de Día"
	lbl_dia.visible = true
	lbl_dia.text = str(dia)
	
	# Billetera final (esquina superior)
	lbl_dinero_total.text = "$%.0f" % dinero_final
	
	# Aciertos y recompensas
	lbl_aciertos_num.text = str(aciertos)
	lbl_aciertos_plata.text = "+$%.0f" % (sueldo + total_buenas)
	
	# Errores y descuentos
	lbl_errores_num.text = str(errores)
	lbl_descuentos.text = "-$%.0f" % total_malas
	
	# Balance del día
	lbl_balance_mensaje.text = "Balance de día:"
	lbl_balance_dinero.text = "$%.0f" % total_dia
	
	if total_dia >= 0:
		lbl_balance_dinero.modulate = Color(0.2, 0.8, 0.2)
	else:
		lbl_balance_dinero.modulate = Color(1.0, 0.3, 0.3)

# =====================================================
# MODO HISTÓRICO (Estadísticas globales desde menú)
# =====================================================

func _mostrar_historico() -> void:
	lbl_titulo.text = "Puntuación Total"
	lbl_dia.visible = false
	
	lbl_dinero_total.text = "$%.0f" % GlobalGameManager.dinero
	
	lbl_aciertos_num.text = str(GlobalGameManager.aciertos_totales)
	lbl_aciertos_plata.text = "+$%.0f" % GlobalGameManager.sueldo_base
	
	lbl_errores_num.text = str(GlobalGameManager.errores_totales)
	lbl_descuentos.text = "-$%.0f" % GlobalGameManager.arriendo_diario
	
	lbl_balance_mensaje.text = "Balance Total:"
	lbl_balance_dinero.text = "$%.0f" % GlobalGameManager.dinero
	
	if GlobalGameManager.dinero >= 0:
		lbl_balance_dinero.modulate = Color(0.2, 0.8, 0.2)
	else:
		lbl_balance_dinero.modulate = Color(1.0, 0.3, 0.3)

# =====================================================
# BOTÓN CONTINUAR
# =====================================================

func _on_btn_continuar_pressed():
	if modo_historico:
		get_tree().change_scene_to_file("res://scenes/ui/menus/menuPrincipal.tscn")
	else:
		continuar_pressed.emit()
