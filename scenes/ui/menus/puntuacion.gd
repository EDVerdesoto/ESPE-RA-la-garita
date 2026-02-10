## Puntuación: Pantalla de Informe de Fin de Día
## Muestra el resumen basado en post-acciones del día
extends Control

signal continuar_pressed()  ## Se emite cuando el jugador cierra el reporte

# --- Referencias a los nodos de la escena ---
@onready var lbl_titulo = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblTitulo
@onready var lbl_dia = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblDiaActual
@onready var lbl_dinero_total = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblDineroTotal
@onready var lbl_paga_diaria = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblPagaDiaria
@onready var lbl_balance_mensaje = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblBalanceMensaje
@onready var lbl_balance_dinero = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblBalanceDinero
@onready var lbl_post_actions = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblPostActions
@onready var lbl_gastos = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/lblGastosDiarios
@onready var btn_continuar = $ColorRect/VBox_Principal/VBox_TituloSello/TextureRect/Button


# Datos del resumen del día (se asignan desde fuera con configurar())
var resumen_data: Dictionary = {}
# Si true, se usa como pantalla de estadísticas globales (menú principal)
var modo_historico: bool = false

func _ready():
	btn_continuar.pressed.connect(_on_btn_continuar_pressed)
	
	if not resumen_data.is_empty():
		_mostrar_resumen_dia()
	else:
		modo_historico = true
		GlobalGameManager.slot_actual = 1
		SaveManager.cargar_partida()
		_mostrar_historico()

## Configura el panel con los datos del resumen del día.
## Llamar ANTES de agregarlo al árbol o en _ready().
func configurar(resumen: Dictionary) -> void:
	resumen_data = resumen
	modo_historico = false
	if is_inside_tree():
		_mostrar_resumen_dia()

# =====================================================
# MODO INFORME DE FIN DE DÍA
# =====================================================

func _mostrar_resumen_dia() -> void:
	var dia = resumen_data.get("dia", 1)
	var sueldo = resumen_data.get("sueldo_base", 20.0)
	var total_dia = resumen_data.get("total_dia", 0.0)
	var dinero_final = resumen_data.get("dinero_final", 0.0)
	var todas_post_actions: Array = resumen_data.get("todas_post_actions", [])
	var gastos_fijos = resumen_data.get("gastos_fijos", 15.0)
	
	# --- Título y día ---
	if lbl_titulo:
		lbl_titulo.text = "Informe de Día"
	if lbl_dia:
		lbl_dia.visible = true
		lbl_dia.text = str(dia)
	
	# --- Dinero actual (billetera acumulada) ---
	if lbl_dinero_total:
		lbl_dinero_total.text = "$ %.2f" % dinero_final
	
	# --- Paga del día (sueldo base fijo) ---
	if lbl_paga_diaria:
		lbl_paga_diaria.text = "$ %.2f" % sueldo
	
	# --- Balance del día (total neto: sueldo + post-actions - gastos) ---
	if lbl_balance_dinero:
		lbl_balance_dinero.text = "$ %.2f" % total_dia
		if total_dia >= 0:
			lbl_balance_dinero.modulate = Color(0.2, 0.8, 0.2)
		else:
			lbl_balance_dinero.modulate = Color(1.0, 0.3, 0.3)
	
	if lbl_gastos:
		lbl_gastos.text = "$ %.2f" % gastos_fijos
	
	# --- Lista de post-acciones del día ---
	if lbl_post_actions:
		_mostrar_lista_post_actions(todas_post_actions)

## Construye el texto de resumen de post-acciones del día
func _mostrar_lista_post_actions(post_actions: Array) -> void:
	if not lbl_post_actions:
		return
	
	if post_actions.is_empty():
		lbl_post_actions.text = "Día tranquilo. Ningún incidente reportado."
		lbl_post_actions.modulate = Color(0.25, 0.18, 0.12, 0.9)
		return
	
	var lineas: Array = []
	for pa in post_actions:
		var texto = pa.get("texto", "")
		var valor = pa.get("valor", 0.0)
		
		if valor < 0:
			lineas.append("%s  ($%.0f)" % [texto, valor])
		elif valor > 0:
			lineas.append("%s  (+$%.0f)" % [texto, valor])
		else:
			lineas.append(texto)
	
	lbl_post_actions.text = "\n".join(lineas)
	
	# Color según gravedad
	var tiene_graves = not resumen_data.get("graves", []).is_empty()
	if tiene_graves:
		lbl_post_actions.modulate = Color(0.6, 0.15, 0.1, 0.95)
	else:
		lbl_post_actions.modulate = Color(0.25, 0.18, 0.12, 0.9)

# =====================================================
# MODO HISTÓRICO (Estadísticas globales desde menú)
# =====================================================

func _mostrar_historico() -> void:
	if lbl_titulo:
		lbl_titulo.text = "Puntuación Total"
	if lbl_dia:
		lbl_dia.visible = false
	
	if lbl_dinero_total:
		lbl_dinero_total.text = "$ %.2f" % GlobalGameManager.dinero
	
	if lbl_paga_diaria:
		lbl_paga_diaria.text = "$ %.2f" % GlobalGameManager.sueldo_base
	
	if lbl_balance_dinero:
		lbl_balance_dinero.text = "$ %.2f" % GlobalGameManager.dinero
		if GlobalGameManager.dinero >= 0:
			lbl_balance_dinero.modulate = Color(0.2, 0.8, 0.2)
		else:
			lbl_balance_dinero.modulate = Color(1.0, 0.3, 0.3)
	
	if lbl_post_actions:
		lbl_post_actions.text = ""

# =====================================================
# BOTÓN CONTINUAR
# =====================================================

func _on_btn_continuar_pressed():
	if modo_historico:
		get_tree().change_scene_to_file("res://scenes/ui/menus/menuPrincipal.tscn")
	else:
		continuar_pressed.emit()
