# Medal Barracks Menu Vietnam — v20 Anti-AFK, musiques Dropbox & Medal Frontline

## v20 — Anti-AFK XP, gestionnaire de musiques, addon Medal Frontline

### Anti-AFK sur l'XP
Un joueur inactif depuis plus de **3 minutes** (`cfg.XP.AFKBlock.Seconds`) ne
gagne **plus aucune XP** (générale ET de rôle) jusqu'à ce qu'il reprenne son
activité (mouvement, caméra, touche, chat). Le suivi d'activité est exposé en
global (`MedalAFK_IsAFK`) et réutilisé par Medal Frontline.

### Gestionnaire de musiques STAFF (dossier Dropbox auto-synchronisé)
Commande **medal_music** (staff) : menu HLL listant les musiques d'un dossier
Dropbox, **mise à jour automatique** (`cfg.Music.RefreshInterval`).
- **Mode API Dropbox** (recommandé) : renseigne `cfg.Music.Dropbox.AccessToken`
  + `FolderPath` — tout fichier audio ajouté au dossier apparaît tout seul
  (listing `files/list_folder` + liens temporaires `get_temporary_link`).
- **Mode manifest** : `cfg.Music.ManifestURL` vers un `musics.json` Dropbox.
- Lecture pour TOUT le serveur (sound.PlayURL), STOP, volume de diffusion,
  toast "♪ en lecture", les joueurs qui arrivent en cours reçoivent la musique.

### NOUVEL ADDON SÉPARÉ : Medal Frontline (dossier `medal_frontline/`)
Capture de zones façon Hell Let Loose — voir `medal_frontline/README_FR.md`.
- 3 modes choisis depuis le **panneau staff** (`medal_frontline_staff`) :
  **WARFARE** (5 secteurs, ligne de front), **OFFENSIVE** (attaque séquentielle
  avec temps additionnel par capture), **ESCARMOUCHE** (point unique à tickets).
- **Barre de secteurs HLL** en haut de l'écran : segments ruban inclinés,
  cadenas sur les secteurs verrouillés, progression de capture, timer.
- **Compteur de joueurs ACTIFS des deux camps** sous la barre : les joueurs
  **AFK depuis plus de 5 minutes ne sont pas comptés**.
- Secteurs définis en jeu (« DÉFINIR ICI ») et sauvegardés par map.

---

## v19 — Créateur de personnage 2 étapes, playlists Dropbox, sabotage des caisses

### Créateur de personnage en 2 étapes (référence "Character Creator")
- **ÉTAPE 1 — IDENTITÉ & APPARENCE** : prénom/nom côte à côte, **sliders ÂGE et
  TAILLE (cm)**, onglets **HOMME / FEMME**, **vignettes de modèles** cliquables
  et **aperçu du soldat en grand** à droite (mis à jour en direct).
- **ÉTAPE 2 — DOSSIER ADMINISTRATIF** : en cliquant sur SUIVANT, une nouvelle
  page s'ouvre en style document militaire 1968 tapé à la machine :
  récapitulatif (soldat, âge, taille, sexe), n° de dossier, nationalité,
  antécédents, tampon incliné et bouton SIGNER L'ENRÔLEMENT.
- Modèles féminins optionnels par faction : `army.characterModelsFemale = {...}`.
- Taille et genre sont sauvegardés en SQLite (migration automatique des tables
  existantes) et affichés sur la carte du personnage.

### Vidéo Dropbox persistante entre les pages
Le fond vidéo utilise désormais un **lecteur global unique** : tant que la
source configurée ne change pas (même lien, ou écran sans lien dédié qui
réutilise la vidéo principale), **la vidéo et sa musique continuent sans
redémarrer** quand on navigue entre menu principal, factions, personnages,
caserne, options… Quand tous les menus sont fermés, la vidéo se met en pause
et reprend au même endroit à la prochaine ouverture.

### Playlists Dropbox (musiques aléatoires)
`cfg.RemoteMedia.MainMenuDropboxVideo.Playlist = { "lien1", "lien2", … }` :
à la fin de chaque vidéo, une autre est **tirée au sort** (jamais deux fois la
même à la suite) — boucle infinie variée. Fonctionne aussi par écran via
`ScreenVideos.<écran>.Playlist`. Si Playlist est vide, `URL` reste utilisée.

### Sabotage : démonter le ravitaillement ennemi
Un joueur de la faction adverse (ex : Vietcong sur une caisse US) **maintient E
sur la caisse** pour la démonter : barre rouge de progression au-dessus de la
caisse, la progression retombe s'il relâche. Une fois démontée, **cooldown
configurable** avant de pouvoir en démonter une autre :
`cfg.Supply.Dismantle = {Enabled, Time = 4, Cooldown = 30}`.
Le propriétaire est prévenu quand sa caisse est démontée.

