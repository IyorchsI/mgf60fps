
# VIBECODED

## patch.sh — Parcheador de 60 FPS para eboot.bin (PSP/PS Vita)

Script en Bash que aplica un parche binario de **60 FPS** a archivos `eboot.bin`
de varios juegos de la saga *Hatsune Miku: Project DIVA* y *Miracle Girls
Festival*. Identifica el juego/versión mediante el **hash MD5** del archivo
de entrada y, si lo reconoce, sobrescribe unos pocos bytes específicos en una
copia del ejecutable.

## Qué hace, paso a paso

1. **Configura el modo estricto de bash** (`set -euo pipefail`): el script se
   detiene ante cualquier error, ante el uso de variables no definidas, o
   ante el fallo de cualquier comando dentro de una tubería.
2. **Se ubica en su propia carpeta** (`cd "$(dirname "$0")"`), para que las
   rutas relativas (`eboot.bin`, `output/`) funcionen sin importar desde
   dónde se ejecute el script.
3. **Comprueba que exista `eboot.bin`** en esa carpeta. Si no está, muestra
   un mensaje pidiéndolo y termina.
4. **Calcula el hash MD5** del archivo y lo pasa a mayúsculas, para
   compararlo contra una lista de hashes conocidos.
5. **Crea la carpeta `output/`** si no existe.
6. **Compara el hash contra cada juego soportado** y, si coincide, copia
   `eboot.bin` a `output/eboot.bin` y sobrescribe en la copia los bytes
   indicados usando la función `patch_byte`.
7. Al final, informa si se aplicó algún parche o si el juego no está
   soportado.

## La función `patch_byte`

```bash
patch_byte() {
    local file="$1"
    local offset="$2"
    local hexbyte="$3"
    printf "\\x${hexbyte}" | dd of="$file" bs=1 seek="$offset" count=1 conv=notrunc status=none
}
```

Escribe **un solo byte** en una posición exacta (`offset`) de un archivo,
sin tocar el resto:

- `printf "\\x${hexbyte}"` genera el byte crudo a partir de su valor
  hexadecimal (por ejemplo `01` → el byte `0x01`).
- `dd ... bs=1 seek="$offset" count=1` le dice a `dd` que se posicione
  exactamente en `offset` (contando en bloques de 1 byte) y escriba
  únicamente 1 byte ahí.
- `conv=notrunc` es crítico: evita que `dd` trunque el archivo al tamaño de
  lo escrito. Sin esto, el archivo de salida quedaría reducido a solo ese
  byte.
- `status=none` silencia el resumen que `dd` imprime normalmente.

## Juegos y offsets reconocidos

| Juego | Hash MD5 esperado | Offsets modificados | Valores (original → parche) |
|---|---|---|---|
| Diva X ASIA | `733033E2DDF86D94FCA30B2AA1249302` | `0x3A32C`, `0x3AA5A` |  `02→01`, `02→01`, `f6→f7`  |
| Diva X JP | `04A530196C722D1A475082C57D85CFD7` | `0x3A320`, `0x3AA4E` |  `02→01`, `02→01`, `f6→f7` |
| Miracle Girls Festival | `9E50BD28879FC721AB724E97141F9D8A` | `0x4F464`, `0x4F5C0` |  `02→01`, `02→01`, `f6→f7` |
| Diva f US | `3727CEE0C28313B961634C15B3F7EA33` *(ver advertencia abajo)* | `0x4F767E`, `0x14764`, `0x149E8` | `02→01`, `02→01`, `f6→f7` |
| Diva f JP | `94AA36566BACEA2DC53ACA96920B3EC3` | `0x4A5316`, `0x142A6`, `0x14538` |  `02→01`, `02→01`, `f6→f7` |
| Diva F 2nd JP | `F161E1D7BB0CA56BBBB56A7B8794F52D` | `0xBA3C`, `0xBB9A` |  `02→01`, `02→01`, `f6→f7`  |

Los comentarios del propio script (líneas 25–33) documentan, para Diva f US,
qué instrucción de ensamblador ARM Thumb corresponde a cada offset:

```
0x4f767e   movs   param_1,#0x2      (cambia a #0x1)
0x14764    movs   r0,#0x2           (cambia a #0x1)
0x149e8    vmov.f32 s1,0x3f000000   (el byte f6 cambia a f7)
```

También hay una línea suelta, **sin usar en ningún parche activo**, que
apunta a un posible offset para **Diva X US** (`0x31d06`, instrucción
`movs r2,#0x2`) — queda como nota de investigación, no como parche
funcional.

## Requisitos

- Bash (con soporte de `set -o pipefail`, disponible en bash 3+).
- `md5sum`, `dd`, `printf`, `mkdir` — todas herramientas estándar de
  cualquier distribución Linux.

## Uso

```bash
chmod +x patch.sh
./patch.sh
```

Coloca `eboot.bin` en la misma carpeta que `patch.sh` antes de ejecutarlo.
El resultado (si el juego es reconocido) queda en `output/eboot.bin`; el
archivo original nunca se modifica.

## Limitaciones conocidas

- **Identificación frágil por hash MD5**: cualquier revisión de disco,
  build distinta, o parche previo ya aplicado cambia el hash y hace que el
  script no reconozca el archivo (ver el bug de arriba para el caso en que
  eso falla silenciosamente en vez de detenerse).
- **Sin verificación de los bytes originales** antes de escribir: el script
  no comprueba que el byte que va a sobrescribir tenga el valor esperado
  antes de parchear, así que un archivo ya parcheado o con una build
  distinta puede terminar con bytes escritos en offsets que no
  corresponden a la instrucción esperada.
- **Diva X (ASIA/JP) sin verificación de contexto**: a diferencia de Diva f
  US, esos offsets no tienen documentado en comentarios qué instrucción
  representan, así que no hay forma de confirmar por inspección que sigan
  siendo válidos si el binario cambia.
- No soporta Diva X USA (el offset `0x31d06` mencionado en un comentario no
  está integrado en ningún bloque de parche funcional).
