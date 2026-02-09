## PostActionCatalog: Catálogo masivo de consecuencias post-entrada
## Cada NPC que entra (aprobado) genera una postAction según su tipo:
##   - BUENAS: NPC sin incidencia que pasa → cosas positivas para la ESPE
##   - MALAS: NPC con incidencia menor que se coló → líos administrativos
##   - GRAVES: Delincuente que se coló → desastres en el campus
##
## Cada entrada tiene: texto (lo que aparece en el reporte), valor (dinero +/-)
class_name PostActionCatalog
extends RefCounted

# =====================================================
# ESTRUCTURA: { "texto": String, "valor": float }
#   valor positivo = recompensa/propina
#   valor negativo = multa/penalización
# =====================================================

# =====================================================
# POST-ACCIONES BUENAS (NPC legítimo que pasó correctamente)
# Pequeñas recompensas por buen trabajo del guardia
# =====================================================
const ACCIONES_BUENAS: Array = [
	# --- Reconocimientos de la universidad ---
	{"texto": "📋 El decano felicitó tu buen control de acceso hoy.", "valor": 3.0},
	{"texto": "📋 Seguridad interna reportó cero incidentes. Bono de desempeño.", "valor": 4.0},
	{"texto": "📋 El rector pasó por la garita y dijo: 'Buen trabajo, soldado.'", "valor": 2.0},
	{"texto": "📋 Recursos Humanos te nominó al 'Guardia del Mes'.", "valor": 5.0},
	{"texto": "📋 El jefe de seguridad te dio una palmada en la espalda.", "valor": 1.0},
	
	# --- Gratitud de estudiantes ---
	{"texto": "😊 Un estudiante te trajo un cafecito de agradecimiento.", "valor": 1.0},
	{"texto": "😊 Una estudiante dejó una nota: 'Gracias por cuidarnos, don.'", "valor": 1.5},
	{"texto": "😊 El presidente estudiantil te agradeció públicamente en redes.", "valor": 2.0},
	{"texto": "😊 Un grupo de estudiantes te compró un almuerzo.", "valor": 3.0},
	{"texto": "😊 Te dejaron un jugo en la garita con una nota de gracias.", "valor": 1.0},
	{"texto": "😊 Un estudiante te presentó a su mamá: 'Él es el guardia buena gente.'", "valor": 1.5},
	
	# --- Propinas y favores ---
	{"texto": "💰 Un profesor te dio propina por ayudarle con las maletas.", "valor": 2.0},
	{"texto": "💰 Un padre de familia te dejó $1 de propina.", "valor": 1.0},
	{"texto": "💰 Encontraste una moneda de $1 en tu caseta.", "valor": 1.0},
	{"texto": "💰 Te pagaron horas extra por quedarte 10 minutos más.", "valor": 2.5},
	{"texto": "💰 El administrador te dio un vale de almuerzo gratis.", "valor": 2.0},
	
	# --- Día tranquilo ---
	{"texto": "☀️ Día tranquilo. Ningún problema reportado.", "valor": 0.5},
	{"texto": "☀️ Turno sin novedades. Pudiste leer tu libro en paz.", "valor": 0.0},
	{"texto": "☀️ Todo el mundo entró con papeles en orden. Buen día.", "valor": 1.0},
	{"texto": "☀️ Los profes del departamento te saludaron amablemente hoy.", "valor": 0.5},
	{"texto": "☀️ Un perrito callejero se echó junto a tu garita. Compañía gratis.", "valor": 0.0},
	{"texto": "☀️ El clima estuvo perfecto. Ni frío ni calor.", "valor": 0.0},
	{"texto": "☀️ Alguien dejó un paraguas olvidado. Ahora tienes uno de repuesto.", "valor": 0.5},
]

