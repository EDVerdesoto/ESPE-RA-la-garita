extends CanvasLayer
# Rutas según tu foto image_f96180.png
@onready var lbl_cargando = $ColorRect/lbl_cargando
@onready var anim_player = $AnimationPlayer
@onready var icono_carga = $ColorRect/iconoCarga # Referencia al icono

# --- SISTEMA DE CARGA ASÍNCRONA ---
const ESCENA_DESTINO = "res://scenes/levels/nivelGarita.tscn"
const NPCS_POR_DIA = 10
var progreso: Array = []  # ResourceLoader devuelve el progreso aquí

# --- ESTADO DE CARGA ---
var escena_cargada: PackedScene = null
var escena_lista: bool = false
var gemini_listo: bool = false
var transicionando: bool = false

# --- MANAGERS ---
var daily_manager: DailyManager = DailyManager.new()

# Las frases del guardia
var frases = [
	"Buscando las llaves del portón principal...",
	"Preparando el café para aguantar el frío...",
	"Revisando la bitácora de novedades...",
	"Lustrando las botas para la inspección...",
	"Verificando que llevaste el almuerzo...",
	"Analizando la foto del gato...",
	"Viendo las baterias de la radio...",
	"Rezando para que no lleguen los de PAFDE...",
	"Conectando al Wi-Fi de la U...",
	"Conversando con la seño de los sánduches...",
	"¿Si leyeron todo?",
	"Repasando los 10 mandamientos del guardia de garita...",
	"Practicando mi cara de 'Tenga la bondad joven'...",
	"Agarrando la plata que es para el papel...",
	"¿Neblina? No, es el alma de los que perdieron el semestre flotando por el campus"
]

var frases_disponibles: Array = []

func _ready():
	# 1. Animamos el ícono de carga para que gire siempre
	var tween = create_tween().set_loops()
	tween.tween_property(icono_carga, "rotation_degrees", 360, 1.2).from(0.0)
	frases_disponibles = frases.duplicate()
	
	# 2. Iniciamos el sistema de frases
	cambiar_frase()
	anim_player.play("cambio_frase")
	
	# Conectamos la señal para saber cuando termina la animación
	anim_player.animation_finished.connect(_on_animation_finished)
	
	# 3. Iniciamos la carga asíncrona de la escena de juego
	ResourceLoader.load_threaded_request(ESCENA_DESTINO)
	
	# 4. Generamos los NPCs del día y los guardamos en GlobalGameManager
	print("[LOADING] Generando NPCs para el día ", GlobalGameManager.dia_actual, "...")
	GlobalGameManager.aciertos_hoy = 0
	GlobalGameManager.errores_hoy = 0
	var lista_npcs = daily_manager.generar_npcs_para_hoy(NPCS_POR_DIA)
	GlobalGameManager.npcs_del_dia = lista_npcs
	GlobalGameManager.npc_actual_index = 0
	
	# 4.5  Generar las reglas del día (seed determinista por día + slot)
	_generar_reglas_del_dia()
	
	# 5. Solicitamos diálogos a Gemini (si está disponible)
	if GeminiManager and GeminiManager.API_KEY and not GeminiManager.API_KEY.is_empty():
		print("[LOADING] Solicitando diálogos a Gemini...")
		if not GeminiManager.batch_completed.is_connected(_on_gemini_completed):
			GeminiManager.batch_completed.connect(_on_gemini_completed)
		if not GeminiManager.error_ocurred.is_connected(_on_gemini_error):
			GeminiManager.error_ocurred.connect(_on_gemini_error)
		GeminiManager.solicitar_dialogos_batch(lista_npcs, "soleado")
	else:
		print("[LOADING] Sin API de Gemini, continuando sin diálogos IA")
		gemini_listo = true

func _process(_delta):
	if transicionando:
		return
	
	# Revisar el estado de la carga de la escena
	if not escena_lista:
		var status = ResourceLoader.load_threaded_get_status(ESCENA_DESTINO, progreso)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass
			ResourceLoader.THREAD_LOAD_LOADED:
				escena_cargada = ResourceLoader.load_threaded_get(ESCENA_DESTINO)
				escena_lista = true
				print("[LOADING] Escena cargada, esperando Gemini...")
			ResourceLoader.THREAD_LOAD_FAILED:
				printerr("[LOADING] Error al cargar: ", ESCENA_DESTINO)
				lbl_cargando.text = "Error al cargar el nivel..."
				set_process(false)
				return
	
	# Cuando AMBOS están listos → transición con fade
	if escena_lista and gemini_listo:
		transicionando = true
		_iniciar_transicion()

# --- CALLBACKS DE GEMINI ---

func _on_gemini_completed(dialogos_array: Array):
	# Asignar los diálogos a cada NPC
	var lista_npcs = GlobalGameManager.npcs_del_dia
	for i in range(min(lista_npcs.size(), dialogos_array.size())):
		if dialogos_array[i] is Dictionary:
			lista_npcs[i].dialogos_ia = dialogos_array[i]
	print("[LOADING] Diálogos de Gemini listos ✓")
	_desconectar_gemini()
	gemini_listo = true

func _on_gemini_error(mensaje: String):
	print("[LOADING] Error de Gemini: ", mensaje, " - continuando sin IA")
	_desconectar_gemini()
	gemini_listo = true

func _desconectar_gemini():
	if GeminiManager.batch_completed.is_connected(_on_gemini_completed):
		GeminiManager.batch_completed.disconnect(_on_gemini_completed)
	if GeminiManager.error_ocurred.is_connected(_on_gemini_error):
		GeminiManager.error_ocurred.disconnect(_on_gemini_error)

