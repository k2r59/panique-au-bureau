# Revue visuelle complète

24 septembre 2026. Revue indépendante de la version locale, avant publication.

Le seuil demandé de 98/100 n’est pas atteint dans cette revue. Le jeu présente une direction graphique cohérente et des écrans utilisables au format nominal. Les écarts de composition et la lisibilité sur petit écran empêchent une validation à ce niveau.

## Périmètre et méthode

Captures examinées : `build/home.png`, `profile.png`, `game.png`, `results.png`, `countdown-wide.png`, les huit variantes à 320 × 568 et 430 × 932, puis `results-fixture.png`. Cette dernière contient un classement réaliste en mémoire et permet la comparaison avec la référence de résultat. Les références sont les deux images fournies par l’utilisateur, avec les trois écrans et le résultat seul.

Les captures ne constituent pas une vérification du site publié. La version publiée peut être antérieure. Aucun navigateur partagé n’a été manipulé et aucun fichier applicatif n’a été modifié pendant cet audit.

La grille attribue 40 points à l’illustration et à la composition, 25 à la typographie et à la hiérarchie, 20 aux finitions et 15 à l’adaptation aux tailles d’écran. Ces notes sont des jugements éditoriaux, avec une incertitude d’environ cinq points. Elles ne mesurent ni une similarité pixel à pixel ni un pourcentage de conformité démontré. Le profil et le compte à rebours n’ont pas de maquette dédiée ; leur composition est évaluée selon la cohérence avec les autres écrans.

| Vue | Illustration / 40 | Typographie / 25 | Finitions / 20 | Adaptation / 15 | Total / 100 |
|---|---:|---:|---:|---:|---:|
| Accueil | 32 | 19 | 18 | 9 | 78 |
| Pseudo et avatar | 34 | 22 | 18 | 8 | 82 |
| Partie | 28 | 19 | 18 | 9 | 74 |
| Résultat, avec classement réaliste | 32 | 21 | 19 | 10 | 82 |
| Compte à rebours | 35 | 23 | 18 | 12 | 88 |
| Chargement web | Non évalué visuellement | Non évalué visuellement | Non évalué visuellement | Non évalué visuellement | Non noté |

## Défauts prioritaires

### P1 : petit écran lisible seulement en agrandissant

À 320 × 568, le contenu conserve les proportions de 390 × 844. Le facteur de réduction est de 0,673 : un texte de 11 px devient environ 7,4 px, une aide de 12 px devient 8,1 px. Le champ de 54 px ne mesure plus que 36 px de haut et le bouton de 63 px environ 42 px. Les cartes restent dans l’écran, mais leurs descriptions et les aides du profil deviennent trop petites.

Correction : prévoir une composition compacte pour les écrans courts. Réduire la hauteur de l’illustration d’accueil et du profil, puis conserver des textes secondaires d’au moins 12 px et des commandes d’environ 44 px. Valider aussi le profil avec le clavier virtuel affiché. Le contrôle de débordement actuel ne mesure pas la lisibilité.

### P2 : composition du jeu encore différente

Les neuf décors sont distincts, mais les ordinateurs occupent presque tous le centre à une taille similaire. La maquette varie davantage leur emplacement et donne plus de place aux personnages. Les cloisons grises du jeu paraissent plus froides et uniformes. Un grand espace sépare le compteur de la grille, surtout sans combo actif.

Correction : déplacer quelques ordinateurs sur les côtés, agrandir les personnages sans masquer leur visage et rapprocher la grille de la zone combo. Garder les poses fixes et les arrivées brèves. Refaire une capture avec six cibles et un combo actif pour évaluer l’ensemble.

### P2 : hiérarchie typographique de la maquette atténuée

À l’accueil, les descriptions des règles sont petites par rapport aux titres et à l’illustration. Au résultat, le titre et les pseudos ont moins de présence que dans la référence. Le trophée est petit ; la composition paraît moins festive. Le tableau, le score vert et la ligne orange sont néanmoins cohérents et bien alignés.

