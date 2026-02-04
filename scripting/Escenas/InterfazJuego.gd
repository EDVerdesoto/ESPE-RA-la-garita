# InterfazJuego.gd - Interfaz visual integrada con el sistema de gestión de NPCs
extends CanvasLayer

# Señales para comunicarse con MesaPrincipal
signal decision_tomada(decision: GlobalEnums.NPCState)
signal siguiente_npc_solicitado()

# Referencias a nodos de la escena
@onready var etiqueta_nombre = $Mesa/CedulaFondo/LblNombre
@onready var etiqueta_carrera = $Mesa/CedulaFondo/LblCarrera
@onready var etiqueta_reloj = $LblReloj
@onready var mesa = $Mesa
@onready var etiqueta_dinero = $LblDinero
@onready var btn_aprobar = $Mesa/BtnAprobar
@onready var btn_denegar = $Mesa/BtnDenegar

# Estado actual
var npc_actual: AbstractNPC = null
var en_proceso_decision: bool = false

func _ready():
	btn_aprobar.pressed.connect(_on_btn_aprobar_pressed)
	btn_denegar.pressed.connect(_on_btn_denegar_pressed)
	
	# Inicialmente oculta hasta que llegue un NPC
	mesa.visible = false
	
	# Inicializar valores
	actualizar_reloj(480) # 8 horas = 480 minutos
	actualizar_dinero(0)

# Mostrar datos del NPC en la interfaz visual
func mostrar_npc(npc: AbstractNPC):
	npc_actual = npc
	mesa.visible = true
	en_proceso_decision = false
	
	# Actualizar información en la cédula
	etiqueta_nombre.text = "%s %s" % [npc.nombre, npc.apellido]
	etiqueta_carrera.text = "%s - %s" % [npc.rol, npc.carrera]
	
	# Habilitar botones
	btn_aprobar.disabled = false
	btn_denegar.disabled = false
	
	print("InterfazJuego: Mostrando NPC - %s %s" % [npc.nombre, npc.apellido])

# Ocultar la interfaz cuando no hay NPCs
func ocultar_mesa():
	mesa.visible = false
	npc_actual = null

# Actualizar el reloj del juego
func actualizar_reloj(minutos: int):
	var horas = int(minutos / 60)
	var mins = minutos % 60
	etiqueta_reloj.text = "Tiempo: %02d:%02d" % [horas, mins]

# Actualizar dinero ganado
func actualizar_dinero(cantidad: float):
	etiqueta_dinero.text = "$ %.2f" % cantidad

# Mostrar mensaje de fin del día
func mostrar_fin_dia(mensaje: String = "¡FIN DEL DÍA!"):
	mesa.visible = false
	# Aquí se podría agregar un panel especial para fin del día

# Deshabilitar botones después de tomar decisión
func deshabilitar_botones():
	btn_aprobar.disabled = true
	btn_denegar.disabled = true
	en_proceso_decision = true

# Evento: Aprobar entrada
func _on_btn_aprobar_pressed():
	if en_proceso_decision or npc_actual == null:
		return
	
	print("InterfazJuego: Jugador APROBÓ ingreso")
	deshabilitar_botones()
	
	# Emitir señal con la decisión
	decision_tomada.emit(GlobalEnums.NPCState.APROBADO)
	
	# Esperar un momento antes de pasar al siguiente
	await get_tree().create_timer(1.5).timeout
	siguiente_npc_solicitado.emit()

# Evento: Denegar entrada
func _on_btn_denegar_pressed():
	if en_proceso_decision or npc_actual == null:
		return
	
	print("InterfazJuego: Jugador DENEGÓ ingreso")
	deshabilitar_botones()
	
	# Emitir señal con la decisión
	decision_tomada.emit(GlobalEnums.NPCState.DESAPROBADO)
	
	# Esperar un momento antes de pasar al siguiente
	await get_tree().create_timer(1.5).timeout
	siguiente_npc_solicitado.emit()

# Mostrar feedback visual de decisión correcta/incorrecta
func mostrar_feedback(correcto: bool):
	var mensaje = "✓ CORRECTO" if correcto else "✗ INCORRECTO"
	var color = Color.GREEN if correcto else Color.RED
	
	# Aquí se podría añadir un efecto visual temporal
	print("InterfazJuego: Decisión fue %s" % mensaje)
