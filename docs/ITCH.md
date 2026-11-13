# Subir el juego a itch.io (versión web)

Zips listos (se generan con los comandos de abajo; `export/` no está en el repo):

| Archivo | Qué es | Tamaño |
| --- | --- | --- |
| `export/web/InflationWhatInflation_web.zip` | Juego completo (jugable en el navegador) | ~9,7 MB |
| `export/web_demo/InflationWhatInflation_web_demo.zip` | Demo: Era 1, Era 2 y la primera reforma | ~9,7 MB |

Cada zip tiene `index.html` en la raíz, que es lo que pide itch.io.

## Pasos

1. Entrá a https://itch.io/game/new (con tu cuenta, desde "Create new project").
2. **Title**: `INFLATION? What Inflation?` (para la demo: `INFLATION? What Inflation? (Demo)`).
   **Project URL**: algo como `inflation-what-inflation` (sin signos de pregunta).
3. **Kind of project**: `HTML`.
4. **Uploads** → `Upload files` → elegí el zip. Marcá **"This file will be played in the browser"**.
5. **Embed options**:
   - Viewport dimensions: `1280` x `720` (el juego escala solo). Activá "Click to launch in fullscreen" y "Fullscreen button".
   - **No** marques "SharedArrayBuffer support": el build es sin threads, no lo necesita.
6. **Visibility & access**: dejalo en `Draft` hasta probarlo; con `Restricted` y una clave compartís el link con probadores.
7. Guardá y abrí la página para probarla. Si algo falla, revisá la consola del navegador (F12).
8. Repetí con el zip de la demo en un proyecto aparte (o como segundo archivo del mismo proyecto).

Con la herramienta `butler` (opcional):

```
butler push export/web/InflationWhatInflation_web.zip TU_USUARIO/inflation-what-inflation:html5
butler push export/web_demo/InflationWhatInflation_web_demo.zip TU_USUARIO/inflation-what-inflation-demo:html5
```

## Cómo se generan los zips

```
godot --headless --import
godot --headless --export-release "Web" export/web/index.html
godot --headless --export-release "Web Demo" export/web_demo/index.html
```

Después se comprimen los archivos de `export/web/` (o `export/web_demo/`, sin los `.import`) dejando `index.html` en la raíz del zip. Hacen falta las export templates 4.4.1 con `web_nothreads_release.zip` (`tools/export_all.sh --install-templates` las baja).

## Notas técnicas verificadas

- Renderer: GL Compatibility (WebGL 2). Los shaders del pizarrón y del efecto tiza compilan y se ven bien en WebGL 2 (probado con Chrome headless por software; ver `tools/web_probe.ps1`). No hizo falta un shader de respaldo.
- Guardado: el navegador usa IndexedDB (`/userfs`); se verificó que `save.json` se escribe tras el autosave de 30 s. Cada navegador y dominio tiene su propia partida; borrar los datos del sitio borra la partida.
- El navegador no deja arrancar el audio sin un gesto del usuario: la música empieza tras el primer clic.
- La demo web guarda en otro archivo (`save_demo.json`), así que no pisa la partida del juego completo si ambos viven en el mismo dominio.
- Probar localmente: `powershell -File tools/serve_web.ps1 -Dir export/web -Port 8060` y abrir http://localhost:8060/. Para una captura automática y los mensajes de la consola: `powershell -File tools/web_probe.ps1 -Url http://localhost:8060/ -Out captura.png`.
