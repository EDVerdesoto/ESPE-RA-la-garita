## PostActionCatalog: Catálogo de consecuencias post-entrada
## Solo se activan para NPCs CON incidencia que fueron aprobados (se colaron).
## NPCs sin incidencia que pasan correctamente NO generan post-action.
##   - BUENAS: Algo positivo pasó a pesar de la incidencia → propina/bonus
##   - MALAS: Consecuencia negativa por dejar pasar a alguien con incidencia
##   - GRAVES: Delincuente que se coló → desastre serio (SIEMPRE para atacantes)
##
## Textos impersonales, narrados como eventos con impacto económico directo.
## Cada entrada: { "texto": String, "valor": float }
class_name PostActionCatalog
extends RefCounted

# =====================================================
# POST-ACCIONES BUENAS
# Algo salió bien a pesar de que el NPC tenía incidencia.
# Pequeñas ganancias inesperadas para el guardia.
# =====================================================
const ACCIONES_BUENAS: Array = [
	{"texto": "Alguien dejó $10 de propina en la garita.", "valor": 10.0},
	{"texto": "Un padre de familia dejó $5 por la amabilidad del guardia.", "valor": 5.0},
	{"texto": "Se encontró un billete de $2 en el suelo de la caseta.", "valor": 2.0},
	{"texto": "La administración pagó un bono sorpresa de $8 por turno completo.", "valor": 8.0},
	{"texto": "Un estudiante compró un almuerzo para el guardia de turno.", "valor": 4.0},
	{"texto": "El comedor regaló la comida sobrante del día al personal de seguridad.", "valor": 3.0},
	{"texto": "Seguridad interna entregó un incentivo de $6 por asistencia perfecta.", "valor": 6.0},
	{"texto": "Alguien olvidó una funda con snacks en la ventanilla. Nadie la reclamó.", "valor": 2.0},
	{"texto": "Se autorizó un pago extra de $7 por cubrir turno extendido.", "valor": 7.0},
	{"texto": "Un profesor dejó una propina de $3 por ayudarle a cargar materiales.", "valor": 3.0},
	{"texto": "La cooperativa depositó un dividendo de $5 a la cuenta del guardia.", "valor": 5.0},
	{"texto": "Se aplicó un reajuste salarial retroactivo de $4.", "valor": 4.0},
	{"texto": "El proveedor de la cafetería regaló café gratis al personal de garita.", "valor": 1.0},
	{"texto": "Un grupo de estudiantes hizo una colecta de $6 para el guardia.", "valor": 6.0},
	{"texto": "La persona que entró dejó una donación de $3 para el fondo de seguridad.", "valor": 3.0},
]

# =====================================================
# POST-ACCIONES MALAS
# Consecuencias negativas por dejar pasar a alguien con incidencia.
# Afectan el salario del guardia directa o indirectamente.
# =====================================================
const ACCIONES_MALAS: Array = [
	{"texto": "Una persona tiró un tacho de basura. Descuento de limpieza al guardia.", "valor": -6.0},
	{"texto": "Alguien sin carnet válido sacó copias a nombre de otro. Multa administrativa.", "valor": -5.0},
	{"texto": "Se reportó un desconocido en el aula B3. Descuento por falta de control.", "valor": -4.0},
	{"texto": "Un individuo con documentos irregulares causó una fila en secretaría.", "valor": -3.0},
	{"texto": "Auditoría detectó una entrada con cédula caducada. Sanción al guardia.", "valor": -7.0},
	{"texto": "Un sujeto entró con carnet ajeno y retiró un libro de biblioteca.", "valor": -4.0},
	{"texto": "Se encontró a una persona no autorizada en el laboratorio de cómputo.", "valor": -5.0},
	{"texto": "Alguien con datos incorrectos hizo un reclamo agresivo en ventanilla.", "valor": -3.0},
	{"texto": "Un vendedor ambulante se coló y montó un puesto en el patio. Multa.", "valor": -4.0},
	{"texto": "Coordinación envió un memo formal por dejar pasar documentación irregular.", "valor": -6.0},
	{"texto": "Un ex-alumno expulsado fue visto en campus. Descuento disciplinario.", "valor": -8.0},
	{"texto": "Se anuló un examen porque entró alguien con identidad falsa al aula.", "valor": -7.0},
	{"texto": "El sistema de control registró una anomalía. Descuento por negligencia.", "valor": -5.0},
	{"texto": "Un extraño entró a un laboratorio y derramó reactivos. Costo de limpieza.", "valor": -6.0},
	{"texto": "Se perdió material de escritorio de una oficina. Descuento compartido.", "valor": -3.0},
	{"texto": "Bienestar estudiantil reportó una queja por presencia de personas ajenas.", "valor": -4.0},
	{"texto": "El jefe de seguridad aplicó una amonestación con descuento de $5.", "valor": -5.0},
	{"texto": "Se dañó una cerradura porque alguien forzó una puerta. Costo al guardia.", "valor": -6.0},
	{"texto": "Recursos Humanos abrió un expediente menor. Retención de $4 del sueldo.", "valor": -4.0},
	{"texto": "Un infiltrado causó un corto circuito en el bloque C. Reparación descontada.", "valor": -8.0},
]

