extends Sprite2D

# Ajusta el offset desde el inspector si la mano no queda donde quieres
@export var offset_personalizado: Vector2 = Vector2(-37, 110)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	z_index = 10

func _process(_delta):
	# Esto es 1:1 real, sigue al mouse sin retraso y respetando la cámara
	global_position = get_global_mouse_position() + offset_personalizado
