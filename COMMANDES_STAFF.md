# 📖 Medal Vietnam — Catalogue des commandes (document staff)

Document de référence pour le staff du serveur. Il couvre les trois addons :
**medal_barracks_menu_vietnam** (menus/caserne), **medal_frontline** (capture de zones)
et **medal_garage** (garage de véhicules).

> Toutes les commandes chat utilisent le préfixe **`!`**. L'ancien préfixe `/` reste
> accepté partout en alias (ex. `/garage` = `!garage`). Anti-spam : 1 commande
> chat max toutes les 0,5 s par joueur.

---

## 1. Commandes chat — TOUS LES JOUEURS

| Commande | Effet |
|---|---|
| `!aide` (ou `!commandes`) | Affiche la liste des commandes disponibles dans le chat. |
| `!menu` | Ouvre le menu principal (factions, personnage, déploiement). |
| `!caserne` | Ouvre la caserne (rôles, équipements, niveaux). |
| `!escouades` | Ouvre le menu des escouades (ABLE, BAKER, …). |
| `!presenter` | Se présente aux joueurs proches (système de relations RP, portée 150 u). |
| `!garage` | Ouvre le garage de véhicules (rôles autorisés uniquement — équipages, logistique…). |

### Canaux de communication

| Commande | Qui peut l'utiliser | Effet |
|---|---|---|
| `!sl <message>` | Commandant, officiers, chefs d'escouade — et radioman **si sa radio posée est réglée sur la fréquence COMMANDEMENT** | Message sur le canal COMMANDEMENT de la faction. |
| `!radio <message>` | Radiomen uniquement | Message sur le RÉSEAU RADIO de la faction (si la radio du radioman est sur la fréquence COMMANDEMENT, la transmission part au commandement). |

Les joueurs à ~10 m d'une radio posée entendent ce qui passe sur sa fréquence.

---

## 2. Commandes chat — STAFF UNIQUEMENT

| Commande | Effet |
|---|---|
| `!staffmenu` | Menu staff des personnages (voir/supprimer/modifier les personnages des joueurs). |
| `!musique` | Gestionnaire de musique d'ambiance (dossier Dropbox auto-actualisé : lecture/arrêt/volume). |
| `!frontline` | Panneau staff Frontline : onglets **OPÉRATION** (Warfare/Offensive/Escarmouche, camp attaquant, lancer/arrêter/réinitialiser), **SECTEURS** (renommer, rayon, téléporter, déplacer, supprimer, ajouter) et **RÉCOMPENSES** (XP + argent par capture). |
| `!garageconfig` | Config in-game du garage (façon WCD) : active/désactive chaque véhicule détecté, niveau requis, HP, essence, catégorie + fond Dropbox du menu. |

L'accès staff = `admin`/`superadmin` (barracks : `cfg.StaffMenu.MinAccess`), plus les
rangs listés dans `MedalGarage.Config.AdminRanks` et `MedalFrontline.Config` pour
leurs addons respectifs.

---

## 3. Commandes console — STAFF

À taper dans la console (F10 / `~`), ou depuis la console serveur (RCON).

### medal_barracks (menus / personnages / XP)

| Commande | Arguments | Effet |
|---|---|---|
| `medal_staff_menu` | — | Ouvre le menu staff des personnages. |
| `medal_camp_reset` | `<joueur>` | Réinitialise le choix de faction d'un joueur. |
| `medal_character_reset` | `<joueur> <americans\|vietcong\|all>` | Supprime le(s) personnage(s) d'un joueur. |
| `medal_xp_give` | `<joueur> <general\|role> <montant> [faction] [role_id]` | Donne de l'XP générale ou de rôle. |
| `medal_xp_reset` | `<joueur>` | Remet toute l'XP d'un joueur à zéro. |
| `medal_media_reload` | — | Recharge le manifest des médias distants (Dropbox) chez tous les clients. |

`<joueur>` accepte : SteamID64, SteamID ou une partie du pseudo.

### medal_frontline (capture de zones)

| Commande | Effet |
|---|---|
| `medal_frontline_staff` | Ouvre le panneau staff Frontline (= `!frontline`). |

### medal_garage (véhicules)