Correction : augmenter les descriptions et les pseudos, renforcer le titre du résultat et agrandir le trophée. Comparer des captures au même cadrage utile, en retirant le cadre de téléphone de la référence avant comparaison. Ne pas ajouter de mouvements pour compenser ces écarts.

### P2 : preuves insuffisantes pour tous les états

Les variantes de taille du résultat affichent « Bien joué, ! », car le test ouvre directement cette vue sans pseudo. Elles montrent aussi un classement vide ; les variantes du jeu n’ont aucune cible. Ces données de test ne prouvent pas un défaut du parcours normal, qui impose le pseudo. Elles ne permettent pas de contrôler les collisions entre un pseudo long et un score, ni la carte du prochain rang sur petit écran.

Correction : utiliser des données en mémoire représentatives pour toutes les tailles : pseudo de 16 caractères, cinq participants, scores à cinq chiffres, ligne active au rang 3 et prochain rang. Ajouter les états de saisie invalide, de combo élevé et de fin de temps. Vérifier la persistance et les erreurs réseau séparément.

## Finitions par vue

- Accueil : logo et fantôme cohérents avec la référence, cartes sans chevauchement, bouton visible. Les détails de l’illustration et les proportions restent différents.
- Profil : portraits correctement arrondis, sélection visible et champ lisible au format nominal. Le carrousel indique le geste attendu. Le clavier mobile n’a pas été observé dans cet audit.
- Partie : légende unifiée claire, objets visibles devant le mobilier et médaillon du record lisible. La barre du temps est propre. La vue avec combo actif manque au dossier de captures examiné.
- Résultat : portraits ronds et ligne active propres. Dans la capture réaliste examinée, les nombres apparaissent encore sous la forme « 4260 » et « 4850 », alors que la référence les groupe. Une correction annoncée après cette capture doit être confirmée par une nouvelle image.
- Compte à rebours : le voile assombrit toute la surface large et le chiffre reste central. Le bouton de son reste très lumineux au-dessus du voile ; l’atténuer réduirait la distraction.

## Chargement web et limites

Le code de `web/shell.html` a été examiné sans imprimer les images intégrées. Il prévoit le visuel, le texte « CHARGEMENT », une barre arrondie, une mise à l’échelle et le respect de la préférence de réduction des animations. Le fantôme oscille encore de six pixels en boucle. Aucun rendu du chargement n’a été examiné lors de cette passe : attribuer une note visuelle serait injustifié.

Le code d’adaptation tient compte des marges de sécurité du navigateur. Leur comportement, le clavier virtuel, la fluidité et l’installation PWA doivent encore être contrôlés sur un téléphone réel. Une validation à 98/100 nécessiterait de corriger les écarts ci-dessus puis de revoir toutes les vues et leurs états représentatifs, y compris le chargement, sur captures comparables et sur appareil.

## Addendum : résultat après corrections

La nouvelle capture `build/results-fixture.png` montre un trophée plus grand, vu de trois quarts, des scores regroupés par milliers, des pseudos et scores de classement agrandis, ainsi que des portraits ronds. L’icône de reprise est lisible. Aucun chevauchement n’apparaît avec les cinq noms et scores de cette capture.

La note du résultat passe de 82 à **85/100** : illustration et composition 34/40, typographie et hiérarchie 22/25, finitions 19/20, adaptation 10/15. Le gain concerne la présence du trophée et la lisibilité des scores. Les notes des autres vues restent inchangées.

Le code prévoit un flottement du trophée de cinq pixels sur 4,6 secondes, avec une ombre variable. Une image fixe ne permet pas de juger le confort de cette animation. Le titre demeure plus petit et plus plat que dans la référence ; l’illustration et les espacements restent différents. Le comportement avec des noms longs et les petites tailles nécessite toujours des captures représentatives. Ces réserves empêchent une validation à 98/100.

Une tentative de contrôle du chargement dans le navigateur intégré a échoué : l’outil a signalé que le navigateur `iab` était indisponible pour cet agent. Aucun onglet ni réglage d’affichage n’a été modifié. La note du chargement reste donc ouverte.