---

## v18 — Voix radio, ravitaillement, écrans factions/personnages refaits

### Combiné radio : le radioman PARLE dans la radio (voix réelle)
- **Maintiens E** sur une radio posée pour décrocher le combiné (appui court = menu
  de fréquence). Un bouton DÉCROCHER existe aussi dans le menu de la radio.
- Pendant l'appel, la voix est routée par `PlayerCanHearPlayersVoice` :
  - fréquence RÉSEAU RADIO → tous les radiomen de la faction l'entendent ;
  - fréquence COMMANDEMENT → commandant, officiers et chefs d'escouade ;
  - toute personne à 10 m d'une radio posée sur la même fréquence entend l'appel ;
  - les joueurs proches du parleur l'entendent parler dans le combiné (3D).
- Raccrochage automatique si on s'éloigne (config `cfg.Radio.Handset`).
- Indicateur HUD "COMBINÉ DÉCROCHÉ" avec témoin d'émission qui pulse.

### Correctif : formulaire de création lisible
La fiche d'enrôlement s'ouvre maintenant en PLEIN ÉCRAN avec un voile sombre
opaque au-dessus de la vidéo Dropbox — le formulaire est parfaitement lisible.

### Écran factions façon HLL (référence "VS.")
Deux emblèmes monochromes centrés avec **VS.** au milieu, nom espacé et
effectifs `27 / 50` en kaki sous chaque camp, éclaircissement au survol.

### Sélection de personnage à emplacements (référence "SELECT YOUR CHARACTER")
- Titre centré + "Nombre d'emplacements", slot jouable avec aperçu du modèle,
  nom/âge/nationalité, bouton **CONTINUER**, et **MODIFIER / SUPPRIMER**
  (suppression définitive avec confirmation, gérée côté serveur en SQLite).
- Emplacements décoratifs verrouillés VIP / STAFF (configurables dans
  `cfg.CharacterSlots.LockedSlots`).
- **UI différente par faction** (`cfg.CharacterSlots.Styles`) : panneau bleu-gris
  "MACV Saigon 1968" côté US, panneau terre brûlée "Front National de Libération"
  côté Vietcong, emblème en filigrane, devise machine à écrire.
- Liens bas-gauche MENU PRINCIPAL / DÉCONNEXION comme la référence.

### Weapon selector : le soldat "cherche sur lui"
La molette déplace la sélection immédiatement, mais l'arme n'arrive en main
qu'après `cfg.WeaponSelector.SwitchDelay` (0.45 s) — indicateur RECHERCHE…
dans le bloc ARME ACTUELLE.

### Caisse de ravitaillement (Soutien)
- SWEP `medal_supply_swep` (donné aux rôles Soutien) : clic droit = fantôme
  vert/rouge, clic gauche = pose. La caisse contient **50 de ravitaillement**
  (`cfg.Supply`), props configurable.
- Après la pose : **logo au-dessus du weapon selector** avec jauge de recharge ;
  la caisse est insélectionnable (grisée + %) tant que la recharge < 100%.

### Ingénieurs : construction alimentée par le ravitaillement
- L'**Emplacement Tool** (gred_emp_tool) est intégré à l'addon avec une config
  Vietnam (`lua/autorun/medal_emplacement_tool_config.lua`) : ingénieurs/sapeurs
  → MG et mortiers, artilleurs → canons ; construction à la pelle.
- **Poser un emplacement consomme `cfg.Supply.EmplacementCost` (25) de
  ravitaillement** pris dans les caisses de Soutien à moins de 15 m du chantier —
  sinon la pose est refusée. Les ingénieurs ont le tool + la pelle en loadout.

### Rappel spawn
Le parcours reste inchangé : pas de spawn tant qu'aucun rôle n'est validé
(`cfg.SpawnGate`), puis spawn/respawn sur le spawn du job DarkRP du rôle.

---

## v17 — Escouades HLL, Radioman, weapon selector molette, palette camo

### Palette camo
Les couleurs passent sur une base **vert olive / kaki** (`cfg.Colors` : `Olive`, `Accent`).
Le rouge est réservé aux erreurs et à la confirmation QUITTER. Les vidéos Dropbox
tournent désormais avec **opacité 1.0** et **volume 0.10**.

### HUD GMod entièrement retiré
`cfg.HideDefaultHUD` masque maintenant tous les éléments HL2 (santé, munitions,
dégâts, train, geiger, zoom…). Seul le chat reste actif (nécessaire au RP et à la radio).

