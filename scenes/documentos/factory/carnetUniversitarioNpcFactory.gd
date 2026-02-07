class_name CarnetUniversitarioNPCFactory
extends IDocumentoNPCFactory

func crear_documento(configuracionNPC : AbstractDocumentoNPCConfig) -> AbstractDocumentoNPC:
	var carnet = CarnetUniversitario.new()
	carnet.configuracion = configuracionNPC
	return carnet
