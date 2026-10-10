#!/bin/sh
# Compila os shaders para o formato .qsb que o Qt 6 usa.
set -e
cd "$(dirname "$0")"
QSB=$(command -v qsb || echo /usr/lib/qt6/bin/qsb)
for f in aurora nebulosa particulas ondas pulso; do
    { sed -n '1,999p' common.glsl; cat "$f.frag"; } > "/tmp/cypher-$f.frag"
    "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$f.frag.qsb" "/tmp/cypher-$f.frag"
    rm -f "/tmp/cypher-$f.frag"
done
cp textgrad.frag.src /tmp/cypher-textgrad.frag
"$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o textgrad.frag.qsb /tmp/cypher-textgrad.frag
rm -f /tmp/cypher-textgrad.frag
echo "shaders ok"
