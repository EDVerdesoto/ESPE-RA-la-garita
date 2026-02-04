# DocumentoNPCFactoryProvider.gd
# Autoload
extends Node

var _factories := {}

func _ready():
	_factories["cedula"] = CedulaNPCFactory.new()
	_factories["carnet_universitario"] = CarnetUniversitarioNPCFactory.new()
	_factories["pase_visitante"] = PasanteNPCFactory.new()

func get_factory(tipo : String) -> IDocumentoNPCFactory:
	return _factories[tipo]
