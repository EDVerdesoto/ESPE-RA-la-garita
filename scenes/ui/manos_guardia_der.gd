extends Sprite2D

# --- TEXTURAS (IMÁGENES) ---
# Arrastra aquí tus imágenes desde el FileSystem
@export var textura_mano_normal: Texture2D 
@export var textura_escaner: Texture2D     

# --- CONFIGURACIÓN ---
@export var offset_personalizado: Vector2 = Vector2(-37, 110)

# Definimos el área del carnet basada en tus datos:
# X: 2845 a 2903 -> Ancho = 58
# Y: 479 a 573.5 -> Alto = 94.5
var zona_carnet = Rect2(2845, 479, 58, 94.5)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	z_index = 100 # Le subí a 100 por si acaso el HUD te lo tape
	
	# Empezamos con la mano normal por defecto
	if textura_mano_normal:
		texture = textura_mano_normal

func _process(_delta):
	# 1. Obtenemos la posición REAL del mouse (sin el offset de la mano)
	# Usamos esto para chequear si el PUNTERO toca el carnet, no la imagen de la mano
	var mouse_pos = get_global_mouse_position()
	
	# 2. Movemos la mano visualmente (con tu offset)
	global_position = mouse_pos + offset_personalizado
	
	# 3. Lógica del cambio de herramienta
	# ¿El puntero del mouse está dentro del rectángulo?
	if zona_carnet.has_point(mouse_pos):
		# CAMBIAR A ESCÁNER
		# El 'if' extra es para no cargar la textura 60 veces por segundo, solo si cambió
		if texture != textura_escaner and textura_escaner:
			texture = textura_escaner
			# Opcional: Si el escáner necesita otro offset, cámbialo aquí
			# offset_personalizado = Vector2(-20, 50) 
	else:
		# VOLVER A MANO NORMAL
		if texture != textura_mano_normal and textura_mano_normal:
			texture = textura_mano_normal
			# offset_personalizado = Vector2(-37, 110) # Restaurar offset original
