# Medal Frontline — Capture de zones façon Hell Let Loose

Addon **séparé** pour Garry's Mod (compatible avec `medal_barracks_menu_vietnam` :
les factions sont lues sur `MedalBarracks_ArmyChoice`).

## Installation
Copie le dossier `medal_frontline/` dans `garrysmod/addons/`.

## Modes (choisis depuis le panneau staff)
- **WARFARE** : 5 secteurs en ligne, chaque camp démarre avec 2 secteurs,
  seule la ligne de front est capturable. Victoire : tous les secteurs, ou
  majorité à la fin du temps.
- **OFFENSIVE** : un camp attaquant (configurable dans le panneau) capture les
  secteurs dans l'ordre ; chaque capture ajoute du temps. Les défenseurs
  gagnent s'ils tiennent jusqu'au bout.
- **ESCARMOUCHE** : un unique point central ; le tenir rapporte des tickets,
  premier camp au quota gagne.

## Panneau staff
Commande : `medal_frontline_staff` (admin).
- Choix du mode, du camp attaquant, LANCER / ARRÊTER / RÉINITIALISER.
- **Définition des secteurs en jeu** : place-toi au centre du secteur et clique
  « DÉFINIR ICI » — sauvegarde automatique par map dans `data/medal_frontline/`.
- Rappel des joueurs actifs par camp.

## HUD
- Barre de secteurs HLL en haut : segments ruban, cadenas (verrouillé),
  progression de capture, liseré pulsant si contesté, timer.
- **Compteur des joueurs ACTIFS des deux camps** : les joueurs **AFK depuis
  plus de 5 minutes** (`cfg.ActiveAFKSeconds`) **ne sont pas comptés**.
- Indicateur « CAPTURE EN COURS » quand tu es dans un secteur actif.

## Config
`lua/medal_frontline/sh_config.lua` : factions, couleurs, vitesses de capture,
rayon des secteurs, durées par mode, tickets d'escarmouche, HUD.

## SWEPs (outils)
- **Outil de secteur** (`medal_zone_tool`, staff) : en main, toutes les zones
  s'affichent en surbrillance avec leur nom au-dessus. Clic gauche = créer,
  clic droit = déplacer la plus proche, R = supprimer, molette = rayon.
- **Carte tactique** (`medal_map`) : clic gauche ouvre une carte vue de dessus
  de toute la map. Les **chefs d'escouade et le commandement** peuvent y poser
  des marqueurs (attaque, défense, mouvement, ennemi, objectif) **visibles
  uniquement par les autres chefs/commandement de leur camp**. La carte est
  donnée automatiquement aux loadouts commandant/officier.

## Ordre de capture (HUD)
Au-dessus de la barre de secteurs, des flèches indiquent l'ordre/le sens de
capture ; en mode Offensive, chaque secteur porte son numéro d'ordre (#1, #2…).
Tout s'adapte automatiquement au nombre de secteurs créés.

## Drapeaux (façon MG CTF)
Chaque secteur porte un **mât avec un drapeau** coloré par camp ; pendant une
capture, le drapeau monte/descend selon la progression (comme un drapeau CTF
qu'on hisse), et devient blanc quand le point est contesté.

## Logos de faction (Imgur) & renommage
- `cfg.FactionLogos` : colle des liens **Imgur** ; l'addon télécharge et met en
  cache les images, les affiche **au centre de l'écran** lors d'une capture
  (bandeau `cfg.CaptureBanner`) et **sur les drapeaux** en jeu.
- Renomme un secteur : prends l'outil de secteur, vise-le et appuie sur **F**.