| Commande | Effet |
|---|---|
| `medal_garage` | Ouvre le garage (= `!garage`, ou touche **F4**). |
| `medal_garage_config` | Ouvre la config in-game du garage (= `!garageconfig`). |
| `medal_garage_point_add` | Pose une **plateforme de spawn** de véhicules à ta position (sauvegardée par map). |
| `medal_garage_npc_add` | Pose le **PNJ mécano** là où tu regardes (E dessus = ouvre le garage, sauvegardé par map). |
| `medal_garage_npc_clear` | Retire tous les PNJ mécanos de la map. |

---

## 4. SWEPs (armes-outils)

À donner via votre admin mod (`ulx giveswep`, etc.) ou le menu Q en tant qu'admin.

| Classe | Qui | Utilisation |
|---|---|---|
| `medal_zone_tool` | **Staff** | Création des secteurs Frontline. **Clic G** : créer un secteur, **Clic D** : déplacer le secteur visé, **R** : supprimer, **Molette** : ajuster le rayon, **F** : renommer. Les secteurs existants sont surlignés avec leur nom au-dessus. |
| `medal_map` | Chefs (SL/Commandant) | Carte tactique vue du dessus. **Clic G** : poser un marqueur, **Clic D** : retirer. Les marqueurs ne sont visibles que par les chefs d'escouade et le commandement de la même faction. |
| `medal_radio_swep` | Radiomen (auto via loadout) | **Clic D** : aperçu fantôme (vert = valide), **maintenir Clic G** : jauge de pose. **E** sur la radio posée : fréquence ; **maintenir E** : combiné (voix réelle sur le réseau). |
| `medal_supply_swep` | Soutien (auto via loadout) | Pose une caisse de ravitaillement (50 de supply). L'ennemi peut la démanteler (maintien E, cooldown configurable). |

---

## 5. Touches en jeu (rappel pour informer les joueurs)

| Touche | Contexte | Effet |
|---|---|---|
| **B** | À pied | Équipement rapide (dernière arme ↔ outil). |
| **E** (maintenir) | Sur radio posée / caisse / PNJ | Menu d'interaction (fréquence, combiné, démantèlement, garage). |
| **Molette** | Sélecteur d'armes | Change d'arme façon HLL (avec temps de sortie). |
| **F4** | Partout | Ouvre le garage (si le rôle y a droit). |
| **R** | Dans un véhicule | Change de siège façon HLL. |
| **G** (maintenir) | Près de son véhicule | Fait le plein via le ravitaillement Soutien. |
| **TAB** | Partout | Scoreboard : effectifs des deux camps (AFK > 5 min exclus du décompte actif). |

---

## 6. Panneaux staff — résumé rapide

- **`!staffmenu`** → personnages : liste par joueur/faction, modification, suppression.
- **`!musique`** → musique d'ambiance depuis le dossier Dropbox configuré (auto-actualisé).
- **`!frontline`** → opérations : mode (Warfare / Offensive / Escarmouche), camp attaquant,
  lancement/arrêt, gestion complète des secteurs (nom, rayon, position, TP) et récompenses
  de capture (XP + argent DarkRP), le tout sauvegardé automatiquement.
- **`!garageconfig`** → véhicules : tous les véhicules Workshop installés sont détectés
  automatiquement (Source, simfphys, LFS, WAC, SCars, Glide). Cochez ceux à activer, réglez
  niveau/HP/essence/catégorie, définissez le fond (lien Dropbox image ou vidéo) du menu.

---

## 7. Sécurité (info pour le staff technique)

- Tous les messages réseau sont **validés côté serveur** : vérification du rang staff,
  du rôle (radioman/soutien/équipage), de la faction, de la distance et des valeurs
  (clamps sur niveaux, HP, essence, rayons, longueurs de texte).
- **Anti-spam réseau** par joueur et par canal sur chaque receveur (0,15 s à 1 s selon l'action).
- L'anti-AFK bloque le gain d'XP après 3 min d'inactivité, et exclut du décompte
  Frontline après 5 min.
- Les sauvegardes (zones, plateformes, PNJ, véhicules, paramètres) sont en JSON dans
  `garrysmod/data/medal_frontline/` et `garrysmod/data/medal_garage/`, par map quand pertinent.
