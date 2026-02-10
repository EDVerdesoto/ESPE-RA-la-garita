# ESPE-RA: La Garita

> Videojuego 2D de verificación de documentos inspirado en *Papers, Please*, ambientado en la garita de seguridad de la **Universidad de las Fuerzas Armadas ESPE** (Ecuador).

**Motor:** Godot 4.6 (GL Compatibility)  
**Resolución:** 1920×1080 | Pantalla completa | Stretch: `canvas_items` / `expand`  
**Lenguaje:** GDScript  
**Plataforma:** PC (Windows / Linux)

---

## Tabla de Contenidos

1. [Descripción del Juego](#1-descripción-del-juego)
2. [Arquitectura Técnica](#2-arquitectura-técnica)
3. [Patrones de Diseño](#3-patrones-de-diseño)
4. [Sistemas del Juego](#4-sistemas-del-juego)
5. [Sistema de UI](#5-sistema-de-ui)
6. [Sistema de Audio](#6-sistema-de-audio)
7. [Jerarquía de Clases](#7-jerarquía-de-clases)
8. [Flujo de Datos Completo](#8-flujo-de-datos-completo-ciclo-de-vida-del-npc)
9. [Sistema de Cámara](#9-sistema-de-cámara)
10. [Objetos del Escritorio](#10-objetos-del-escritorio)
11. [Controles](#11-controles)
12. [Decisiones Técnicas Notables](#12-decisiones-técnicas-notables)
13. [Estructura del Proyecto](#13-estructura-del-proyecto)

---

## 1. Descripción del Juego

El jugador asume el rol de un **guardia de seguridad** en la garita de la ESPE. Cada día, una cola de NPCs — estudiantes, profesores y ocasionalmente atacantes — se acercan a la ventanilla presentando sus documentos de identidad (carnet universitario, cédula, pase de visitante).

### Mecánica Principal

1. **Inspeccionar documentos:** El jugador examina el carnet físico del NPC.
2. **Escanear en el sistema:** Clic derecho sobre el carnet para enviar datos al monitor del PC.
3. **Comparar campos:** Clic en un campo del carnet + clic en el mismo campo del monitor para verificar coincidencias.
4. **Detectar discrepancias:** Nombres diferentes, fotos distintas, fechas caducadas, carreras incorrectas.
5. **Tomar decisión:** Aprobar (✓) o rechazar (✗) a cada persona.

### Consecuencias

- Las decisiones incorrectas generan **errores** — acumular **3 errores en un día** provoca **Game Over**.
- Las decisiones correctas/incorrectas tienen **consecuencias económicas** (multas, propinas, amonestaciones).
- El jugador debe balancear su **economía diaria**: sueldo base ($20) - gastos fijos ($15) ± post-acciones.

### Contexto Cultural

El juego está ambientado en un contexto **ecuatoriano**, con jerga local en los diálogos (generados por IA), música de pasillos en la radio, y narrativas culturalmente específicas.

---

## 2. Arquitectura Técnica

### 2.1 Autoloads (Singletons)

El juego utiliza 7 autoloads globales que persisten entre escenas:

| Autoload | Archivo | Propósito |
|---|---|---|
| `GlobalGameManager` | `globals/GlobalGameManager.gd` | Estado central: día, economía, puntaje, reglas, sesión |
| `SaveManager` | `globals/SaveManager.gd` | Sistema de guardado basado en 3 slots |
| `ProgresoGlobal` | `scenes/gameplay/providers/progresoGlobal.gd` | Calendario interno, aritmética de fechas para expiración de cédulas |
| `NpcFactoryProvider` | `scenes/gameplay/providers/npcFactoryProvider.gd` | Service Locator para fábricas de NPCs |
| `DocumentoNpcFactoryProvider` | `scenes/gameplay/providers/documentoNpcFactoryProvider.gd` | Service Locator para fábricas de documentos |
| `GeminiManager` | `scenes/gameplay/geminiManager.gd` | Integración con Google Gemini 2.5 Flash para diálogos procedurales |
| `MusicManager` | `globals/MusicManager.gd` | Reproductor de música persistente entre escenas |

### 2.2 Árbol de Escenas del Nivel Principal

```
nivelGarita.tscn (raíz)
├── GameplayController (gameplayController.gd)
├── Npc (npc.tscn / npc.gd — Area2D)
│   ├── SpriteCuerpo (Sprite2D)
│   │   └── SpriteCara (Sprite2D — se muestra al hacer clic)
│   ├── ClickCara (Area2D + CollisionShape2D)
│   └── CarnetVisual (carnetVisual.tscn)
│       ├── SpriteFondo, FotoSprite, Labels
│       └── Áreas clickeables: Nombre, Apellido, Carrera, Código, Foto
├── Pc (PC.tscn / PC.gd — Area2D)
│   └── PantallaMonitor (Control)
│       ├── Labels (Nombre, Apellido, Cédula, FechaExp, Carrera, Código)
│       ├── FotoSistema (Sprite2D)
│       └── Áreas clickeables por cada campo
├── UI (UI.tscn / UI.gd — CanvasLayer)
│   ├── TopBar (HUD: Día, Dinero, Aciertos, Errores)
│   ├── ChatPanel (izquierda — burbujas NPC/Guardia)
│   ├── OptionsPanel (derecha — opciones de respuesta)
│   └── BtnAprobar, BtnRechazar (TextureButtons)
├── CarpetaDocumentos (abre reglas del día)
├── Radio (reproductor de música interactivo)
├── Reporte (objeto del escritorio)
├── Camera2D (camera2d.gd)
├── EnvironmentGarita (fondo visual)
│   └── WeatherController (sistema climático dinámico)
└── ManosJugador (cursor personalizado)
```

**Total: 27 archivos `.tscn`** incluyendo menús, pantalla de carga, HUD overlays y objetos del escritorio.

---

## 3. Patrones de Diseño

### 3.1 Abstract Factory Pattern (Fábricas de NPCs y Documentos)

Dos jerarquías paralelas de fábricas:

**Fábricas de NPCs:**
```
INPCFactory (clase abstracta — Node)
├── NPCGenericoFactory   → crea NPCGenerico (estudiantes/profesores)
└── DelincuenteNPCFactory → crea NPCDelincuente (atacantes con tipo_amenaza)
```

**Fábricas de Documentos:**
```
IDocumentoNPCFactory (clase abstracta — Node)
├── CedulaNPCFactory               → crea objetos Cedula
├── CarnetUniversitarioNPCFactory  → crea objetos CarnetUniversitario
└── PasanteNPCFactory              → crea objetos PaseVisitante
```

### 3.2 Service Locator / Provider Pattern

`NpcFactoryProvider` y `DocumentoNpcFactoryProvider` registran fábricas en `_ready()` y las exponen a través de `get_factory(tipo: String)`. Esto desacopla la creación de NPCs del código que los consume.

### 3.3 Abstract Base Classes (Template Method)

- `AbstractNPC` (RefCounted) → `NPCGenerico`, `NPCDelincuente`
- `AbstractDocumentoNPC` (RefCounted) → `Cedula`, `CarnetUniversitario`, `PaseVisitante`
- `AbstractDocumentoNPCConfig` (RefCounted) → `CedulaNPCConfig`, `CarnetUniversitarioNPCConfig`, `PaseVisitanteNPCConfig`

### 3.4 Arquitectura Basada en Señales (Observer Pattern)

Toda la comunicación entre sistemas utiliza señales de Godot:
- Llegada del NPC → `npc_llego_a_ventanilla`
- Escaneo de carnet → `carnet_escaneado`
- Clic en campos → `campo_clickeado`, `campo_monitor_clickeado`
- Decisiones → `decision_tomada`
- Fin del día → `dia_finalizado`
- Diálogos de Gemini → `dialogos_completados`

### 3.5 Decomposición Manager/Controller

| Componente | Responsabilidad |
|---|---|
| `GameplayController` | Orquestador principal del flujo de juego |
| `ComparacionManager` | Máquina de estados para comparación de campos |
| `DailyManager` | Generación del roster diario de NPCs |
| `GeneradorIncidencias` | Inyección de discrepancias (métodos estáticos) |
| `PostActionCatalog` | Catálogo de consecuencias económicas (métodos estáticos) |

---

## 4. Sistemas del Juego

### 4.1 Pipeline de Generación de NPCs

1. **LoadingScreen** invoca `DailyManager.generar_npcs_para_hoy(10)`.
2. **DailyManager** carga `data/npc_catalog.json` (22 entradas: 14 estudiantes, 6 profesores, 3 atacantes).
3. Determina composición: ~25% profesores, 1 atacante si `randf() < 0.1 + día*0.05` (máximo 40%).
4. Para cada NPC: crea configs → `NpcFactoryProvider.get_factory("generico").crear_npc(...)`.
5. **NPCGenericoFactory** instancia `NPCGenerico` y llama `GeneradorIncidencias.generar_incidencias(...)`.
6. **GeneradorIncidencias** (65% prob. de incidencia) inyecta discrepancias en los documentos.
7. Paralelamente, `GeminiManager.solicitar_dialogos_batch(...)` genera diálogos con IA.

### 4.2 Catálogo de NPCs (`data/npc_catalog.json`)

- **14 Estudiantes:** Camila, Carlos, Daniela, David, Fernando, Joan, Juan, María, Nahomi, Oswaldo, Paola, Pedro, Pepe, Sara
- **6 Profesores:** Camilo, Fabián, Marco, Mauricio, Rubén, Sang
- **3 Atacantes:** Desconocido (atk_01, atk_02, atk_03)
- **Carreras:** Software, Biotecnología, Economía, Fisioterapia, Derecho
- **Personalidades:** Amigable, Tranquilo, Nerviosa, Relajado, Formal, Chistoso, Agresivo, Tímida, Impaciente, Sospechoso
- Cada entrada tiene `sprite_path` (cuerpo completo) y `cara_path` (primer plano facial).

### 4.3 Sistema de Verificación y Comparación de Documentos

**ComparacionManager** implementa una mecánica de selección dual:

1. El jugador hace clic en un **campo del carnet** (nombre, apellido, carrera, código, foto) → almacenado como `seleccion_carnet`.
2. El jugador hace clic en el **mismo tipo de campo en el monitor del PC** → almacenado como `seleccion_monitor`.
3. Si ambos campos son del mismo tipo, se comparan (case-insensitive).
4. **Resultado:** `COINCIDE` → resaltado verde. `NO_COINCIDE` → resaltado rojo + alerta de discrepancia.
5. **Comparación de fotos:** Clic en la cara del NPC → toggle de visibilidad + comparar con foto del carnet.

**Mapeo Campo → Incidencia:**

| Campo | Incidencia |
|---|---|
| NOMBRE / APELLIDO | `NOMBRE_CEDULA_DIFERENTE`, `NOMBRE_CARNET_DIFERENTE` |
| FOTO | `FOTO_CARNET_DIFERENTE` |
| CARRERA | `CARRERA_DIFERENTE` |
| FECHA_EXPIRACION | `FECHA_CEDULA_CADUCADA` |

### 4.4 Sistema de Reglas Diarias

Generadas determinísticamente por día+slot en LoadingScreen:

| Tipo de Regla | Ejemplo | Efecto |
|---|---|---|
| `solo_rol` | "Hoy solo pasan PROFESORES" | Los estudiantes deben ser rechazados |
| `carrera_libre` | "Software tiene acceso libre" | Estudiantes de Software están exentos de revisión |
| `primeros_sin_revision` | "Los primeros 2 pasan libre" | Los primeros N NPCs son auto-aprobados |

Las reglas escalan con los días: `max_reglas = clamp(1 + día/3, 1, 3)`. Sin tipos duplicados. Visibles en el juego a través de la **CarpetaDocumentos** en el escritorio.

### 4.5 Sistema Económico

Calculado en `GlobalGameManager.calcular_fin_de_dia()`:

| Concepto | Valor |
|---|---|
| Sueldo base | +$20.00/día |
| Gastos fijos (arriendo) | -$15.00/día |
| Post-acciones buenas (propinas, bonos) | +$1 a +$10 |
| Post-acciones malas (multas, memorandos) | -$3 a -$8 |
| Post-acciones graves (consecuencias criminales) | -$140 a -$320 |
| Rechazo injusto | -$6 a -$15 |

**Probabilidad de activación:** Solo el 40% de los NPCs aprobados con incidencias generan una post-acción.  
**Fórmula diaria:** `sueldo_base + total_post_acciones - arriendo_diario`

### 4.6 Puntaje y Game Over

- Se rastrean `aciertos_hoy` y `errores_hoy` por día (también totales acumulados).
- **Game Over** se activa con **3 errores en un solo día** (`MAX_ERRORES_DIARIOS = 3`).
- Al activarse, se cambia a `gameOver.tscn` con botón de retorno al menú.

### 4.7 Integración con IA (Google Gemini)

**GeminiManager** utiliza la API de **Gemini 2.5 Flash**:

- Lee `GEMINI_API_KEY` desde archivo `.env` en la raíz del proyecto.
- Envía un prompt batch para los 10 NPCs simultáneamente con:
  - Personalidad del NPC, rol, verdad secreta (criminal, error honesto o papeles limpios)
  - Condición climática actual
  - Instrucciones para **jerga ecuatoriana**
- **Formato de respuesta:** Array JSON con estructura de diálogo por NPC:
  - `respuesta_incidencia_correcta` (3 opciones de respuesta del guardia con reacciones del NPC)
  - `respuestas_incidencia_incorrecta` (4 cadenas de excusa)
  - `respuesta_aprobado` / `respuesta_rechazado`
- Temperatura: 1.0, máximo tokens: 8192, MIME: `application/json`
- **Degradación elegante:** Si la API falla o no hay clave, el juego continúa con diálogos por defecto.

### 4.8 Sistema de Guardado

**SaveManager** gestiona 3 slots:

- Archivos: `user://slot_1.save`, `slot_2.save`, `slot_3.save`
- Serialización binaria via `FileAccess.store_var()` / `get_var()`
- **Datos guardados:** fecha, progreso (día, dinero), estadísticas (aciertos/errores totales), sesión (índice NPC, array de NPCs, diálogos Gemini cacheados)
- Pantalla de selección de slots: muestra resumen "DÍA X | $Y" o "VACÍO"

### 4.9 Sistema Climático

**WeatherController** maneja 4 estados:

```
SOLEADO → NUBLADO → LLUVIOSO → MOJADO → SOLEADO (cíclico)
```

- Estado inicial aleatorio. Cambio potencial cada 120 segundos.
- Transiciones suaves de 3 segundos (alpha de sprites de fondo izquierdo/derecho).
- `CPUParticles2D` para efecto de lluvia en estado LLUVIOSO.
- El clima afecta el contexto de los diálogos de Gemini (los NPCs mencionan lluvia, frío, etc.).

---

## 5. Sistema de UI

### 5.1 Panel UI Principal (`UI.gd` — CanvasLayer)

| Componente | Ubicación | Función |
|---|---|---|
| **TopBar/HUD** | Superior | Día, dinero, aciertos (✓), errores (✗) — actualizado cada frame |
| **ChatPanel** | Izquierda | Burbujas de chat estilizadas (NPC=azul oscuro, Guardia=verde oscuro), auto-scroll |
| **OptionsPanel** | Derecha | 3 botones de respuesta al encontrar discrepancia (agresivo, amable, técnico) |
| **BtnAprobar** | Esquina inferior izquierda | TextureButton con texturas normal/hover/pressed |
| **BtnRechazar** | Esquina inferior derecha | TextureButton con texturas normal/hover/pressed |

### 5.2 Sistema de Menús

| Menú | Características |
|---|---|
| **Menú Principal** | Continuar, Nuevo Turno, Puntuación, Opciones, Créditos, Salir. Reproduce `track4.mp3`. |
| **Selector de Partida** | 3 slots con info guardada. Nueva partida o cargar. → LoadingScreen |
| **Pausa** | Continuar, Opciones (sub-ventana), Salir (confirmación). `get_tree().paused = true`. CanvasLayer 110. |
| **Opciones** | Slider de volumen (linear→dB), toggle pantalla completa. Context-aware. |
| **Confirmación** | Sí/No para salir al menú. Despausa antes de salir. |
| **Game Over** | Se muestra tras 3 errores diarios. Retorno al menú. |
| **Créditos** | Pantalla simple con botón de regreso. |
| **Puntuación/Reporte** | Modo dual: reporte de fin de día (post-acciones, balance) o stats históricas desde menú. Balance con código de colores (verde/rojo). |

### 5.3 Pantalla de Carga (`loadingScreen.gd`)

- Carga threaded de `nivelGarita.tscn` via `ResourceLoader.load_threaded_request()`.
- Genera NPCs, reglas diarias y solicita diálogos Gemini simultáneamente.
- Ícono de carga rotativo con frases humorísticas ecuatorianas del guardia (15 mensajes rotativos).
- Transición fade-to-black cuando la escena y Gemini están listos.

### 5.4 Manos del Jugador / Cursor Personalizado (`manos_guardia_der.gd`)

- Reemplaza el cursor del ratón con un sprite de mano que sigue `get_global_mouse_position()`.
- **Sensible al contexto:** Mano normal por defecto, cambia a textura de escáner al pasar sobre el carnet (detectado via `Area2D Detector` entrando en grupo `"carnet"`).

### 5.5 Overlay de Reglas Diarias (`reglas_dia.gd`)

- CanvasLayer popup activado al hacer clic en CarpetaDocumentos.
- Muestra `GlobalGameManager.reglas_texto_dia` formateado.
- Se cierra al hacer clic en cualquier parte.

---

## 6. Sistema de Audio

### 6.1 MusicManager (`globals/MusicManager.gd`)

- Autoload global con `AudioStreamPlayer` creado por código.
- Evita reiniciar la misma canción si ya está reproduciéndose.
- Usado por el menú principal (`track4.mp3`) — se detiene al entrar a `nivelGarita`.

### 6.2 Radio del Juego (`radio.gd`)

- Objeto interactivo del escritorio (Area2D).
- Auto-descubre todos los archivos `.mp3`/`.ogg` en `res://music/`.
- **Clic izquierdo:** Siguiente canción. **Clic derecho:** Play/Pausa.
- Auto-avanza al terminar una canción. Empieza en track aleatorio.
- **Biblioteca de tracks** (12+ canciones): Pasillos ecuatorianos, música latina clásica, tracks originales.

### 6.3 Control de Volumen

- `GlobalGameManager._ready()` establece el bus Master al 70% linear (≈-3.1 dB), reduciendo el volumen general un 30%.
- El menú de opciones ofrece un slider que controla el volumen del bus Master.
- **Easter egg:** Gato clickeable en el nivel que reproduce `miau_hombre.mp3` con variación de pitch aleatoria (0.95-1.05).

---

## 7. Jerarquía de Clases

### 7.1 Modelo de NPCs

```
RefCounted
└── AbstractNPC
    │   Propiedades: nombre, apellido, tipo_npc, rol, incidencia,
    │                documentos[], datos_sistema{}, dialogos_ia{},
    │                ruta_sprite_npc, cara_path, estado
    │
    ├── NPCGenerico          ← Estudiante o profesor normal
    └── NPCDelincuente       ← Criminal (tiene tipo_amenaza)
```

### 7.2 Modelo de Documentos

```
RefCounted
├── AbstractDocumentoNPCConfig      ← Config base: nombre, apellido, ruta_sprite
│   ├── CedulaNPCConfig             ← + numero_cedula, fecha_emision, fecha_expiracion
│   ├── CarnetUniversitarioNPCConfig ← + carrera, rol, codigo_carnet, foto_path
│   └── PaseVisitanteNPCConfig      ← + razon
│
└── AbstractDocumentoNPC            ← Wrapper que contiene una referencia a config
    ├── Cedula
    ├── CarnetUniversitario
    └── PaseVisitante
```

### 7.3 Fábricas

```
Node
├── INPCFactory                     ← crear_npc() → AbstractNPC
│   ├── NPCGenericoFactory          ← + GeneradorIncidencias
│   └── DelincuenteNPCFactory       ← + GeneradorIncidencias
│
└── IDocumentoNPCFactory            ← crear_documento() → AbstractDocumentoNPC
    ├── CedulaNPCFactory
    ├── CarnetUniversitarioNPCFactory
    └── PasanteNPCFactory
```

### 7.4 Enumeraciones (`globalEnums.gd`)

| Enum | Valores |
|---|---|
| `NPCState` | NUEVO, APROBADO, EN_VALIDACION, DESAPROBADO |
| `Incidencia` | NINGUNA, NOMBRE_CEDULA_DIFERENTE, NOMBRE_CARNET_DIFERENTE, FECHA_CEDULA_CADUCADA, FOTO_CARNET_DIFERENTE, CARRERA_DIFERENTE, CARNET_OLVIDADO, ATAQUE (11 tipos) |
| `CampoComparacion` | NINGUNO, NOMBRE, APELLIDO, FOTO, CODIGO_CARNET, CARRERA, NUMERO_CEDULA, FECHA_EXPIRACION, CARA_NPC |
| `ResultadoComparacion` | COINCIDE, NO_COINCIDE, DATO_FALTANTE |
| `DecisionGuardia` | PENDIENTE, APROBADO, RECHAZADO |

---

## 8. Flujo de Datos Completo: Ciclo de Vida del NPC

```
LoadingScreen
  │
  ├─ DailyManager.generar_npcs_para_hoy(10)
  │    ├─ Cargar npc_catalog.json
  │    ├─ Mezclar y componer roster (estudiantes/profesores/atacantes)
  │    ├─ Para cada NPC:
  │    │    ├─ Crear objetos Config (Cedula, Carnet, Pase)
  │    │    ├─ NpcFactoryProvider.get_factory("generico").crear_npc(...)
  │    │    │    ├─ GeneradorIncidencias.generar_incidencias(npc, configs)
  │    │    │    │    ├─ Tirar probabilidad de incidencia (65%)
  │    │    │    │    ├─ Asignar tipo de incidencia aleatorio
  │    │    │    │    ├─ Inyectar discrepancias en configs
  │    │    │    │    ├─ Construir npc.datos_sistema{} (para el monitor)
  │    │    │    │    └─ Crear objetos documento via DocumentoNpcFactoryProvider
  │    │    │    └─ Retornar NPCGenerico con documentos e incidencia
  │    │    └─ Almacenar en GlobalGameManager.npcs_del_dia[]
  │    └─ Almacenar en GlobalGameManager
  │
  ├─ _generar_reglas_del_dia() → GlobalGameManager.reglas_del_dia[]
  ├─ GeminiManager.solicitar_dialogos_batch(npcs, clima)
  │    └─ async → asigna dialogos_ia a cada NPC
  │
  └─ Transición → nivelGarita.tscn
       │
       └─ GameplayController.iniciar_dia()
            │
            └─ cargar_npc_siguiente() [BUCLE para cada NPC]
                 │
                 ├─ SI ATACANTE:
                 │    ├─ npc_visual.cargar_npc() → corre de largo
                 │    ├─ señal atacante_paso → PostAction registrada
                 │    └─ npc_salio → siguiente NPC
                 │
                 ├─ SINO (NPC normal):
                 │    ├─ ComparacionManager.iniciar_comparacion(npc)
                 │    ├─ npc_visual.cargar_npc(npc)
                 │    │    ├─ Cargar sprite de cuerpo → escala estandarizada
                 │    │    ├─ Cargar sprite de cara (oculto inicialmente)
                 │    │    ├─ Configurar CarnetVisual desde documentos
                 │    │    └─ Animación de caminar → State.ENTRANDO
                 │    │
                 │    ├─ señal npc_llego_a_ventanilla
                 │    │    ├─ Iniciar temporizador NPC (60s)
                 │    │    ├─ UI.configurar_npc() → mostrar saludo
                 │    │    └─ Mostrar botones aprobar/rechazar
                 │    │
                 │    ├─ INTERACCIONES DEL JUGADOR:
                 │    │    ├─ Clic campo carnet → señal campo_clickeado
                 │    │    ├─ Clic campo monitor → señal campo_monitor_clickeado
                 │    │    ├─ ComparacionManager compara → COINCIDE/NO_COINCIDE
                 │    │    │    ├─ Resaltado verde/rojo en carnet y monitor
                 │    │    │    └─ UI muestra feedback en chat + opciones de respuesta
                 │    │    ├─ Clic cara NPC → toggle visibilidad + comparar foto
                 │    │    └─ Clic derecho carnet → ESCANEAR → monitor muestra datos_sistema
                 │    │
                 │    └─ DECISIÓN:
                 │         ├─ Verificar reglas diarias (¿exento? ¿prohibido?)
                 │         ├─ ComparacionManager.evaluar_decision()
                 │         ├─ Actualizar aciertos/errores
                 │         ├─ PostActionCatalog.obtener_post_action() si aplica
                 │         ├─ Reproducir diálogo de aprobación/rechazo
                 │         ├─ NPC camina fuera (izquierda=aprobado, derecha=rechazado)
                 │         └─ Verificar game over (3 errores) → siguiente NPC
                 │
                 └─ TODOS LOS NPCs PROCESADOS → finalizar_dia()
                      ├─ GlobalGameManager.calcular_fin_de_dia()
                      │    ├─ Calcular: sueldo + post_acciones - gastos
                      │    ├─ Actualizar dinero, avanzar día, guardar
                      │    └─ Retornar diccionario resumen
                      ├─ UI.mostrar_reporte_fin_de_dia()
                      └─ Al cerrar reporte → resetear_sesion → siguiente día
```

---

## 9. Sistema de Cámara

**`camera2d.gd`** implementa un sistema de cámara con dos vistas:

| Vista | Posición X | Zoom | Hotkey |
|---|---|---|---|
| **Exterior** (ventanilla NPCs) | 2885 | 1.1 | E |
| **Interior** (escritorio/monitor) | 1325 | 0.85 | Q |

- **Paneo WASD** a 700 px/s, limitado a los bordes del sprite de fondo.
- Transiciones suaves con Tween (0.9s, Sine ease).
- Sistema de clamp consciente del zoom futuro para evitar saltos visuales.

---

## 10. Objetos del Escritorio

| Objeto | Script | Interacción |
|---|---|---|
| **PC Monitor** | `PC.gd` | Muestra datos del sistema al escanear carnet. Campos clickeables para comparación. Estética de terminal verde. |
| **Radio** | `radio.gd` | Jukebox con tracks auto-descubiertos. Clic izq: siguiente. Clic der: play/pausa. |
| **CarpetaDocumentos** | `carpetaDocumentos.gd` | Abre overlay de reglas diarias al hacer clic. |
| **Reporte** | `reporte.gd` | Emite señal `reporte_solicitado` al hacer clic. |
| **Gato (Easter Egg)** | `gato_area.gd` | Gato clickeable que reproduce "miau" con pitch aleatorio (0.95-1.05). |

---

## 11. Controles

| Acción | Tecla | Propósito |
|---|---|---|
| Mover cámara | W/A/S/D | Paneo del viewport |
| Mirar adentro | Q | Zoom al escritorio |
| Mirar afuera | E | Zoom a la ventanilla |
| Pausa | Escape | Abrir menú de pausa |
| Interactuar | Clic izquierdo | Seleccionar campos, aprobar/rechazar, interactuar con objetos |
| Escanear carnet | Clic derecho | Enviar datos del carnet al monitor del PC |

---

## 12. Decisiones Técnicas Notables

1. **Todos los datos de NPC son `RefCounted`** (no `Node`), permitiendo generación ligera de 10+ NPCs por día sin overhead de escenas.

2. **Separación Config/Modelo en documentos** — Los configs contienen datos crudos para construcción; los modelos los envuelven para la lógica del juego.

3. **Integración con Gemini es completamente opcional** — El juego degrada elegantemente a diálogos por defecto si la clave API está ausente o la petición falla.

4. **Reglas diarias determinísticas** via RNG con semilla (`día * 1000 + slot`) aseguran las mismas reglas al recargar.

5. **Escalado estandarizado de sprites de NPC** — Todos los NPCs se escalan a un cuerpo fijo de 220×614px y cara de 109×109px independientemente del tamaño de la textura fuente, con compensación de escala del padre para sprites hijos.

6. **Carga threaded de escenas** via `ResourceLoader.load_threaded_request()` en la pantalla de carga para evitar congelamientos de UI.

7. **Sprites persistentes de atacantes** — Cuando un atacante pasa corriendo, se crea un clon `Sprite2D` en la raíz de la escena para que permanezca visible tras resetear el nodo NPC.

8. **Volumen reducido 30% globalmente** al inicio via `linear_to_db(0.7)` en el bus Master.

9. **Cursor personalizado context-aware** — Cambia entre mano normal y escáner al pasar sobre el carnet, usando detección por grupos de Godot.

10. **Sistema climático dinámico** con 4 estados cíclicos que afectan los sprites de fondo y los diálogos generados por IA.

---

## 13. Estructura del Proyecto

```
espe-ra-la-garita/
├── project.godot              # Configuración del motor
├── data/
│   └── npc_catalog.json       # Catálogo de 22 NPCs (estudiantes, profesores, atacantes)
├── globals/
│   ├── GlobalGameManager.gd   # Estado central del juego
│   ├── SaveManager.gd         # Sistema de guardado (3 slots)
│   ├── MusicManager.gd        # Música persistente entre escenas
│   ├── globalEnums.gd         # Enumeraciones globales
│   └── camera2d.gd            # Sistema de cámara con dos vistas
├── scenes/
│   ├── characters/
│   │   ├── npc.gd / npc.tscn           # NPC visual con movimiento y estados
│   │   ├── carnetVisual.gd / .tscn      # Representación visual del carnet
│   │   ├── factory/                      # Fábricas de NPCs (Abstract Factory)
│   │   └── modelo/                       # Clases abstractas y concretas de NPCs
│   ├── documentos/
│   │   ├── config/                       # Configs de documentos
│   │   ├── factory/                      # Fábricas de documentos
│   │   └── modelo/                       # Clases de documentos
│   ├── gameplay/
│   │   ├── gameplayController.gd         # Orquestador principal
│   │   ├── comparacionManager.gd         # Máquina de comparación
│   │   ├── dailyManager.gd              # Generador de roster diario
│   │   ├── generadorIncidencias.gd       # Inyector de discrepancias
│   │   ├── postActionCatalog.gd          # Catálogo de consecuencias
│   │   ├── geminiManager.gd             # Integración IA
│   │   └── providers/                    # Service Locators
│   ├── levels/
│   │   └── nivelGarita.gd / .tscn       # Nivel principal del juego
│   ├── ui/
│   │   ├── UI.gd / UI.tscn              # HUD + Chat + Decisiones
│   │   ├── menus/                        # Todos los menús del juego
│   │   └── loading/                      # Pantalla de carga
│   └── world/
│       ├── deskObjects/                  # PC, Radio, Carpeta, Reporte
│       └── weather/                      # Sistema climático
├── assets/
│   ├── HUD/                              # Texturas de botones Aprobar/Rechazar
│   ├── objetos/                          # Sprites de objetos del escritorio
│   ├── personajes/                       # Sprites de NPCs y caras
│   ├── fondo/                            # Fondos (normal, izquierda, gatito)
│   └── sounds/                           # Efectos de sonido
├── music/                                # 12+ tracks (pasillos, latina, original)
├── fonts/                                # Fuente personalizada
└── fotos/                                # Assets adicionales (sello ESPE)
```

---

*Proyecto desarrollado como parte de la materia de Videojuegos — Séptimo Semestre, Universidad de las Fuerzas Armadas ESPE.*
