# Panique au bureau

Jeu de réflexes réalisé avec Godot 4.7.2, en GDScript. Le projet utilise les illustrations, animations et sons du dossier fourni « panique-au-bureau 3 ».

## Jouer dans Godot

1. Importer `project.godot` dans Godot 4.7.2.
2. Appuyer sur **F6** depuis la scène `scenes/main.tscn`, ou sur **F5** pour lancer le projet.
3. Sélectionner **Jouer**.
4. Saisir un pseudo de 2 à 16 caractères, puis sélectionner **C’est parti !**.

Chaque partie dure 60 secondes, après un décompte de trois secondes. Toucher les monstres rapporte 50 points ; les bonbons rapportent 100 points. Le multiplicateur augmente toutes les trois touches réussies, jusqu’à ×5. Toucher un collègue ou une citrouille retire 100 points et annule le combo. Laisser partir un monstre annule aussi le combo. Le score reste positif ou nul.

Cliquer ou toucher une case pour jouer. Les touches de la rangée **1 à 9** correspondent aux cases de gauche à droite et de haut en bas, y compris sur un clavier AZERTY. Le pavé numérique suit sa disposition habituelle. **P** ou **Échap** met en pause. **Entrée** lance une partie ou reprend la partie en pause. Le jeu se met en pause lorsqu’il perd le focus.

Les personnages gardent une pose fixe ; seuls les retours de touche et une courte arrivée de la cible bougent. Le son est coupé au premier lancement. Le meilleur score de chaque pseudo et les préférences sont enregistrés sur l’appareil, dans `user://records.json`. Le classement affiche les cinq meilleurs pseudos ; le jeu conserve jusqu’à 100 pseudos sur l’appareil. Le navigateur conserve ses propres records, séparés de ceux du jeu natif. Effacer les données du site supprime ces records.

## Tester la PWA locale

Un export existe dans `build/web/`. Depuis le dossier du projet, lancer :

```sh
./tools/serve-web.sh
```

Ouvrir [le jeu local](http://localhost:8765). Arrêter le serveur avec **Ctrl+C**. Si le port est occupé, utiliser `PORT=8766 ./tools/serve-web.sh`.

## Régénérer l’export web

Le préréglage **Web PWA** active le manifeste, le service worker et l’orientation portrait. Il utilise le moteur de rendu Compatibility et désactive les threads.

Les modèles d’export web de Godot 4.7.2 sont installés sur ce Mac. Depuis le dossier du projet, lancer :

```sh
./tools/export-web.sh
```

Sur un autre ordinateur, installer les modèles d’export correspondant à la version de Godot. Définir `GODOT_BIN` si l’exécutable se trouve ailleurs que dans `/Applications/Godot.app/Contents/MacOS/Godot`.

Pour publier la PWA, servir le contenu complet de `build/web/` sur un hébergement HTTPS. Activer la compression Brotli ou gzip côté serveur, notamment pour les fichiers `.wasm` et `.pck`. L’export brut représente environ 48 Mio, dont 38 Mio pour le moteur WebAssembly. Le projet n’a pas encore été publié.

Le service worker de Godot permet la mise en cache du jeu après chargement. Le navigateur peut libérer son stockage ; le premier chargement nécessite une connexion. Sur mobile, utiliser la commande d’installation ou d’ajout à l’écran d’accueil du navigateur. Ces comportements dépendent du navigateur. Consulter la [documentation d’export web de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

## Vérifier les règles et les écrans

Depuis le dossier du projet :

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_round.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/smoke.gd
```

Le premier test vérifie le score, les combos, les pièges, les cibles expirées, la pause et la fin de partie. Le second lance les scènes, vérifie les commandes et la sauvegarde, puis produit cinq captures dans `build/`. Il restaure les records présents avant le test.

Les tests passent sur ce Mac. `tests/responsive.gd` vérifie les quatre vues sur cinq formats, de 320 × 568 à 430 × 932 et en paysage. La page web occupe la zone visible sans défilement ; les commandes respectent les marges de sécurité du téléphone. L’export web a été lancé dans le navigateur intégré de Codex. L’absence de défilement a été vérifiée à 320 × 568, 390 × 844 et 430 × 932. Le rapport indépendant figure dans `QA.md`. La fluidité et l’installation sur un véritable iPhone ou Android restent à vérifier. La version Canvas sera envisagée si les essais sur les appareils cibles montrent des ralentissements.

## Fichiers principaux

- `scripts/round.gd` : règles, apparitions et difficulté progressive.
- `scripts/main.gd` : affichage, commandes, son et sauvegarde.
- `scenes/main.tscn` : scène principale.
- `export_presets.cfg` : configuration de la PWA.
- `assets/` : ressources du kit fourni ; les doublons PNG et SVG inutiles sont exclus de l’export.

Le classement présente uniquement les parties enregistrées sur cet appareil. Aucun compte ni classement en ligne n’est implémenté. Les neuf bureaux sont issus de `assets/generated/desks-atlas.png`, créé avec ImageGen à partir de la maquette fournie. La police de titres Lilita One conserve sa licence OFL dans `assets/fonts/LilitaOne-LICENSE.txt`. Les polices DejaVu conservent leur licence dans `assets/fonts/LICENSE.txt`. Godot est distribué sous [licence MIT](https://godotengine.org/license/).
