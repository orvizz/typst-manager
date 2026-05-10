# Future Work — typst-manager

Documento vivo de ideas, mejoras y funcionalidades nice-to-have que podrían
incorporarse al proyecto. No es un compromiso de implementación: es un
catálogo de oportunidades a discutir, priorizar y descartar a medida que el
proyecto evoluciona.

El estado actual de la herramienta (v0.2.0) cubre lo esencial: gestión local
de plantillas (`create`, `edit`, `rename`, `delete`, `list`), creación de
documentos a partir de una plantilla (`new`), configuración (`config`) y
manual (`man`). Todo funciona sobre carpetas planas en el directorio de
datos del usuario.

A partir de ahí, el siguiente plan de trabajo se organiza en tres ejes.

---

## 1. Mejoras y nuevas funcionalidades de la CLI

### 1.1. Compilación integrada

Hoy `typst-manager` se queda en la generación de la carpeta del documento;
el usuario tiene que invocar `typst` por su cuenta. Sería natural envolver
esa parte:

- `typst-manager build <doc-dir>` — ejecuta `typst compile main.typ` en la
  carpeta del documento (o en la carpeta actual si se omite).
- `typst-manager watch <doc-dir>` — equivalente a `typst watch main.typ`.
- `typst-manager new ... --open` — al terminar de crear el documento, lo
  abre en el editor configurado.
- `typst-manager new ... --compile` — compila inmediatamente tras la
  creación, útil para validar que la plantilla está sana.

Consideraciones: detectar si `typst` está en el PATH y dar un mensaje claro
si no lo está; permitir pasar flags pass-through a `typst` (`-- --root ...`).

### 1.2. Variables y placeholders en plantillas

El modelo "copy as-is" es simple y predecible, pero hay un caso muy común
que se resolvería con sustitución mínima: rellenar `metadata.typ` con el
título, autor y fecha al crear el documento.

Propuesta:

- Soportar placeholders tipo `{{ title }}`, `{{ author }}`, `{{ date }}` en
  cualquier archivo `.typ` o `.toml` de la plantilla.
- `typst-manager new <doc> -t <tpl> --title "..." --author "..."` los
  rellena en el momento de la copia.
- Si faltan valores, leer interactivamente (prompt) o caer en los
  definidos en `config.toml` (`[user] author = "..."`).
- Definición de placeholders adicionales por plantilla en `meta.toml`:

  ```toml
  [variables]
  title       = { prompt = "Document title", required = true }
  course      = { prompt = "Course code",   default  = "" }
  ```

Esto mantiene la promesa de "no lock-in": si el usuario no usa variables,
las plantillas siguen siendo carpetas planas.

### 1.3. Información y previsualización

- `typst-manager template show <name>` — muestra `meta.toml`, lista de
  archivos, tamaño, fecha de última modificación.
- `typst-manager template preview <name>` — compila la plantilla a PDF y
  abre el archivo resultante (gran ayuda para recordar qué hace cada
  plantilla cuando hay muchas).
- Generación opcional de un `thumbnail.png` (primera página renderizada)
  asociado a la plantilla, mostrado por la web y por `template list` con
  `--rich`.

### 1.4. Búsqueda, etiquetas y agrupaciones

- Campos `tags` y `category` en `meta.toml`.
- `typst-manager template list --tag academic`,
  `--category report`, `--search "two-column"`.
- Salida `--json` para integración con otros scripts y para la posible
  página web.

### 1.5. Importar / exportar plantillas

- `typst-manager template export <name> --out file.zip` — empaqueta la
  carpeta de la plantilla.
- `typst-manager template import file.zip` — la instala localmente.
- Útil para enviar plantillas por correo, adjuntar a documentación de
  cursos o universidades, o sincronizar entre máquinas sin depender del
  registro central.

### 1.6. Backup, sincronización y versionado

- `typst-manager backup --out file.tar.gz` — comprime todo el directorio
  de datos.
- `typst-manager restore file.tar.gz`.
- Modo opcional "git-tracked": al inicializar, convertir
  `<data-dir>/templates/` en un repo git para tener historial automático
  (pensado para usuarios avanzados; opt-in vía `config set track-git true`).

### 1.7. Mejoras de usabilidad

- Autocompletado para Bash, Zsh, Fish y PowerShell
  (`typst-manager completions <shell>`).
- Aliases más cortos: `tm` como entry point alternativo declarado en
  `pyproject.toml` (para quien quiera teclear menos).
- Mensajes con color e iconos consistentes (ya hay un `✓` por ahí —
  conviene homogeneizar y añadir `⚠`, `✗`).
