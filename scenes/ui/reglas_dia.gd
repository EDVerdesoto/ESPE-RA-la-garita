extends CanvasLayer

@onready var lbl_reglas = $TextureRect/lblReglas

var pool_reglas = [
	"Cédulas caducadas NO pasan.\nSoftware tiene libre hoy.\nProhibido vendedores.",
	"Prohibido entrar con gorra.\nBiotecnología solo con mandil.\nCarnets sin sello no valen.",
	"Solo entran cédulas pares.\nMedicina no tiene clase.\nProhibido comida.",
	"Solo estudiantes con carnet físico.\nSoftware entra directo.\nNo mascotas.",
	"Casa abierta: Revisar alcohol.\nCaducados pagan multa.\nTuristas no entran."
]

func _ready():
	# Usamos el día + slot como semilla para que sea consistente dentro del mismo día
	# pero diferente entre días y entre partidas
	var semilla = GlobalGameManager.dia_actual * 1000 + GlobalGameManager.slot_actual
	var rng = RandomNumberGenerator.new()
	rng.seed = semilla
	
	var indice = rng.randi_range(0, pool_reglas.size() - 1)
	lbl_reglas.text = pool_reglas[indice]

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Clic en cualquier lugar cierra el panel
		queue_free()
