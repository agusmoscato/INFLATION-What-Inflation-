# Íconos de negocios

El juego dibuja cada ícono por código (trazo de tiza, `scripts/ui/chalk_icons.gd`).
Para reemplazarlos por dibujos hechos a mano, poné un PNG con el id del negocio en esta carpeta:

```
assets/icons/<id>.png
```

Si el archivo existe se usa en lugar del dibujo por código; si no, el dibujo por código sirve de respaldo.
Recomendado: PNG cuadrado (256x256 o 512x512) con fondo transparente y trazo claro (blanco/tiza) para que se lea sobre el pizarrón.

Ids: `empanadas`, `kiosco`, `choripan`, `lavadero`, `panaderia`, `almacen`, `remiseria`, `verduleria`,
`fabrica`, `cadena`, `banco`, `bolsa`, `cripto`, `imprenta`, `ceros`, `holding`.

Después de agregar un PNG abrí el proyecto en el editor una vez (o corré `godot --headless --import`) para que Godot lo importe.
