# Software Diversity – Build Pipeline Security

## Objectifs
L’objectif de ce travail est d’évaluer comment la diversité logicielle appliquée aux pipelines de build peut renforcer la sécurité des chaînes d’approvisionnement logicielle.  
L’étude se concentre sur la comparaison des systèmes de build **Maven** et **Gradle** à travers des projets Java réels (ex. MyBatis), afin de :  
- Identifier les sources de non-déterminisme dans la production des artefacts.  
- Évaluer leur impact sur la reproductibilité et la traçabilité.  
- Explorer la diversité comme levier de détection d’anomalies ou d’attaques (backdoors, trusting trust).  

## Contenu
- **Artefacts JAR** générés avec Maven et Gradle.  
- **Extraction des contenus** (META-INF, MANIFEST, bytecode).  
- **SBOMs** générés avec Syft pour chaque build.  
- **Arbres de dépendances** Maven et Gradle.  
- **Scripts** Bash et Python pour automatiser la migration Maven2Gradle, l’analyse et la comparaison.  

## Expérimentations
1. **Migration Maven → Gradle**  
   - Conversion manuelle du `pom.xml` en `build.gradle.kts`.  
   - Reproduction des plugins et profils.  
   - Vérification d’équivalence fonctionnelle.  

2. **Comparaison Maven vs Gradle**  
   - Diffoscope sur les JAR.  
   - Analyse des dépendances et SBOM.  

3. **Analyse des différences**  
   - Timestamps, ordre des entrées, métadonnées, bytecode, `pom.properties`...

4. **Correction des différences**  
   - Exclure les timestamps.  
   - Forcer l’ordre des entrées JAR.  
   - Harmoniser `MANIFEST.MF`.  
   - Fixer `targetCompatibility`.  
   - Régénérer `pom.properties`.  




## Résultats

La comparaison des artefacts générés par **Maven** et **Gradle** a mis en évidence plusieurs sources de non-déterminisme.  
Ces différences expliquent pourquoi deux builds fonctionnellement équivalents peuvent produire des JAR divergents au niveau binaire.

### Sources de non-déterminisme observées

| Source              | Maven                                | Gradle                         | Explication                                                                 | Correction possible |
|---------------------|--------------------------------------|--------------------------------|-----------------------------------------------------------------------------|---------------------|
| **Timestamps**      | Exclus automatiquement               | Inclus                         | Chaque build Gradle génère des horodatages différents → différences binaires | Exclure explicitement (`preserveTimestamps`) |
| **Ordre des entrées JAR** | Alphabétique                     | Non garanti                    | L’ordre variable des fichiers dans l’archive empêche la reproductibilité     | Forcer un ordre fixe (`reproducibleFileOrder = true`) |
| **Métadonnées**     | Riches (JDK, vendor, commit…)        | Minimales                      | Divergences dans le contenu du MANIFEST et traçabilité réduite               | Harmoniser le contenu du `MANIFEST.MF` |
| **Version du bytecode** | Java 11                          | Java 17 (par défaut)           | Impact sur la compatibilité et le comportement à l’exécution                 | Fixer `targetCompatibility` |
| **pom.properties**  | Généré (version/date du projet)       | Absent (non copié ou généré)   | Maven ajoute automatiquement des infos de version, non répliquées dans Gradle | Regénérer manuellement ou l’utiliser pour la traçabilité |

### Interprétation

- **Maven** tend à produire des artefacts plus riches en métadonnées, facilitant la traçabilité mais introduisant plus de points de divergence.  
- **Gradle**, par défaut, introduit du non-déterminisme (timestamps, ordre des fichiers) et un bytecode compilé en Java 17, ce qui accentue les écarts.  
- Ces différences sont **bénignes** dans un contexte normal, mais deviennent utiles comme **indicateur d’anomalie** si des divergences supplémentaires apparaissent (par exemple en cas de backdoor).  

En résumé, la diversité des builds Maven/Gradle permet de générer des **artefacts divergents mais valides**, qui peuvent servir de référence croisée pour détecter des comportements suspects dans la supply chain logicielle.


## Outils
- **Maven / Gradle** : systèmes de build.  
- **Syft / Grype** : génération de SBOM et détection de vulnérabilités.  
- **diffoscope / meld** : comparaison d’artefacts et de hiérarchies.  
- **jnorm** : normalisation des builds Gradle.  
- **Docker / Testcontainers** : environnements de tests reproductibles.  

## Perspectives
- Automatiser partiellement le processus de **migration Maven → Gradle**, afin de réduire l’effort manuel tout en préservant l’équivalence fonctionnelle des builds.  
- Développer des méthodes pour **détecter et classifier les différences** entre artefacts Maven et Gradle, en distinguant les variations bénignes (timestamps, ordre des entrées, métadonnées) des **divergences suspectes** pouvant indiquer une compromission.  
- **Simuler des attaques réelles** (par exemple insertion d’une backdoor, ou attaque de type *trusting trust*) afin d’évaluer la résilience du pipeline de build et de valider le rôle de la diversité logicielle dans la détection d’anomalies.  


## Références
- Forrest et al., *Software Diversity: Divided We Win*.  
- Fourné et al., *It’s like flossing your teeth: On the Importance and Challenges of Reproducible Builds*.  
- Xiong et al., *Towards Build Verifiability for Java-based Systems*.  
- Apache, *Migrating Builds From Apache Maven*.  
- DALEQ, *Explainable Equivalence for Java Bytecode*.  
- NSTAC, *Beyond SolarWinds: Principles for Securing Software Supply Chains*.  
- Thompson, *Reflections on Trusting Trust*.  
- McDermott, *Countering Trusting Trust through Diverse Double-Compiling*.  
