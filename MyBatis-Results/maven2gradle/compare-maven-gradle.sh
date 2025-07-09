#!/usr/bin/env bash
#
#    Copyright 2009-2025 the original author or authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

set -euo pipefail

# par défaut
JAR_MAVEN=${1:-mybatis-maven.jar}
JAR_GRADLE=${2:-mybatis-gradle.jar}

# Existence
for f in "$JAR_MAVEN" "$JAR_GRADLE"; do
  [[ -f $f ]] || { echo "Fichier introuvable : $f"; exit 1; }
done

echo "=== Comparaison Maven vs Gradle ==="
echo "Maven JAR : $JAR_MAVEN"
echo "Gradle JAR: $JAR_GRADLE"
echo

# --- Étape 1 – Fonctionnel ? ---
echo ">>> Étape 1 – Fonctionnel"
javac -cp .:mybatis-maven.jar TestMyBatis.java
javac -cp .:mybatis-gradle.jar TestMyBatis.java
java -cp .:mybatis-maven.jar TestMyBatis
java -cp .:mybatis-gradle.jar TestMyBatis
echo

# --- Étape 2 – MANIFEST.MF ---
echo ">>> Étape 2 – MANIFEST.MF"
unzip -p "$JAR_MAVEN" META-INF/MANIFEST.MF > manifest-maven.txt
unzip -p "$JAR_GRADLE" META-INF/MANIFEST.MF > manifest-gradle.txt
echo "Diff du MANIFEST"
diff -u manifest-maven.txt manifest-gradle.txt || true
echo

# --- Étape 3 – Listing JAR ---
echo ">>> Étape 3 – Listing JAR"
jar tf "$JAR_MAVEN" > contents-maven.txt
jar tf "$JAR_GRADLE" > contents-gradle.txt
echo "Diff des listes de fichiers"
diff -u contents-maven.txt contents-gradle.txt || true
echo

# --- Étape 4 – Décompression & diff récursif ---
echo ">>> Étape 4 – Décompression et diff -r"
rm -rf maven-extracted gradle-extracted
mkdir maven-extracted gradle-extracted
( cd maven-extracted && jar xf "../$JAR_MAVEN" )
( cd gradle-extracted && jar xf "../$JAR_GRADLE" )
diff -r maven-extracted gradle-extracted > full-structure-diff.txt || true
echo "Résultat dans full-structure-diff.txt"
echo

# --- Étape 5 – Analyse de bytecode ---
echo ">>> Étape 5 – bytecode avec javap"
CLASS_PATH="org/apache/ibatis/session/SqlSession.class"
javap -v "maven-extracted/$CLASS_PATH"  > maven-SqlSession.txt  || echo "[!] pas trouvé dans Maven"
javap -v "gradle-extracted/$CLASS_PATH" > gradle-SqlSession.txt || echo "[!] pas trouvé dans Gradle"
echo "Diff bytecode"
diff -u maven-SqlSession.txt gradle-SqlSession.txt || true
echo

# --- Étape 6 – SBOM (Syft) ---
echo ">>> Étape 6 – génération SBOM"
syft "$JAR_MAVEN"  -o json > sbom-maven.json
syft "$JAR_GRADLE" -o json > sbom-gradle.json
echo "Diff SBOM JSON"
diff -u sbom-maven.json sbom-gradle.json || true
echo

# --- Étape 7 – Scan des Vulnérabilités avec Grype ---
echo ">>> Étape 7 – scan vulnérabilités Grype"
echo "→ Maven"
grype sbom-maven.json > grype-maven.txt || true
echo "→ Gradle"
grype sbom-gradle.json > grype-gradle.txt || true
echo "Résultats dans grype-*.txt"
echo

echo ">>> Étape 8 – signature Cosign"

# Génération de la paire de clés si nécessaire
if [[ ! -f cosign.key ]]; then
  echo "Génération de la clé cosign..."
  cosign generate-key-pair
fi

# Signature en bundle du JAR Maven
echo "→ signature Maven"
cosign sign-blob \
  --key cosign.key \
  --bundle "$JAR_MAVEN.bundle" \
  "$JAR_MAVEN"

# Signature en bundle du JAR Gradle
echo "→ signature Gradle"
cosign sign-blob \
  --key cosign.key \
  --bundle "$JAR_GRADLE.bundle" \
  "$JAR_GRADLE"

# Vérification du bundle pour Maven
echo "→ vérification Maven"
cosign verify-blob \
  --key cosign.pub \
  --bundle "$JAR_MAVEN.bundle" \
  "$JAR_MAVEN"

# Vérification du bundle pour Gradle
echo "→ vérification Gradle"
cosign verify-blob \
  --key cosign.pub \
  --bundle "$JAR_GRADLE.bundle" \
  "$JAR_GRADLE"

echo

echo "=== FIN du pipeline de comparaison ==="

