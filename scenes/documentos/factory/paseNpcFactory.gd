class_name PasanteNPCFactory
extends IDocumentoNPCFactory

func crear_documento(configuracionNPC : AbstractDocumentoNPCConfig) -> AbstractDocumentoNPC:
	var pase = PaseVisitante.new()
	pase.configuracion = configuracionNPC
	return pase
