class_name CedulaNPCFactory
extends IDocumentoNPCFactory

func crear_documento(configuracionNPC : AbstractDocumentoNPCConfig) -> AbstractDocumentoNPC:
	
	var cedulaNPC = Cedula.new()
	cedulaNPC.configuracion = configuracionNPC
	
	return cedulaNPC
