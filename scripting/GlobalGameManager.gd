# GlobalGameManager.gd
extends Node

# --- ESTADO DEL MUNDO ---
var clima_actual: String = "Soleado" # Para que el Prompt lo lea
var dia_actual: int = 1

# --- DATOS DE LA SESIÓN ---
# Aquí guardaremos los objetos NPC ya procesados con IA y todo
var npcs_del_dia: Array = [] 
var npc_actual_index: int = 0

# Función para limpiar datos al iniciar un nuevo día
func iniciar_nuevo_dia():
	dia_actual += 1
	npcs_del_dia.clear()
	npc_actual_index = 0