### Weapon selector façon HLL (bas droite)
- Bloc **ARME ACTUELLE** permanent : grande silhouette + nom, comme le
  "CURRENT WEAPON / FELDSPATEN" de HLL.
- Pile de silhouettes au-dessus lors d'un changement d'arme, l'arme courante
  est surlignée par un bandeau clair translucide.
- **La molette change d'arme directement** (`cfg.WeaponSelector.ScrollSwitch`),
  les touches 1-9 sélectionnent le slot correspondant.

### Équipement rapide (touche B)
`cfg.QuickEquip` + bind `quick_equip` : un bandeau HLL liste les équipements
tenus (grenades, bandages, trousse médicale, outils… détectés par motifs de
class configurables) — clique pour équiper. Pensé pour les médecins & grenadiers.

### Menu E (interaction)
Vise un soldat proche et appuie sur **E** : menu contextuel HLL avec
**SE PRÉSENTER** (relations RP existantes), **INVITER DANS L'ESCOUADE**
(si tu es chef d'escouade) et l'accès au menu escouades.

### Escouades façon Hell Let Loose
- `cfg.Squads` : noms ABLE/BAKER/CHARLIE…, 6 membres max, le créateur est SL.
- Menu escouades (touche **K** ou `medal_squads`) : créer, rejoindre, quitter, exclure.
- Invitations avec panneau ACCEPTER/REFUSER.
- **HUD bas-gauche** : nom d'escouade + membres avec ★ pour le SL, comme HLL.
- Chat commandement : **/sl message** (commandant, officiers, chefs d'escouade).

### Radioman & radio de campagne
- Nouveau rôle **RADIO** (`radioman`) dans l'infanterie US et Vietcong, équipé du
  SWEP `medal_radio_swep`.
- **Pose de la radio** : clic droit = fantôme de placement (**vert** si valide,
  rouge sinon), **maintenir clic gauche** = jauge circulaire qui pose la radio à 100%.
- Props configurable : `cfg.Radio.PropModel`.
- **E sur la radio posée** : menu avec **animation de recherche de fréquence**
  (aiguille qui balaie la bande), puis choix : RÉSEAU RADIO (31.00 MHz) ou
  COMMANDEMENT (38.50 MHz). Le propriétaire peut remballer sa radio.
- Règles d'écoute :
  - `/radio` : tous les radiomen de la faction l'entendent **toujours** ;
  - `/sl` : canal commandement. Le radioman doit avoir **posé sa radio sur la
    fréquence COMMANDEMENT** pour l'entendre (et pour transmettre aux SL) ;
  - toute personne à **10 mètres** d'une radio posée entend ce qui passe sur sa
    fréquence (`cfg.Radio.HearRadiusMeters`).

### Création de personnage refaite (esprit Vietnam)
Fiche d'enrôlement façon **dossier militaire de 1968** : typographie machine à
écrire (Courier), en-tête MACV Saigon / Front de Libération, numéro de dossier,
coins de formulaire, lignes pointillées et **tampon incliné** CONFIDENTIEL / ENRÔLÉ.
Boutons SIGNER L'ENRÔLEMENT / ENREGISTRER LE DOSSIER en DA HLL.

---

## v16 — Refonte UI complète façon Hell Let Loose

Toute la couche visuelle des menus a été reprise pour coller à la DA Hell Let Loose du visuel de référence, **sans toucher au système de vidéos Dropbox** qui reste le fond de chaque écran :

- **Typographie HLL** : tous les titres, boutons, onglets et labels utilisent des majuscules condensées avec lettrage espacé (rendu caractère par caractère, compatible accents).
- **Boutons HLL unifiés** : panneau sombre translucide, liseré rouge à gauche qui s'épaissit au survol, filets fins haut/bas, texte qui glisse légèrement vers la droite avec un chevron `›` au survol. Plus aucun gros bouton brillant.
- **En-têtes d'écran HLL** : fil d'Ariane (`MEDAL VIETNAM // FACTION`), grand titre espacé, petit bloc rouge + filet fin sur toute la largeur. Version centrée pour les écrans factions et options.
- **Barres d'action basses HLL** : filet fin en bas d'écran, bouton RETOUR toujours en bas à gauche, action principale (DÉPLOYER…) toujours en bas à droite, hint de touche `ÉCHAP` affiché comme dans HLL.
- **Caserne façon écran de déploiement HLL** : colonnes assombries par dégradés latéraux, catégories de rôles en petites majuscules espacées avec filet, niveau de rôle en chiffres romains dans une case sombre bordée, bandeau de progression XP avec barre rouge sous le niveau général.
- **Menu principal fidèle à l'image de référence** : `BIENVENUE SUR` très espacé, gros titre `MEDAL VIETNAM`, filet rouge, boutons JOUER / OPTION / QUITTER à liseré rouge sur la zone d'ombre gauche, astuce en bas au centre, liens DISCORD / SITE WEB en bas à droite.
- Les vidéos Dropbox par écran (`cfg.RemoteMedia.ScreenVideos`) fonctionnent exactement comme avant : la vidéo reste derrière l'UI, chaque écran peut avoir la sienne, sinon la vidéo du menu principal est réutilisée.

---

Cette version applique la DA du dernier visuel demandé : menu principal sombre, grand dégradé noir à gauche, vidéo Dropbox derrière l’UI, boutons sobres type HLL/cinématique et astuce centrée en bas.

## Workflow inclus

1. **Menu principal** avec vidéo Dropbox `.webm` en fond.
2. La vidéo reste **derrière** toute l’UI.
3. Le côté gauche utilise un **dégradé d’ombre noir**, pas un bloc net ni une brume grise.
4. Clic sur **JOUER** → transition vers le choix de faction plein écran.
5. Choix faction avec équilibrage des camps.
6. Sélection/création de personnage.
7. Choix obligatoire du rôle et du loadout avant spawn.
8. Changement vers le **job DarkRP configuré dans le rôle**, puis spawn sur les spawns du job.

## DA du menu principal

Le layout principal se configure ici :

```lua
cfg.MainMenuStyle = {
    TitleX = 132,
    TitleY = 275,
    ServerLineY = 405,
    ButtonX = 132,
    ButtonY = 500,
    ButtonW = 395,
    ButtonH = 74,
    ButtonGap = 26,
    LinkY = 988,
}
```

Le texte du titre :

```lua
cfg.MainMenu = {
    Title = "MEDAL VIETNAM",
    Subtitle = "BIENVENUE SUR",
    ServerLine = "GARRY'S MOD - SERVEUR VIETNAM WAR RP",
}
```

## Dégradé d’ombre à gauche

Le nouveau rendu demandé est ici :

```lua
cfg.MainMenuLeftZone = {
    Enabled = true,
    Mode = "shadow",

    Width = 880,
    SolidWidth = 470,
    DarkAlpha = 248,
    FadeAlpha = 238,
    FadeWidth = 620,
    GradientPower = 2.15,
    TopVignetteAlpha = 78,
    BottomVignetteAlpha = 108,
}
```

`SolidWidth` règle la partie très noire à gauche. `FadeWidth` règle la longueur du fondu vers le centre. `GradientPower` règle la douceur du dégradé.

## Vidéo Dropbox du menu principal

Le lien Dropbox `.webm` reste configuré ici :

```lua
cfg.RemoteMedia.ScreenVideos.main_menu_background = {
    Enabled = true,
    URL = "https://www.dropbox.com/scl/fi/uwkm6t3htbdn28tl00z5b/California-Dreamin.webm?rlkey=z8pqdwouykd8vxlxd1akoq3bu&st=hk2u282r&dl=0",
    Volume = 0.35,
    Muted = false,
    Loop = true,
    Opacity = 0.72,
    ObjectFit = "cover",
    Filter = "brightness(.62) contrast(1.12) saturate(.92)",
}
```

L’addon convertit automatiquement le lien Dropbox en lien direct `dl.dropboxusercontent.com` avec `dl=1`.

## Vidéos par menu

Chaque écran peut avoir sa vidéo Dropbox :

```lua
cfg.RemoteMedia.ScreenVideos.faction_background
cfg.RemoteMedia.ScreenVideos.character_background
cfg.RemoteMedia.ScreenVideos.barracks_background
cfg.RemoteMedia.ScreenVideos.options_background
cfg.RemoteMedia.ScreenVideos.staff_background
```

Si une vidéo n’est pas configurée, l’addon réutilise la vidéo principale en fond.

## Conseils aléatoires

Les conseils s’affichent en bas au milieu avec retour automatique à la ligne :

```lua
cfg.Tips = {
    Enabled = true,
    Interval = 10,
    Width = 760,
    Prefix = "ASTUCE :",
    YOffset = 104,
    Texts = {
        "Crée ton personnage avant de choisir un rôle.",
        "Les chiffres romains indiquent ton niveau dans le rôle.",
    }
}
```

## Boutons Discord / site web

Materials inclus :

```txt
materials/medal/ui/discord.png
materials/medal/ui/globe.png
```

Config :

```lua
cfg.MainMenu.DiscordURL = "https://discord.gg/tonserveur"
cfg.MainMenu.WebsiteURL = "https://ton-site.fr"
```

## Menu Options plein écran

Le menu **OPTION** garde l’UI Medal et contient :

- **BINDS MEDAL** ;
- **BINDS GMOD** récupérés via `input.LookupBinding` ;
- **GRAPHIQUES** via convars client.

## Menu staff personnages

Commande client :

```txt
medal_staff_menu
```

Permet de modifier ou supprimer les personnages sauvegardés en SQLite.

## Relations RP / Inconnu / Présentation

Commande joueur :

```txt
/presenter
```

Règles :

- US ↔ Vietcong : inconnus tant qu’ils ne se sont pas présentés.
- Même escouade : tout le monde se connaît automatiquement.
- Officiers/commandants : bypass uniquement dans la même faction.
- Le bypass ne s’applique jamais entre US et Vietcong.

API serveur utile pour tes HUD / chat RP :

```lua
MedalBarracks.CharactersKnow(viewer, target)
MedalBarracks.GetDisplayNameForViewer(viewer, target)
```

## Rôle lié à un job DarkRP

Chaque rôle possède son job :

```lua
Role("fusilier", "FUSILIER", "TEAM_MEDAL_US_FUSILIER", "Fusilier US", 1, "✦", US_MODEL, {
    L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 150}, {"Pansement"})
})
```

Quand le joueur choisit ce rôle, il est envoyé dans le job DarkRP configuré, puis spawn sur les spawns du job.

## v14 - DA complète + corrections menu

Cette version applique la DA sombre/cinématique du visuel de référence sur l'ensemble de l'addon :

- gros dégradé noir à gauche sur le main menu, avec la vidéo Dropbox derrière l'UI ;
- boutons unifiés partout : main menu, options, faction, personnage, caserne, staff ;
- nouveaux materials UI inclus :
  - `materials/medal/ui/shadow_left_gradient.png`
  - `materials/medal/ui/button_hll_panel.png`
  - `materials/medal/ui/panel_hll_dark.png`
  - `materials/medal/ui/tip_panel.png`
- page faction plein écran : chaque faction occupe une moitié complète de l'écran ;
- menu personnage refait façon dossier de déploiement avant départ au front ;
- correction de l'erreur `RunConsoleCommand: Command is blocked! (fov_desired)` : les convars bloquées par GMod sont affichées mais non appliquées ;
- tant que le joueur n'a pas choisi un rôle, il reste hors déploiement : gelé/invisible/spectateur selon la config ;
- le spawn réel arrive seulement après validation d'un rôle/loadout.

### Config utile

Dans `lua/medal_barracks/sh_config.lua` :

```lua
cfg.MainMenuLeftZone = {
    Mode = "shadow",
    Width = 1040,
    SolidWidth = 520,
    DarkAlpha = 255,
    FadeAlpha = 246,
    FadeWidth = 820,
    GradientPower = 1.78,
}
```

Pour que les joueurs ne soient pas réellement déployés tant qu'ils sont dans le menu :

```lua
cfg.SpawnGate = {
    Enabled = true,
    HidePlayerWhileInMenu = true,
    SpectateWhileInMenu = true,
    StripWeaponsWhileInMenu = true,
    GodWhileInMenu = true,
    PreventDeathRespawnWithoutRole = true,
}
```

Pour la page faction plein écran :

```lua
cfg.FactionPage = {
    SplitFullscreen = true,
    UseCoverImages = true,
}
```

## v15 — Options GMod en lecture seule + weapon selector Medal

- Le menu OPTIONS ne modifie plus directement les binds GMod du joueur. Les binds GMod sont lus avec `input.LookupBinding()` et affichés avec l'UI Medal.
- Les binds Medal restent des binds propres à l'addon, sauvegardés côté client avec cookies.
- Si tu veux faire suivre un bind Medal à une touche GMod, configure `cfg.GModBindAdapter.Mappings` dans `lua/medal_barracks/sh_config.lua`.
- Correction de la police manquante `MedalBarracks_Title`.
- Le menu personnage est bien rendu au-dessus de la vidéo de fond.
- Le HUD GMod de base est masqué via `cfg.HideDefaultHUD`.
- Ajout d'un weapon selector custom en bas à droite, configurable dans `cfg.WeaponSelector`.

Exemple image d'arme :

```lua
cfg.WeaponSelector.WeaponIcons = {
    m9k_m16a4_acog = "medal/weapons/m16.png",
    arc9_bo1_m16 = "medal/weapons/m16.png",
    weapon_pistol = "medal/loadouts/pistol.png",
}
```

Place les images ici :

```txt
garrysmod/materials/medal/weapons/m16.png
```
