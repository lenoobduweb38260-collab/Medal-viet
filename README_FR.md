# Medal Barracks Menu Vietnam — v16 UI Hell Let Loose

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
