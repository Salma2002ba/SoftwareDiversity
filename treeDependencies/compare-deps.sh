#!/usr/bin/env bash
set -euo pipefail

# Fichiers de travail
MAVEN_OUT=deps-maven.txt
GRADLE_OUT=deps-gradle.txt
MAVEN_HIER=deps-maven-hierarchy.txt
GRADLE_HIER=deps-gradle-hierarchy.txt

echo "==[1] Récupération de l'arbre Maven (compile) =="
mvn dependency:tree -Dscope=compile -Dverbose \
  | grep -v "Downloading" > "$MAVEN_OUT"

echo "==[2] Récupération de l'arbre Gradle (compileClasspath) =="
./gradlew dependencies --configuration compileClasspath --quiet \
  | grep -v ">" > "$GRADLE_OUT"

echo "==[3] Analyse des hiérarchies =="

#
# --- Analyse Maven ---
#
declare -a direct_mvn
declare -A trans_mvn
current=""

while IFS= read -r line; do
  # 1) dépendance directe
  if [[ $line =~ ^\[INFO\]\ ([\+\-\\]+)[[:space:]]*([^:]+):([^:]+):jar:([^:]+): ]]; then
    grp="${BASH_REMATCH[2]}"
    art="${BASH_REMATCH[3]}"
    ver="${BASH_REMATCH[4]}"
    current="$grp:$art:$ver"
    direct_mvn+=( "$current" )

  # 2) dépendance transitive normale
  elif [[ $line =~ ^\[INFO\]\ \|[[:space:]]*\\-[[:space:]]*([^:]+):([^:]+):jar:([^:]+): ]]; then
    grp="${BASH_REMATCH[1]}"
    art="${BASH_REMATCH[2]}"
    ver="${BASH_REMATCH[3]}"
    td="$grp:$art:$ver"
    trans_mvn["$current"]+="$td "
  fi
done < "$MAVEN_OUT"

# Écriture du fichier Maven
{
  echo "## Maven hierarchy (direct -> transitive)"
  for dep in "${direct_mvn[@]}"; do
    echo "- $dep"
    for td in ${trans_mvn[$dep]:-}; do
      echo "   -> $td"
    done
  done
} > "$MAVEN_HIER"


#
# --- Analyse Gradle (inchangé) ---
#
declare -a direct_grd
declare -A trans_grd
current=""

while IFS= read -r line; do
  # dépendance directe
  if [[ $line =~ ^[[:space:]]*(\+---|\\---)[[:space:]]*([^:]+:[^:]+:[^:]+) ]]; then
    current="${BASH_REMATCH[2]}"
    direct_grd+=( "$current" )

  # dépendance transitive
  elif [[ $line =~ ^[[:space:]]*\|[[:space:]]*\\---[[:space:]]*([^:]+:[^:]+:[^:]+) ]]; then
    trans_grd["$current"]+="${BASH_REMATCH[1]} "
  fi
done < "$GRADLE_OUT"

# Écriture du fichier Gradle en **ordre Maven** + éventuels extras
{
  echo "## Gradle hierarchy (direct -> transitive)"
  # d'abord tout ce qui était dans Maven, dans le même ordre
  for dep in "${direct_mvn[@]}"; do
    if [[ " ${direct_grd[*]} " == *" $dep "* ]] || [[ -n "${trans_grd[$dep]:-}" ]]; then
      echo "- $dep"
      for td in ${trans_grd[$dep]:-}; do
        echo "   -> $td"
      done
    fi
  done
  # ensuite, les directes Gradle non listées par Maven
  for dep in "${direct_grd[@]}"; do
    if [[ ! " ${direct_mvn[*]} " == *" $dep "* ]]; then
      echo "- $dep"
      for td in ${trans_grd[$dep]:-}; do
        echo "   -> $td"
      done
    fi
  done
} > "$GRADLE_HIER"

# Affichage rapide
echo
echo "### Maven ###"
cat "$MAVEN_HIER"
echo
echo "### Gradle ###"
cat "$GRADLE_HIER"

echo
echo "Hiérarchies exportées dans :"
echo "  • $MAVEN_HIER"
echo "  • $GRADLE_HIER"
