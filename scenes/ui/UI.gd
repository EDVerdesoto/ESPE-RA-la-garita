extends CanvasLayer # Cambiado a CanvasLayer para que sea la raíz

signal decision_tomada(decision: int, incidencia_detectada: int)

# --- REFERENCIAS (Asegúrate de que los nombres coincidan en tu escena) ---
@onready var main_layout: Control = $MainLayout
@onready var lbl_dia: Label = $MainLayout/MarginContainer/TopHUD/LblDia
@onready var lbl_dinero: Label = $MainLayout/MarginContainer/TopHUD/LblDinero

# Zona Verde (NPC)
@onready var chat_container: PanelContainer = $MainLayout/MarginContainer/MiddleLayout/ChatContainer
@onready var scroll_chat: ScrollContainer = $MainLayout/MarginContainer/MiddleLayout/Scroll

# Zona Azul (Opciones de respuesta)
@onready var contenedor_opciones: VBoxContainer = $MainLayout/MarginContainer/MiddleLayout/ResponseMenu

# Botones de Acción (Abajo)
@onready var btn_aprobar: TextureButton = $MainLayout/MarginContainer/ActionFooter/BtnAprobar
@onready var btn_rechazar: TextureButton = $MainLayout/MarginContainer/ActionFooter/BtnRechazar

var incidencia_actual_clicada: int = 0

func _ready():
	# Conectar botones principales
	btn_aprobar.pressed.connect(_on_aprobar)
	btn_rechazar.pressed.connect(_on_rechazar)
	# El HUD no debe bloquear clics en los papeles
	main_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE 

# --- SISTEMA DE INCIDENCIAS POR CLIC ---
# Esta función la llamarás desde el script de la Cédula o Carnet
func set_incidencia_detectada(id_incidencia: int):
	incidencia_actual_clicada = id_incidencia
	# Opcional: Feedback visual de que "seleccionaste" un error
	print("Incidencia marcada: ", id_incidencia)

func _on_rechazar() -> void:
	# Ya no abrimos el menú. Usamos la incidencia que el jugador detectó clicando.
	decision_tomada.emit(GlobalEnums.DecisionGuardia.RECHAZADO, incidencia_actual_clicada)
	incidencia_actual_clicada = 0 # Reset para el siguiente NPC

func _on_aprobar() -> void:
	decision_tomada.emit(GlobalEnums.DecisionGuardia.APROBADO, 0)
