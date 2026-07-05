# Config explicite — rôles, armes, images, icônes et XP

Fichier à modifier :

```txt
lua/medal_barracks/sh_config.lua
```

## 1. Structure d'un rôle

```lua
Role("fusilier", "FUSILIER", "TEAM_MEDAL_US_FUSILIER", "Fusilier US", 1, "✦", US_MODEL, {
    -- loadouts ici
}, {
    iconMaterial = "medal/roles/fusilier.png"
})
```

| Élément | À quoi ça sert |
|---|---|
| `"fusilier"` | ID unique du rôle. Utilisé pour XP, DB et icône. |
| `"FUSILIER"` | Nom affiché dans l'UI. |
| `"TEAM_MEDAL_US_FUSILIER"` | Constante du job DarkRP. |
| `"Fusilier US"` | Nom fallback du job si la constante n'existe pas. |
| `1` | Niveau général requis pour accéder au rôle. |
| `"✦"` | Symbole texte si tu ne mets pas d'icône material. |
| `US_MODEL` | Model joueur appliqué. |
| `{ L(...), L(...) }` | Liste des loadouts du rôle. |
| `{ iconMaterial = ... }` | Options du rôle. |

## 2. Structure d'un loadout

```lua
L("standard", "MODÈLE STANDARD", 1,
    {"weapon_smg1", "weapon_pistol"},
    {SMG1 = 180, Pistol = 45},
    {"Radio", "Pansement", "Jumelles"},
    {
        image = "medal/loadouts/rifle.png",
        previewImage = "medal/loadouts/rifle_big.png",
        armor = 25,
        health = 100,
    }
)
```

| Élément | À quoi ça sert |
|---|---|
| `"standard"` | ID unique du loadout. |
| `"MODÈLE STANDARD"` | Nom affiché. |
| `1` | Niveau de rôle requis. |
| `{ "weapon_smg1" }` | Codes/classes des armes. |
| `{ SMG1 = 180 }` | Munitions données. |
| `{ "Radio" }` | Équipements affichés dans l'UI. |
| `image` | Image de la ligne loadout. |
| `previewImage` | Grande image dans le panneau équipement. |
| `preview = {type="model", model="..."}` | Aperçu en modèle 3D au lieu d'une image. |

## 3. Trouver le code d'une arme

En jeu, prends l'arme en main puis lance :

```txt
lua_run_cl print(LocalPlayer():GetActiveWeapon():GetClass())
```

Le résultat est le code à mettre dans la table `weapons` du loadout.

## 4. Images et chemins

Les chemins commencent toujours depuis `garrysmod/materials/`.

Exemple fichier :

```txt
garrysmod/materials/medal/loadouts/m16.png
```

Config :

```lua
image = "medal/loadouts/m16.png"
```

## 5. Icônes de rôles

Méthode globale :

```lua
cfg.RoleIconMaterials = {
    fusilier = "medal/roles/fusilier.png",
    medic = "medal/roles/medic.png",
}
```

Méthode par rôle :

```lua
Role("fusilier", "FUSILIER", "TEAM_MEDAL_US_FUSILIER", "Fusilier US", 1, "✦", US_MODEL, {
    L(...)
}, {
    iconMaterial = "medal/roles/fusilier.png"
})
```

## 6. XP générale automatique

```lua
cfg.XP.General = {
    Enabled = true,
    Interval = 300,
    Amount = 25,
    RequireRoleSelected = true,
    MaxLevel = 100,
    BaseNextXP = 350,
    Growth = 1.16,
    Notify = true,
}
```

`Interval = 300` signifie que l'XP est donnée toutes les 5 minutes.

## 7. XP de rôle par kill

```lua
cfg.XP.Role = {
    Enabled = true,
    KillXP = 4,
    MaxLevel = 8,
    BaseNextXP = 60,
    Growth = 1.35,
    Notify = true,
    IgnoreTeamKills = true,
}
```

À chaque kill, le joueur gagne l'XP sur son rôle sélectionné actuellement.

## 8. Commandes admin

```txt
medal_xp_give <joueur> general <montant>
medal_xp_give <joueur> role <montant> [americans|vietcong] [role_id]
medal_xp_reset <joueur>
```

Exemples :

```txt
medal_xp_give Shadow general 200
medal_xp_give Shadow role 25 americans fusilier
medal_xp_reset Shadow
```