- Soporte para `--quiet` y `--verbose` global.
- Más editores reconocidos: `helix`, `subl`, `emacs`, `zed`,
  además del `system` y `vim`/`nvim`/`code` actuales.
- `typst-manager doctor` — diagnostica: ¿está `typst` en el PATH?, ¿el
  editor configurado es ejecutable?, ¿el directorio de datos es
  escribible?, ¿hay plantillas inválidas (sin `main.typ`)?
- Hook post-creación opcional: `meta.toml` puede declarar un comando a
  ejecutar tras `new` (por ejemplo `git init`, `bun install` para una
  plantilla con assets web, etc.). Sólo si el usuario lo activa
  explícitamente — consideraciones de seguridad obvias.

### 1.8. Alcance del proyecto al completo

- Reconocer que un documento existente sigue siendo "gestionable" después
  de creado: comandos como `typst-manager open <doc-dir>` o un registro
  ligero de documentos creados (con su plantilla de origen y fecha) podría
  habilitar funciones futuras como "actualizar este documento si la
  plantilla cambia". Es un paso grande y rompe la promesa de "copia y
  olvida", así que debería ser opt-in.

---

## 2. Página web del proyecto

Una landing + documentación dedicada complementa al README y al `man`, y
sobre todo es el lugar natural para alojar los ejemplos visuales de las
plantillas (algo que el terminal no puede hacer bien).

### 2.1. Stack sugerido

- Generador estático: **Astro**, **MkDocs Material** o
  **Docusaurus** — los tres se despliegan bien en GitHub Pages.
- Hosting: GitHub Pages bajo `orvizz.github.io/typst-manager` o un dominio
  propio (`typst-manager.dev`, por ejemplo).
- CI: workflow de GitHub Actions que rebuild + redeploy en cada push a
  `main`.

### 2.2. Estructura propuesta

- **Home** — pitch breve, animación de un terminal mostrando
  `template create` → `new` → PDF compilado.
- **Install** — copia/expande la sección del README, con tabs por SO.
- **Docs** — referencia completa de comandos, una página por subcomando
  (genera contenido a partir del propio `--help` de la CLI vía un script
  para mantenerlos sincronizados).
- **Cookbook / Examples** — recetas concretas: "carta formal", "informe
  con portada", "paper a dos columnas", "tesis con bibliografía"…
  Cada receta enlaza a la plantilla correspondiente del registro
  comunitario (ver §3).
- **Gallery** — grid visual de plantillas oficiales y destacadas con
  thumbnail, descripción y comando para instalarla
  (`typst-manager pull <name>`).
- **Changelog** — generado a partir de las releases de GitHub.
- **Contribute** — cómo proponer nuevas plantillas al registro, cómo
  abrir issues, convenciones de naming.

### 2.3. Funcionalidades opcionales

- **Playground en el navegador**: usar `typst.ts` (la build WASM de Typst)
  para que el usuario pueda previsualizar una plantilla sin instalarla.
- **Buscador full-text** sobre la documentación y la galería.
- **Modo oscuro/claro** (Typst tiene una estética limpia que casa bien
  con un look minimal).

### 2.4. Mantenimiento

- Versionar la documentación por release (drop-down de versiones) para
  que los usuarios en una versión vieja puedan consultar lo suyo.
- Generar la página de "comandos" desde el código: parsear el resultado
  de `typst-manager <cmd> --help` o exportar un JSON desde `argparse`.
  Así no hay drift entre código y docs.

---

## 3. Registro / repositorio de plantillas comunitarias

Quizá la idea con más impacto: que cualquier usuario pueda hacer
`typst-manager pull <nombre>` y obtener una plantilla bien hecha sin
construirla desde cero.

### 3.1. Modelo del registro

Dos opciones razonables:

**A. Repositorio Git monolítico** (más simple, sigue el estilo de
[awesome-typst]). Estructura:

```
typst-templates-registry/
├── registry.json           ← índice de plantillas
└── templates/
    ├── academic-paper/
    │   ├── meta.toml       ← name, description, author, license, tags
    │   ├── main.typ
    │   ├── template.typ
    │   └── ...
    ├── modern-cv/
    └── ...
```

`registry.json` mantiene metadatos derivados (versión, hash, tamaño,
thumbnail URL) generados por CI cuando se merge una PR.

**B. Plantillas como repositorios separados**, con un repo "índice"
liviano que sólo contiene `registry.json` apuntando a cada repo
(`https://github.com/<owner>/<repo>` + ref/tag).

