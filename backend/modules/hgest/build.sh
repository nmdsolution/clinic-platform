#!/bin/sh
# Construit hgest-<version>.omod sans Maven : compilation contre les bibliothèques de la distribution
# elle-même (openmrs.war et modules billing, fhir2, webservices.rest, stockmanagement), donc toujours
# avec les mêmes versions que celles qui tournent.
#
#   sh build.sh <dossier distribution> <dossier de sortie>
#   ex. dans backend/Dockerfile : sh build.sh /openmrs/distribution /openmrs/distribution/openmrs_modules
set -eu

SRC=$(cd "$(dirname "$0")" && pwd)
DIST=$1
OUT=$2
VERSION=$(sed -n 's:.*<version>\(.*\)</version>.*:\1:p' "$SRC/src/main/resources/config.xml" | head -1)
W=$(mktemp -d)

mkdir -p "$W/cp" "$W/classes"
cd "$W/cp"
jar xf "$DIST/openmrs_core/openmrs.war" WEB-INF/lib
for m in billing fhir2 webservices.rest stockmanagement; do
  for f in "$DIST"/openmrs_modules/$m-*.omod; do jar xf "$f" lib; done
done
CP=$(find "$W/cp" -name '*.jar' | tr '\n' ':')

javac -encoding UTF-8 --release 17 -nowarn -proc:none -cp "$CP" -d "$W/classes" $(find "$SRC/src/main/java" -name '*.java')
cp -r "$SRC"/src/main/resources/. "$W/classes/"
mkdir -p "$OUT"
(cd "$W/classes" && jar cf "$OUT/hgest-$VERSION.omod" .)
rm -rf "$W"
echo "hgest-$VERSION.omod construit dans $OUT"
