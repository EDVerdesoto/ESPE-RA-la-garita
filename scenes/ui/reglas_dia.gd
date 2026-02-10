extends CanvasLayer

@onready var lbl_reglas = $TextureRect/lblReglas

func _ready():
	# Leer las reglas generadas durante la pantalla de carga
	if GlobalGameManager.reglas_texto_dia.is_empty():
		lbl_reglas.text = "Sin disposiciones especiales hoy.\nRevise documentos como de costumbre."
	else:
		lbl_reglas.text = GlobalGameManager.reglas_texto_dia

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Clic en cualquier lugar cierra el panel
		queue_free()
