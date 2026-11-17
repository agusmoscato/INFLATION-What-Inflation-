# INFLATION? What Inflation?

Este juego es parte del estudio moscode.games: para todo lo visual y los clips, seguir ../_estudio/brand/MARCA.md.

Todo lo técnico (cómo correrlo, tests, simulador, QA, exportar, decisiones) está en `README.md`, `docs/DISENO_V2.md`
y `docs/DECISIONES.md`. Leelos antes de cambiar el juego.

- Godot 4.4.1 (GDScript). Las herramientas se instalan con `powershell -File tools/setup.ps1`.
- Clips de marketing: `tools/clips/grabar.ps1` graba los crudos; la edición la hace el estudio (`/clips inflation`).
  Ver `tools/clips/README.md`.
- Nada de políticos, partidos ni billetes reales.

## Ideas para después del playtest
No implementar hasta que Agus lo pida.
- La imprenta acelera la inflación: más producción ya a cambio de más inflación después.
- La imprenta y el holding se desbloquean recién en la vuelta ~36 (~2 h): casi nadie los va a ver. Evaluar adelantarlos.
- El remarcar automático (vuelta 14) mata la hiperinflación y la tensión del late game.
- En la vuelta 1 el bot "activo" pasa 5 min solo con carrito y kiosco: chequear en el playtest si a una persona le pasa igual.
- La notación de números grandes ("$5,97 Dc", "$2e41") es ilegible: evaluar nombres ("5,97 decillones") o un formato más claro.
