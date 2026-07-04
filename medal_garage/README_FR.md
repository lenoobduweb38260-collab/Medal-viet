# Medal Garage — Véhicules par niveau, essence, HUD HLL, sièges

Addon **séparé** pour Garry's Mod. Fonctionne seul, mais s'intègre à
`medal_barracks_menu_vietnam` (niveau, rôles, ravitaillement Soutien).

## Installation
Copie `medal_garage/` dans `garrysmod/addons/`.

## Garage

Menu façon **William's Car Dealer** : liste des véhicules à gauche, grand
aperçu 3D rotatif à droite avec fiche et bouton **SORTIR CE VÉHICULE**.

- Ouvre avec **F4** (`cfg.OpenKey`) ou la commande `medal_garage`.
- Menu façon HLL : onglets par catégorie, véhicules **débloqués par niveau**
  (verrouillés + cadenas sinon), restrictions de rôle possibles.
- **Compatible n'importe quel véhicule Workshop** : chaque entrée se spawn par
  sa `class` (remplace les exemples dans `cfg.Vehicles` par tes chars/hélicos).
- Cooldown de spawn et limite de véhicules par joueur configurables.
- **Points de garage** (staff) : prends l'outil **"Point de garage"**
  (`medal_garage_point`), clic gauche pour poser un point, clic droit pour tout
  effacer. Sauvegardés par map. Les véhicules apparaissent au garage le plus
  proche et s'y ravitaillent automatiquement.

## Essence
- Chaque véhicule a une jauge d'essence (`cfg.Fuel`). Elle baisse à l'usage
  (ralenti + vitesse). À sec, le moteur cale.
- **Plein automatique** quand le véhicule est garé, à l'arrêt, près d'un garage.
- **Ravitaillement manuel** : maintiens **G** (`cfg.Fuel.RefuelKey`) près de ton
  véhicule ; consomme le ravitaillement des caisses de Soutien si présent.

## Sièges façon HLL
- Change de place avec **R** (`cfg.Seats.SwitchKey`) : cycle vers le prochain
  siège libre. Compatible multi-sièges GMod (pods enfants/proches) et API
  **Simfphys / LFS / Glide** détectées automatiquement.

## HUD véhicule façon HLL
Quand tu es dans un véhicule : nom, **siège actuel** + touche pour changer,
vitesse (km/h), **jauge d'essence**, vie du véhicule.

## Config
`lua/medal_garage/sh_config.lua` : catalogue des véhicules, niveaux, catégories,
essence, sièges, touches, rôles autorisés.
