## CarpetaDocumentos: Contiene las reglas/normas que el guardia puede consultar
## (Lista negra, reglamento de la ESPE, etc.)
extends Area2D

signal carpeta_abierta()
signal carpeta_cerrada()

var esta_abierta: bool = false

func _ready():
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if esta_abierta:
			cerrar()
		else:
			abrir()

func abrir():
	esta_abierta = true
	print("[CARPETA] Carpeta abierta - mostrando reglamento")
	carpeta_abierta.emit()

func cerrar():
	esta_abierta = false
	print("[CARPETA] Carpeta cerrada")
	carpeta_cerrada.emit()
