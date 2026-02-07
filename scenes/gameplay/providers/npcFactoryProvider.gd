extends Node

var _factories := {}

func _ready():
	_factories["generico"] = NPCGenericoFactory.new()
	_factories["delincuente"] = DelincuenteNPCFactory.new()

func get_factory(tipo : String) -> INPCFactory:
	return _factories[tipo]