La opción A es más fácil de bootstrapear; la B escala mejor cuando hay
muchos contribuidores y permite versionado independiente por plantilla.
Empezaría por A y migraría a B si se justifica.

### 3.2. Comandos CLI nuevos

- `typst-manager registry list [--tag ...] [--search ...]` — lista lo
  publicado.
- `typst-manager registry info <name>` — descripción extendida, autor,
  licencia, README de la plantilla.
- `typst-manager pull <name> [--as <local-name>]` — descarga la plantilla
  y la instala en el store local. Equivalente a clonar/copiar a
  `<data-dir>/templates/<name>/`.
- `typst-manager registry update` — refresca la copia local del índice
  (`registry.json` cacheado en `<data-dir>/cache/`).
- `typst-manager pull <name> --upgrade` — actualiza una plantilla ya
  instalada si hay nueva versión, preservando un backup.
- `typst-manager publish <local-name>` (largo plazo) — abre una PR contra
  el repo del registro con la plantilla del usuario.

### 3.3. Calidad y curaduría

- Cada plantilla en el registro debe tener:
  - `meta.toml` con `name`, `description`, `author`, `license`, `version`,
    `tags`, `typst-version-min`.
  - `README.md` con captura de pantalla (o `thumbnail.png`).
  - Compilar correctamente en CI (job `typst compile main.typ`).
- Plantilla de PR estricta: campos obligatorios, validación automática
  (lint del `meta.toml`, test de compilación).
- Categorías iniciales propuestas: *academic*, *report*, *letter*, *cv*,
  *invoice*, *slides*, *book*, *thesis*, *poster*, *misc*.

### 3.4. Seguridad y confianza

- Los archivos descargados son código Typst (no se ejecuta como tal,
  pero puede `#import` paquetes y leer assets locales). Aun así, conviene:
  - Mostrar al usuario el origen exacto (URL, commit hash) antes de
    instalar.
  - Verificar checksum (sha256) declarado en `registry.json`.
  - No ejecutar hooks post-install descargados del registro
    (regla estricta: el registro distribuye archivos, no comandos).
- Distinguir visualmente entre **plantillas oficiales** (mantenidas por
  el equipo) y **plantillas comunitarias**.

### 3.5. Relación con `typst.app/universe`

Typst ya tiene su propio sistema de paquetes/templates oficiales en
[Typst Universe](https://typst.app/universe). Cabe estudiar:

- Si conviene **interoperar** (que `typst-manager pull typst-universe:<id>`
  baje un template de allí) en vez de duplicar esfuerzo.
- O si el registro propio se centra en plantillas que no encajan en
  Universe (privadas de un grupo, plantillas educativas locales,
  plantillas con assets pesados, plantillas en otros idiomas, etc.).

Personalmente: empezar con un registro propio pequeño y, en una segunda
fase, añadir un adaptador que entienda Typst Universe — lo mejor de los
dos mundos.

---

## 4. Backlog corto y priorización sugerida

Si tuviera que elegir las primeras tres "siguientes cosas" en orden:

1. **Variables/placeholders básicos** (`title`, `author`, `date`) — máximo
   impacto por línea de código, resuelve un dolor real.
2. **`pull` + registro mínimo** en la opción A (un repo, un
   `registry.json` curado a mano al principio) — desbloquea la red de
   distribución.
3. **Web del proyecto** con galería que consume el mismo `registry.json`
   — multiplica la visibilidad de cada plantilla añadida en el paso 2.

Todo lo demás (compilación integrada, exportación, `doctor`, búsqueda
avanzada, etc.) son refinamientos que valdría la pena retomar después de
ver cómo responde la base de usuarios a esos tres pasos.

---

## 5. Riesgos y cosas a evitar

- **Scope creep**: la herramienta es valiosa porque es simple. Cada
  feature nueva debe respetar la promesa "carpetas planas, sin lock-in".
- **Acoplarse a un editor o flujo concreto**: mantener neutralidad
  (system / vim / nvim / code / helix / etc.) y no asumir ninguno por
  defecto al implementar `--open`.
- **Hooks ejecutables**: cualquier mecanismo que ejecute código declarado
  en una plantilla descargada del registro abre una superficie de ataque.
  Mantenerlo opt-in y desactivado para plantillas remotas.
- **Promesas de compatibilidad**: una vez publicado el registro y la API
  de variables, romper su formato es caro. Versionar `meta.toml` desde
  el primer commit (`schema = 1`).

---

*Última actualización: mayo 2026.*