# =====================================================
# POST-ACCIONES MALAS (NPC con incidencia menor que se coló)
# Consecuencias leves/medias: líos administrativos, quejas, etc.
# =====================================================
const ACCIONES_MALAS: Array = [
	# --- Problemas con documentos ---
	{"texto": "⚠️ Auditoría detectó que dejaste pasar a alguien con carnet vencido.", "valor": -5.0},
	{"texto": "⚠️ Un estudiante usó el carnet de su hermano. Le robaron el celular adentro.", "valor": -4.0},
	{"texto": "⚠️ Alguien con nombre incorrecto en el carnet causó confusión en secretaría.", "valor": -3.0},
	{"texto": "⚠️ El sistema registró una entrada con cédula caducada. Te llaman la atención.", "valor": -4.0},
	{"texto": "⚠️ Un infiltrado con carnet ajeno se metió a un examen y lo anulan entero.", "valor": -6.0},
	{"texto": "⚠️ Dejaste pasar a alguien con la foto diferente. Resultó ser un ex-alumno expulsado.", "valor": -5.0},
	
	# --- Quejas de profesores ---
	{"texto": "😤 Un profesor se quejó porque entró un desconocido a su clase.", "valor": -3.0},
	{"texto": "😤 La secretaria dijo que alguien sacó copias con carnet prestado.", "valor": -2.0},
	{"texto": "😤 El laboratorio reportó un 'estudiante fantasma' que no existe en el sistema.", "valor": -4.0},
	{"texto": "😤 Un docente encontró a alguien durmiendo en el aula. No era de la ESPE.", "valor": -3.0},
	{"texto": "😤 Coordinación académica te mandó un memo: 'Revise mejor los documentos.'", "valor": -2.0},
	
	# --- Incidentes menores ---
	{"texto": "🔧 Alguien que entró sin carnet se cayó en las gradas. La ESPE paga médico.", "valor": -5.0},
	{"texto": "🔧 Entró un tipo a vender empanadas sin permiso. Decomisaron todo.", "valor": -2.0},
	{"texto": "🔧 Un estudiante con datos incorrectos retiró un libro a nombre de otro.", "valor": -3.0},
	{"texto": "🔧 Se coló un vendedor de seguros y molestó a medio campus.", "valor": -2.0},
	{"texto": "🔧 Dejaste pasar a alguien de carrera equivocada. Fue a un lab que no le tocaba y dañó un equipo.", "valor": -6.0},
	{"texto": "🔧 El de la foto distinta resultó ser un periodista. Publicó un artículo vergonzoso.", "valor": -4.0},
	{"texto": "🔧 Alguien que pasó con cédula caducada hizo un escándalo en bienestar estudiantil.", "valor": -3.0},
	
	# --- Reprimendas ---
	{"texto": "📝 Te pusieron un llamado de atención por escrito.", "valor": -3.0},
	{"texto": "📝 Tu jefe dice que si sigues así, te cambian al turno de madrugada.", "valor": -2.0},
	{"texto": "📝 Recursos Humanos abrió un expediente menor sobre tu desempeño.", "valor": -4.0},
	{"texto": "📝 El encargado de seguridad te miró feo todo el día.", "valor": -1.0},
	{"texto": "📝 Te quitaron el bono del mes por 'falta de atención'.", "valor": -5.0},
	{"texto": "📝 Tu compañero del turno siguiente se quejó del desorden que dejaste.", "valor": -1.5},
	{"texto": "📝 Recibiste un correo de advertencia del departamento de personal.", "valor": -2.0},
	{"texto": "📝 Te redujeron la hora de almuerzo como 'medida correctiva'.", "valor": -2.5},
]

