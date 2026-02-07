## Reporte: Objeto de escritorio que permite al guardia reportar incidencias
## Click para abrir el formulario de reporte
extends Area2D

signal reporte_solicitado()

func _ready():
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[REPORTE] Guardia solicita formulario de reporte")
		reporte_solicitado.emit()