# =====================================================
# POST-ACCIONES GRAVES (Solo para NPCDelincuente)
# Consecuencias severas. Impacto económico fuerte y directo.
# =====================================================
const ACCIONES_GRAVES: Array = [
	{"texto": "Un profesor fue asaltado por un intruso en el estacionamiento.", "valor": -200.0},
	{"texto": "Desaparecieron 5 laptops del laboratorio principal. Costo al guardia.", "valor": -180.0},
	{"texto": "Un sujeto robó mochilas de un aula completa. Demanda colectiva.", "valor": -150.0},
	{"texto": "Vaciaron la oficina del decano. Pérdidas superiores a $300.", "valor": -250.0},
	{"texto": "Un intruso agredió a un conserje. Gastos médicos descontados.", "valor": -170.0},
	{"texto": "Se robaron equipos del laboratorio de electrónica por $400.", "valor": -220.0},
	{"texto": "Amenazaron con arma blanca a una docente. Intervino la policía.", "valor": -300.0},
	{"texto": "Un delincuente vendió sustancias prohibidas detrás del coliseo.", "valor": -250.0},
	{"texto": "Rompieron ventanales del edificio central. Reparación millonaria.", "valor": -190.0},
	{"texto": "Robaron la caja fuerte de la cafetería. Pérdida total.", "valor": -160.0},
	{"texto": "Un sujeto clonó tarjetas de estudiantes en la fotocopiadora.", "valor": -200.0},
	{"texto": "Incendiaron un basurero en el bloque de aulas. Bomberos en campus.", "valor": -180.0},
	{"texto": "Un intruso acosó a estudiantes en los pasillos. Escándalo público.", "valor": -210.0},
	{"texto": "Hurtaron el equipo de audio del auditorio. Evento cancelado.", "valor": -170.0},
	{"texto": "Alguien cobró matrículas falsas a padres de familia. Fraude masivo.", "valor": -280.0},
	{"texto": "Robaron cables de cobre del edificio en construcción. Obra paralizada.", "valor": -150.0},
	{"texto": "La policía antinarcóticos realizó un operativo dentro del campus.", "valor": -320.0},
	{"texto": "Destrozaron el jardín botánico de Biotecnología. Daño irreparable.", "valor": -140.0},
	{"texto": "Un sospechoso golpeó a un estudiante y le robó el celular.", "valor": -160.0},
	{"texto": "Se filtró en prensa que un delincuente entró sin control. Desprestigio.", "valor": -230.0},
]

# =====================================================
# FUNCIONES DE SELECCIÓN
# =====================================================

## Probabilidad de que un NPC con incidencia aprobado genere una post-acción.
## No siempre pasa algo: solo el 40% de las veces.
const PROBABILIDAD_POST_ACTION: float = 0.4

## Selecciona una post-acción para NPCs aprobados.
## - NPCs SIN incidencia → {} (no generan post-action, entrada legítima)
## - NPCs CON incidencia → 40% de chance de generar post-action:
##     - Genéricos: BUENA o MALA (50/50)
##     - NPCDelincuente: SIEMPRE GRAVE
static func obtener_post_action(npc: AbstractNPC, fue_aprobado: bool) -> Dictionary:
	if not fue_aprobado:
		return {}
	
	# NPC sin incidencia → sin consecuencias
	if not npc.tiene_incidencia():
		return {}
	
	# Solo el 40% de las veces se genera una post-acción
	if randf() > PROBABILIDAD_POST_ACTION:
		return {}
	
	# ── NPCDelincuente con incidencia → SIEMPRE GRAVE (cuando se activa) ──
	if npc is NPCDelincuente:
		var accion = ACCIONES_GRAVES.pick_random().duplicate()
		accion["categoria"] = "grave"
		accion["npc_nombre"] = npc.nombre + " " + npc.apellido
		return accion
	
	# ── NPC genérico con incidencia → BUENA o MALA (50/50) ──
	if randf() < 0.5:
		var accion = ACCIONES_BUENAS.pick_random().duplicate()
		accion["categoria"] = "buena"
		accion["npc_nombre"] = npc.nombre + " " + npc.apellido
		return accion
	else:
		var accion = ACCIONES_MALAS.pick_random().duplicate()
		accion["categoria"] = "mala"
		accion["npc_nombre"] = npc.nombre + " " + npc.apellido
		return accion

## Para rechazos incorrectos (rechazaste a alguien sin incidencia)
## Penalización por negar el acceso a una persona legítima.
static func obtener_post_action_rechazo_injusto(npc: AbstractNPC) -> Dictionary:
	var acciones_rechazo_injusto = [
		{"texto": "Se presentó una queja formal en Recursos Humanos por acceso denegado sin causa.", "valor": -8.0},
		{"texto": "Bienestar estudiantil reportó una denuncia por rechazo injustificado.", "valor": -6.0},
		{"texto": "Un familiar llamó al rectorado para reclamar por trato indebido en garita.", "valor": -10.0},
		{"texto": "Se publicó un video en redes sociales denunciando abuso de autoridad en la entrada.", "valor": -9.0},
		{"texto": "Un estudiante perdió su examen final por no poder ingresar. Sanción al guardia.", "valor": -12.0},
		{"texto": "El gremio estudiantil envió una carta exigiendo explicaciones por el rechazo.", "valor": -7.0},
		{"texto": "Se recibió una carta notarial por denegación de acceso sin fundamento.", "valor": -10.0},
		{"texto": "La persona rechazada resultó ser familiar de un directivo. Consecuencias graves.", "valor": -15.0},
		{"texto": "El incidente fue grabado y compartido en medios locales. Desprestigio institucional.", "valor": -8.0},
		{"texto": "La asociación de estudiantes solicitó formalmente la remoción del guardia.", "valor": -11.0},
	]
	var accion = acciones_rechazo_injusto.pick_random().duplicate()
	accion["categoria"] = "rechazo_injusto"
	accion["npc_nombre"] = npc.nombre + " " + npc.apellido
	return accion