# =====================================================
# POST-ACCIONES GRAVES (Delincuente que se coló)
# Consecuencias severas: robos, daños, peligro real
# =====================================================
const ACCIONES_GRAVES: Array = [
	# --- Robos ---
	{"texto": "🚨 ¡ROBO! Desaparecieron 3 laptops del laboratorio de software.", "valor": -15.0},
	{"texto": "🚨 ¡ROBO! Robaron proyectores del edificio de Biotecnología.", "valor": -12.0},
	{"texto": "🚨 ¡ROBO! Un delincuente se llevó las mochilas de un aula entera.", "valor": -10.0},
	{"texto": "🚨 ¡ROBO! Vaciaron la oficina del decano de Economía.", "valor": -14.0},
	{"texto": "🚨 ¡ROBO! Se robaron el microscopio nuevo del laboratorio.", "valor": -13.0},
	{"texto": "🚨 ¡ROBO! Desapareció la caja chica de la cafetería.", "valor": -8.0},
	{"texto": "🚨 ¡ROBO! Un sujeto robó celulares en el comedor. 5 víctimas.", "valor": -12.0},
	{"texto": "🚨 ¡ROBO! Se llevaron cables de cobre del edificio en construcción.", "valor": -10.0},
	{"texto": "🚨 ¡ROBO! Hurtaron el equipo de audio del auditorio principal.", "valor": -11.0},
	
	# --- Vandalismo ---
	{"texto": "💥 ¡VANDALISMO! Rayaron la fachada del edificio central con grafiti.", "valor": -8.0},
	{"texto": "💥 ¡VANDALISMO! Rompieron ventanales del bloque de aulas.", "valor": -10.0},
	{"texto": "💥 ¡VANDALISMO! Dañaron los baños del segundo piso. Inundación.", "valor": -9.0},
	{"texto": "💥 ¡VANDALISMO! Destrozaron el jardín botánico que los de Biotec cuidaban.", "valor": -7.0},
	{"texto": "💥 ¡VANDALISMO! Le desinflaron las llantas al carro del vicerrector.", "valor": -6.0},
	{"texto": "💥 ¡VANDALISMO! Dibujaron obscenidades en la pizarra del aula magna.", "valor": -5.0},
	
	# --- Agresiones ---
	{"texto": "🏥 ¡AGRESIÓN! Un sospechoso golpeó a un estudiante en el estacionamiento.", "valor": -15.0},
	{"texto": "🏥 ¡AGRESIÓN! Amenazaron con cuchillo a una profesora de Derecho.", "valor": -18.0},
	{"texto": "🏥 ¡AGRESIÓN! Un tipo agredió al conserje cuando le pidió identificación.", "valor": -12.0},
	{"texto": "🏥 ¡AGRESIÓN! Tuvieron que llamar a la policía por una pelea con arma blanca.", "valor": -20.0},
	{"texto": "🏥 ¡AGRESIÓN! Un intruso acosó a estudiantes en los pasillos.", "valor": -14.0},
	
	# --- Estafas ---
	{"texto": "💸 ¡ESTAFA! Un sujeto vendió carnets falsos a estudiantes nuevos.", "valor": -10.0},
	{"texto": "💸 ¡ESTAFA! Alguien cobró matrículas falsas a padres de familia.", "valor": -15.0},
	{"texto": "💸 ¡ESTAFA! Un tipo se hizo pasar por profesor y dio clases por 3 días.", "valor": -8.0},
	{"texto": "💸 ¡ESTAFA! Vendieron supuestas 'becas' a estudiantes ingenuos.", "valor": -12.0},
	{"texto": "💸 ¡ESTAFA! Alguien clonó tarjetas en la fotocopiadora.", "valor": -10.0},
	
	# --- Sustancias ---
	{"texto": "🚬 ¡DROGAS! Encontraron sustancias ilegales en el baño del tercer piso.", "valor": -12.0},
	{"texto": "🚬 ¡DROGAS! Un delincuente vendió sustancias prohibidas detrás del coliseo.", "valor": -15.0},
	{"texto": "🚬 ¡DROGAS! La policía antinarcóticos llegó al campus. El rector está furioso contigo.", "valor": -20.0},
	
	# --- Consecuencias para ti ---
	{"texto": "📛 El rector dijo que si pasa algo más, te despiden.", "valor": -8.0},
	{"texto": "📛 Tu contrato está en revisión por 'negligencia grave'.", "valor": -10.0},
	{"texto": "📛 Te suspendieron 1 día sin sueldo por el incidente.", "valor": -15.0},
	{"texto": "📛 La policía te interrogó por 2 horas por dejar pasar al sospechoso.", "valor": -5.0},
	{"texto": "📛 Tu foto salió en el periódico local como 'el guardia que dejó entrar al ladrón'.", "valor": -8.0},
	{"texto": "📛 Te cambiaron al turno de medianoche como castigo.", "valor": -6.0},
	{"texto": "📛 El sindicato dice que no te puede defender esta vez.", "valor": -7.0},
]

