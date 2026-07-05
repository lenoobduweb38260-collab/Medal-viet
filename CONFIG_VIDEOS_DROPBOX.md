# Medal Vietnam — Configuration vidéos Dropbox par menu

Chaque écran peut avoir une vidéo Dropbox différente. Le `.webm` est conseillé pour GMod/Chromium.

Fichier principal :

```txt
lua/medal_barracks/sh_config.lua
```

## Vidéo du menu principal

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

## Vidéos des autres menus

```lua
cfg.RemoteMedia.ScreenVideos.faction_background = {
    Enabled = true,
    URL = "https://www.dropbox.com/scl/fi/TON_ID/faction.webm?rlkey=TON_RLKEY&dl=0",
    Volume = 0,
    Muted = true,
    Loop = true,
    Opacity = 0.72,
    ObjectFit = "cover",
}

cfg.RemoteMedia.ScreenVideos.character_background = {
    Enabled = true,
    URL = "https://www.dropbox.com/scl/fi/TON_ID/personnage.webm?rlkey=TON_RLKEY&dl=0",
    Volume = 0,
    Muted = true,
    Loop = true,
    Opacity = 0.72,
    ObjectFit = "cover",
}

cfg.RemoteMedia.ScreenVideos.barracks_background = {
    Enabled = true,
    URL = "https://www.dropbox.com/scl/fi/TON_ID/caserne.webm?rlkey=TON_RLKEY&dl=0",
    Volume = 0,
    Muted = true,
    Loop = true,
    Opacity = 0.72,
    ObjectFit = "cover",
}
```

## Crop / recadrage vidéo

Tu peux ajouter ceci dans n’importe quelle vidéo :

```lua
Crop = {
    X = 50,      -- 0 = gauche, 50 = centre, 100 = droite
    Y = 50,      -- 0 = haut, 50 = centre, 100 = bas
    Zoom = 1.15, -- agrandit la vidéo pour cadrer une zone précise
}
```

## Dégradé noir à gauche du main menu

La DA demandée utilise maintenant `Mode = "shadow"` :

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
}
```

Le mode `video` existe toujours si tu veux mettre une vidéo uniquement dans la zone gauche, mais le rendu par défaut est maintenant le grand dégradé sombre.

## Important Dropbox

- Mets plutôt du `.webm`.
- Garde un lien partagé Dropbox classique en `dl=0`.
- L’addon convertit automatiquement vers `dl.dropboxusercontent.com` avec `dl=1`.
- Les vidéos des menus secondaires sont muettes par défaut pour éviter plusieurs sons en même temps.
