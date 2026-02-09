extends Area2D

@onready var audio = $AudioStreamPlayer

func _ready():
	# Esto es vital para que el mouse detecte al Area2D
	input_pickable = true

func _input_event(viewport, event, shape_idx):
	# Detectamos clic izquierdo
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if audio.stream:
			# Un poquito de variedad en el tono (opcional)
			audio.pitch_scale = randf_range(0.95, 1.05)
			audio.play()
			print("Gato: ¡MIAU!")
		else:
			print("Ñaño, carga el sonido en el AudioStreamPlayer")