# =====================================================
# FUNCIONES DE SELECCIÓN
# =====================================================

## Selecciona una post-acción aleatoria según el tipo de NPC y su resultado
## Retorna: { "texto": String, "valor": float, "categoria": String }
static func obtener_post_action(npc: AbstractNPC, fue_aprobado: bool) -> Dictionary:
	if not fue_aprobado:
		# Si fue rechazado, no genera post-action (no entró al campus)
		return {}
	
	# NPC sin incidencia que pasó correctamente → acción buena
	if not npc.tiene_incidencia():
		var accion = ACCIONES_BUENAS.pick_random().duplicate()
		accion["categoria"] = "buena"
		accion["npc_nombre"] = npc.nombre + " " + npc.apellido
		return accion
	
	# NPC con incidencia que se coló (el guardia no la detectó o lo dejó pasar)
	if npc is NPCDelincuente:
		# Delincuente que entró → consecuencia GRAVE
		var accion = ACCIONES_GRAVES.pick_random().duplicate()
		accion["categoria"] = "grave"
		accion["npc_nombre"] = npc.nombre + " " + npc.apellido
		return accion
	else:
		# Ciudadano con incidencia menor → consecuencia MALA
		var accion = ACCIONES_MALAS.pick_random().duplicate()
		accion["categoria"] = "mala"
		accion["npc_nombre"] = npc.nombre + " " + npc.apellido
		return accion

## Para rechazos incorrectos (rechazaste a alguien sin incidencia)
## Retorna una penalización por abuso de autoridad
static func obtener_post_action_rechazo_injusto(npc: AbstractNPC) -> Dictionary:
	var acciones_rechazo_injusto = [
		{"texto": "⚖️ %s puso una queja formal en Recursos Humanos por trato injusto.", "valor": -4.0},
		{"texto": "⚖️ %s fue a llorar a Bienestar Estudiantil. Te mandaron un memo.", "valor": -3.0},
		{"texto": "⚖️ La mamá de %s llamó al rector para quejarse de ti.", "valor": -5.0},
		{"texto": "⚖️ %s publicó en Twitter que le negaste la entrada sin razón. Trending.", "valor": -4.0},
		{"texto": "⚖️ %s perdió su examen final porque no lo dejaste entrar. El decano te busca.", "valor": -6.0},
		{"texto": "⚖️ %s se fue llorando. Sus compañeros te miran feo el resto del día.", "valor": -2.0},
		{"texto": "⚖️ El abogado de %s envió una carta notarial a la universidad.", "valor": -5.0},
		{"texto": "⚖️ %s era hijo del vicerrector. Oops.", "valor": -8.0},
		{"texto": "⚖️ %s grabó todo con el celular. El video tiene 10K vistas.", "valor": -4.0},
		{"texto": "⚖️ La asociación de estudiantes pidió tu destitución por rechazar a %s.", "valor": -5.0},
	]
	var accion = acciones_rechazo_injusto.pick_random().duplicate()
	accion["texto"] = accion["texto"] % npc.nombre
	accion["categoria"] = "rechazo_injusto"
	accion["npc_nombre"] = npc.nombre + " " + npc.apellido
	return accion