# --- TRANSICIÓN CON FADE ---

func _iniciar_transicion():
	print("[LOADING] ¡Todo listo! Iniciando fade...")
	
	# Creamos un rectángulo negro encima de todo para el fade
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)  # Empieza transparente
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ColorRect.add_child(fade_rect)
	# Aseguramos que quede encima de todo
	fade_rect.move_to_front()
	
	# Fade a negro en 0.8 segundos
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.8)
	tween.tween_callback(_cambiar_a_nivel)

func _cambiar_a_nivel():
	print("[LOADING] Cambiando al nivel...")
	get_tree().change_scene_to_packed(escena_cargada)

func cambiar_frase():
	if frases_disponibles.is_empty():
		frases_disponibles = frases.duplicate()
	
	var frase_elegida = frases_disponibles.pick_random()
	
	frases_disponibles.erase(frase_elegida)
	
	lbl_cargando.text = frase_elegida

func _on_animation_finished(anim_name):
	# Si terminó la animación (el texto ya se hizo invisible)...
	if anim_name == "cambio_frase":
		cambiar_frase()      # Cambiamos el texto
		anim_player.play("cambio_frase") # Reproducimos de nuevo

# =====================================================
# GENERACIÓN DE REGLAS DEL DÍA
# =====================================================

## Pool de reglas posibles.  Cada una tiene: id, texto (lo que ve el jugador),
## tipo (clave lógica), y valor (dato asociado al tipo).
const POOL_REGLAS: Array = [
	{
		"id": "solo_profesores",
		"texto": "Hoy solo pueden ingresar PROFESORES. Estudiantes deben ser rechazados.",
		"tipo": "solo_rol",
		"valor": "profesor"
	},
	{
		"id": "solo_estudiantes",
		"texto": "Hoy solo pueden ingresar ESTUDIANTES. Profesores deben ser rechazados.",
		"tipo": "solo_rol",
		"valor": "estudiante"
	},
	{
		"id": "carrera_libre_software",
		"texto": "Software tiene libre acceso hoy, no requieren revisión.",
		"tipo": "carrera_libre",
		"valor": "Software"
	},
	{
		"id": "carrera_libre_biotech",
		"texto": "Biotecnología tiene libre acceso hoy, no requieren revisión.",
		"tipo": "carrera_libre",
		"valor": "Biotecnología"
	},
	{
		"id": "carrera_libre_economia",
		"texto": "Economía tiene libre acceso hoy, no requieren revisión.",
		"tipo": "carrera_libre",
		"valor": "Economía"
	},
	{
		"id": "carrera_libre_fisio",
		"texto": "Fisioterapia tiene libre acceso hoy, no requieren revisión.",
		"tipo": "carrera_libre",
		"valor": "Fisioterapia"
	},
	{
		"id": "carrera_libre_derecho",
		"texto": "Derecho tiene libre acceso hoy, no requieren revisión.",
		"tipo": "carrera_libre",
		"valor": "Derecho"
	},
	{
		"id": "primeros_2_libres",
		"texto": "Las primeras 2 personas pasan sin revisión.",
		"tipo": "primeros_sin_revision",
		"valor": 2
	},
	{
		"id": "primeros_3_libres",
		"texto": "Las primeras 3 personas pasan sin revisión.",
		"tipo": "primeros_sin_revision",
		"valor": 3
	}
]

func _generar_reglas_del_dia() -> void:
	var dia = GlobalGameManager.dia_actual
	var slot = GlobalGameManager.slot_actual
	
	# Seed determinista: mismo día + slot = mismas reglas
	var rng = RandomNumberGenerator.new()
	rng.seed = dia * 1000 + slot
	
	# Desde el día 1 se aplican reglas reales
	var pool_copia = POOL_REGLAS.duplicate()
	pool_copia.shuffle()
	# Reordenar con el rng determinista
	for i in range(pool_copia.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = pool_copia[i]
		pool_copia[i] = pool_copia[j]
		pool_copia[j] = tmp
	
	var reglas_elegidas: Array = []
	var tipos_usados: Array = []
	var max_reglas = clampi(1 + (dia / 3), 1, 3)  # sube con los días
	
	for regla in pool_copia:
		if reglas_elegidas.size() >= max_reglas:
			break
		var tipo = regla.get("tipo", "")
		# No repetir el mismo tipo de regla
		if tipo in tipos_usados:
			continue
		# Evitar conflictos: no poner "solo_profesores" y "solo_estudiantes" juntas
		if tipo == "solo_rol" and "solo_rol" in tipos_usados:
			continue
		reglas_elegidas.append(regla)
		tipos_usados.append(tipo)
	
	GlobalGameManager.reglas_del_dia = reglas_elegidas
	_construir_texto_reglas()
	print("[LOADING] Reglas del día: ", reglas_elegidas.map(func(r): return r.get("id", "")))

func _construir_texto_reglas() -> void:
	var lineas: Array = []
	lineas.append("=== DISPOSICIONES DEL DÍA %d ===" % GlobalGameManager.dia_actual)
	lineas.append("")
	for i in range(GlobalGameManager.reglas_del_dia.size()):
		var regla = GlobalGameManager.reglas_del_dia[i]
		lineas.append("%d. %s" % [i + 1, regla.get("texto", "")])
	lineas.append("")
	lineas.append("Cumpla estas disposiciones al pie de la letra.")
	GlobalGameManager.reglas_texto_dia = "\n".join(lineas)
