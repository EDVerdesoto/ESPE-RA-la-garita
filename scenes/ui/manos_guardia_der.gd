extends Sprite2D

# --- TEXTURAS ---
@export var textura_mano_normal: Texture2D 
@export var textura_escaner: Texture2D      

# --- OFFSETS (VISUALES) ---
# Estos números mueven SOLO EL DIBUJO, no el detector.
@export var offset_mano_normal: Vector2 = Vector2(-25, -10)
@export var offset_escaner: Vector2 = Vector2(0, -70) 

# --- ESCALAS ---
@export var escala_mano_normal: Vector2 = Vector2(0.35, 0.35)
@export var escala_escaner: Vector2 = Vector2(0.5, 0.5)

@onready var detector = $Detector 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	z_index = 100
	
	# Importante: Desactivamos la propiedad "Centered" si usas offsets manuales grandes,
	# pero si tus offsets ya funcionan bien, déjalo como esté.
	centered = false 
	
	activar_mano_normal()
	
	if detector:
		detector.area_entered.connect(_on_detector_area_entered)
		detector.area_exited.connect(_on_detector_area_exited)

func _process(_delta):
	# 1. MOVIMIENTO PURO
	# El Nodo (y el Detector) van EXACTAMENTE a donde está el mouse.
	# ¡Aquí NO sumamos offsets!
	global_position = get_global_mouse_position()

# --- FUNCIONES DE CAMBIO ---

func activar_mano_normal():
	if textura_mano_normal:
		texture = textura_mano_normal
		scale = escala_mano_normal
		
		# MAGIA: Usamos la propiedad nativa 'offset' del Sprite2D.
		# Esto mueve la pintura pero deja el nodo (y el detector) quietos en el mouse.
		offset = offset_mano_normal

func activar_escaner():
	if textura_escaner:
		texture = textura_escaner
		scale = escala_escaner
		
		# MAGIA: Cambiamos donde se pinta el escáner visualmente.
		offset = offset_escaner

# --- SEÑALES ---

func _on_detector_area_entered(area):
	if area.is_in_group("carnet"):
		activar_escaner()

func _on_detector_area_exited(area):
	if area.is_in_group("carnet"):
		activar_mano_normal()
