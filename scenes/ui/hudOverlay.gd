## HUD Overlay: Muestra información del estado del juego al jugador
extends Control

@onready var lbl_dia: Label = $PanelHUD/LblDia
@onready var lbl_dinero: Label = $PanelHUD/LblDinero
@onready var lbl_aciertos: Label = $PanelHUD/LblAciertos
@onready var lbl_errores: Label = $PanelHUD/LblErrores

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func actualizar(datos: Dictionary) -> void:
	if lbl_dia:
		lbl_dia.text = "DÍA " + str(datos.get("dia", 1))
	if lbl_dinero:
		lbl_dinero.text = "$" + str(datos.get("dinero", 0.0))
	if lbl_aciertos:
		lbl_aciertos.text = "✓ " + str(datos.get("aciertos", 0))
	if lbl_errores:
		lbl_errores.text = "✗ " + str(datos.get("errores", 0))
