# INTEGRACIÓN DE INTERFAZ VISUAL - ESPE-RA-LA-GARITA

## Resumen de Cambios

Se ha integrado exitosamente el componente de interfaz visual (new-game-project) con el sistema principal del juego.

## Archivos Movidos y Creados

### Assets Movidos:
- `Mesa.jpeg` → `assets/objetos/Mesa.jpeg`
- `cedula.jpeg` → `assets/objetos/cedula.jpeg`

### Scripts Integrados:
- `interfaz_juego.gd` → `scripting/Escenas/InterfazJuego.gd` (actualizado con nueva lógica)
- `InterfazJuego.tscn` → `escenas/InterfazJuego.tscn` (actualizado con rutas correctas)

### Scripts Actualizados:
- `scripting/Escenas/MesaPrincipal.gd` → Completamente reescrito para usar la interfaz visual
  - Backup creado: `MesaPrincipal_Original_Backup.gd`

## Arquitectura de la Integración

### Sistema de Señales
La integración utiliza un patrón de señales para comunicación entre componentes:

```
InterfazJuego.gd (CanvasLayer - Visual)
    ↓ (señales)
    ├── decision_tomada(decision: GlobalEnums.NPCState)
    └── siguiente_npc_solicitado()
        ↓
MesaPrincipal.gd (Node2D - Lógica)
    ├── Gestiona NPCs
    ├── Evalúa decisiones
    ├── Actualiza puntajes
    └── Controla flujo del juego
```

### Flujo de Datos

1. **MesaPrincipal.gd** carga `InterfazJuego.tscn`
2. **InterfazJuego.gd** muestra los datos visuales del NPC
3. El jugador hace clic en APROBAR o DENEGAR
4. **InterfazJuego.gd** emite señal `decision_tomada`
5. **MesaPrincipal.gd** evalúa la decisión y actualiza el estado
6. **InterfazJuego.gd** emite señal `siguiente_npc_solicitado`
7. **MesaPrincipal.gd** carga el siguiente NPC

## Características Implementadas

### InterfazJuego.gd
- ✅ Muestra nombre y carrera del NPC en la cédula visual
- ✅ Botones de APROBAR/DENEGAR funcionales
- ✅ Reloj de tiempo actualizable
- ✅ Contador de dinero
- ✅ Sistema de señales para decisiones
- ✅ Auto-avance al siguiente NPC con delay

### MesaPrincipal.gd
- ✅ Carga dinámica de InterfazJuego.tscn
- ✅ Gestión de lista de NPCs desde GlobalGameManager
- ✅ Sistema de evaluación de decisiones
- ✅ Sistema de puntaje y dinero
- ✅ Panel adicional de diálogos
- ✅ Panel adicional de documentos
- ✅ Fin de día con estadísticas

## Funciones Principales

### InterfazJuego.gd
```gdscript
mostrar_npc(npc: AbstractNPC)          # Muestra datos del NPC en pantalla
ocultar_mesa()                          # Oculta la interfaz
actualizar_reloj(minutos: int)         # Actualiza el reloj
actualizar_dinero(cantidad: float)     # Actualiza el contador de dinero
mostrar_feedback(correcto: bool)       # Muestra feedback visual
```

### MesaPrincipal.gd
```gdscript
_mostrar_npc_actual()                  # Carga y muestra el NPC actual
_on_decision_tomada(decision)          # Procesa la decisión del jugador
_evaluar_decision(decision)            # Evalúa si la decisión fue correcta
_on_siguiente_npc()                    # Avanza al siguiente NPC
_mostrar_fin_del_dia()                 # Muestra estadísticas finales
```

## Sistema de Evaluación

La decisión se evalúa de la siguiente manera:
- Si el NPC tiene `incidencia != NINGUNA` → debe ser **DENEGADO**
- Si el NPC tiene `incidencia == NINGUNA` → debe ser **APROBADO**

### Sistema de Recompensas:
- ✅ Decisión correcta: **+$5.00**
- ❌ Decisión incorrecta: **-$2.00**
- ⏱️ Cada decisión consume **5 minutos**

## Paneles de Información

### Panel Visual (InterfazJuego)
- Imagen de mesa
- Cédula con nombre y carrera
- Botones de decisión
- Reloj
- Dinero

### Panel Adicional (UI_Adicional)
- Diálogos del NPC (generados por IA)
- Lista de documentos detallada
- Información de incidencias (modo debug)

## Próximos Pasos Sugeridos

### Para mejorar la integración:

1. **Visualización de Documentos**
   - Agregar imágenes de carnet universitario
   - Mostrar pase de visitante visualmente
   - Animaciones al revisar documentos

2. **Efectos Visuales**
   - Animación de entrada/salida del NPC
   - Efecto visual para decisión correcta/incorrecta
   - Transiciones suaves entre NPCs

3. **Audio**
   - Sonidos de botones
   - Música de fondo
   - Efectos de éxito/error

4. **UI Mejorada**
   - Panel de estadísticas en tiempo real
   - Tutorial inicial
   - Pantalla de game over

## Pruebas

Para probar la integración:

1. Ejecuta el juego desde `PantallaCarga.tscn`
2. Espera a que se generen los NPCs
3. Verifica que se cargue la interfaz visual de la mesa
4. Toma decisiones con los botones APROBAR/DENEGAR
5. Observa el auto-avance al siguiente NPC

## Solución de Problemas

### La interfaz no se muestra:
- Verifica que `InterfazJuego.tscn` esté en `res://escenas/`
- Verifica las rutas de las imágenes en el archivo .tscn

### Las señales no funcionan:
- Revisa las conexiones en `_cargar_interfaz_visual()`
- Asegúrate de que los nombres de las señales coincidan

### Los NPCs no cargan:
- Verifica que `GlobalGameManager.npcs_del_dia` tenga datos
- Revisa que la `PantallaCarga` esté generando NPCs correctamente

## Archivos de Respaldo

Por seguridad, se crearon los siguientes respaldos:
- `MesaPrincipal_Original_Backup.gd` - Versión anterior de MesaPrincipal

La carpeta `new-game-project` puede ser eliminada o conservada como referencia.

---
**Fecha de Integración:** 2026-02-03
**Versión:** 1.0
