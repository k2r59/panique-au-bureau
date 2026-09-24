# Contrôle des animations

24 septembre 2026. Version locale après correction de la répétition du combo ×5.

Verdict : **10/10 sur les dix critères visuels et temporels définis ci-dessous**, pour le rendu natif contrôlé. Aucun défaut concret restant n’a été trouvé dans ce périmètre. Cette note ne mesure pas la ressemblance globale avec la maquette ni la fluidité sur téléphone.

## Preuves

L’agent qualité a exécuté Godot 4.7.2 avec le rendu OpenGL natif, au format 390 × 844. Un script temporaire a fixé les horloges d’animation à des instants connus et enregistré les images correspondantes. Il n’a modifié ni le code applicatif ni les sauvegardes.

- Descente : neuf instants de 0 à 240 ms, avec fantôme, zombie, vampire et collègue sur plusieurs bureaux. Planche : `build/qa-animations/descent-contact.png`.
- Flottement : douze instants de 0 à 6,6 s, espacés de 600 ms, couvrant plus d’un cycle complet de chaque objet. Planche : `build/qa-animations/float-contact.png`.
- Entrée du combo ×3 : 0, 70, 140, 200, 300, 400, 650, 750 et 1 200 ms. Planche : `build/qa-animations/combo-contact.png`.
- Confirmation du combo ×5 : mêmes neuf instants. Planche : `build/qa-animations/repeat-contact.png`.

Les planches se lisent de gauche à droite, puis de haut en bas. Les images individuelles figurent dans le même dossier. Les formules de déplacement, les conditions de déclenchement et les limites de durée ont aussi été examinées dans `scripts/main.gd` et `scripts/round.gd`.

Une première capture a croisé des imports d’assets en cours et était invalide. Toutes les planches mentionnées ci-dessus ont ensuite été régénérées sans erreur de chargement.

## Dix critères d’acceptation

Chaque critère vaut un point. Un échec entraîne le refus au seuil demandé de 10/10.

| Critère | Constat | Résultat |
|---|---|---|
| 1. Déclenchement cohérent | La sortie suit la touche ou l’expiration. Le combo suit un changement de palier ou une confirmation au plafond. | 1/1 |
| 2. Durée bornée des effets de jeu | Sortie de 240 ms, entrée du combo stabilisée après 650 ms, éclats éteints après 750 ms. | 1/1 |
| 3. Trajectoire de sortie cohérente | Le personnage descend progressivement. Aucun déplacement latéral ni changement d’échelle ne détourne cette lecture. | 1/1 |
| 4. Continuité du flottement | Les sinusoïdes du fantôme et de la coupe ne présentent pas de rupture à la fermeture du cycle. | 1/1 |
| 5. Lisibilité du combo | Le texte demeure identifiable durant l’entrée, l’amortissement et la confirmation. Le multiplicateur reste visible. | 1/1 |
| 6. Séparation des zones de jeu | Aux phases contrôlées, le combo et ses éclats ne masquent ni le compteur ni les cibles de la grille. | 1/1 |
| 7. Profondeur et occlusion | Le mobilier passe devant le personnage qui descend. Le masque reste attaché au bureau. | 1/1 |
| 8. Fin de sortie propre | Le personnage est caché avant la suppression de la cible ; aucune partie ne réapparaît sous le bureau dans les images contrôlées. | 1/1 |
| 9. Répétition sans rétrécissement brutal | Au plafond ×5, le label part désormais de 100 %, atteint 108 % et revient à 100 %. | 1/1 |
| 10. Réduction des mouvements respectée | Le code conditionne les déplacements, le flottement et le changement d’échelle à `motion_enabled`. | 1/1 |

## Défaut refusé puis corrigé

La première version répétait l’entrée à une échelle de 50 % après chaque groupe de trois succès au plafond ×5. Le label était déjà visible à sa taille normale : ce redémarrage produisait donc une contraction instantanée et répétitive. Cette version ne satisfaisait pas le critère 9 et était refusée.

La version contrôlée distingue la confirmation au plafond avec `combo_repeat`. Les captures successives confirment une variation de taille limitée à 8 %, avec retour à la taille normale. L’entrée plus marquée reste réservée aux changements de palier.

## Conclusion par animation

- **Descente derrière les bureaux : acceptée.** Trajectoire et occlusion sont propres dans les séquences examinées.
- **Fantôme et coupe : acceptés.** Le déplacement reste faible, continu et lisible ; la coupe conserve une ombre dont la variation suit sa hauteur.
- **Combo corrigé : accepté.** L’entrée se stabilise, les éclats s’éteignent et la répétition au plafond ne recommence plus par une contraction à 50 %.

## Limites de cette validation

Les images proviennent d’instants contrôlés, et non d’une vidéo chronométrée de la boucle de rendu. Elles permettent d’examiner les trajectoires et les couches, mais ne prouvent pas l’absence de saccades, de pertes d’images ou de latence tactile.

La note de 10/10 porte exclusivement sur les dix critères annoncés. La cadence réelle dans la PWA, les appareils mobiles, les tailles réduites et les interruptions de navigateur restent hors de cette passe. Une régression observée sur ces supports doit rouvrir la validation concernée ; cette note ne doit pas être présentée comme une perfection universelle ou une fidélité de 98 % à la maquette.
