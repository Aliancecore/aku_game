class_name GameConfig
extends RefCounted
## Tous les réglages du jeu au même endroit (tailles, vitesses, cadences),
## comme GameConfig.hpp dans le R-Type. Les unités sont des mètres Godot.
##
## Repère : la sorcière vole dans le plan z = 0, vers le fond (-Z).
## La caméra est derrière elle (z positif). Les esprits arrivent du fond.

# Caméra (derrière la sorcière, elle la suit en partie).
const CAMERA_Z := 11.5
const CAMERA_HEIGHT := 3.4
const CAMERA_FOV := 70.0
const CAMERA_FOLLOW := 0.6              ## Part du déplacement de la sorcière que la caméra suit.

# Zone de vol de la sorcière, dans le plan z = 0.
const PLAY_MIN := Vector2(-9.0, -4.0)
const PLAY_MAX := Vector2(9.0, 7.0)
const GROUND_Y := -6.0

# Vitesse de vol : la ville défile vers la caméra.
const SCROLL_SPEED := 18.0

# Sorcière.
const PLAYER_START := Vector3(0.0, 0.5, 0.0)
const PLAYER_SPEED := 10.0
const PLAYER_RADIUS := 0.8
const PLAYER_LIVES := 3
const PLAYER_INVINCIBLE_TIME := 2.0     ## Secondes d'invincibilité après un coup.
const PLAYER_FIRE_COOLDOWN := 0.18      ## Secondes entre deux sorts.
const CHARGE_TIME := 1.0                ## Secondes à maintenir pour un sort chargé.
const RETICLE_DISTANCE := 30.0          ## Distance du viseur devant la sorcière.

# Sorts de la sorcière (ils partent vers le fond).
const SHOT_SPEED := 80.0
const SHOT_RADIUS := 0.35
const SHOT_RANGE := 170.0
const CHARGED_SHOT_SPEED := 55.0
const CHARGED_SHOT_RADIUS := 1.4
const CHARGED_SHOT_DAMAGE := 5          ## Traverse les esprits.

# Esprits.
const SPIRIT_SPEED := 22.0              ## Vitesse d'approche vers la caméra.
const SPIRIT_RADIUS := 1.2
const SINE_AMPLITUDE := 4.0             ## Largeur de la vague.
const SINE_FREQUENCY := 0.4             ## Vagues par seconde.
const ZIGZAG_AMPLITUDE := 3.0
const SPIRAL_RADIUS := 3.0
const HOVER_Z := -32.0                  ## Les esprits "hover" s'arrêtent à cette distance…
const HOVER_TIME := 5.0                 ## …pendant ce temps, puis foncent.
const FIRE_ZONE := Vector2(-95.0, -14.0) ## Les esprits ne tirent qu'entre ces profondeurs.
const ENEMY_SHOT_SPEED := 30.0
const ENEMY_SHOT_RADIUS := 0.45

# Boss : un seul, lancé par la dernière vague du dernier niveau.
const BOSS_NAME := "L'Esprit du Lac Nokoué"
const BOSS_HEALTH := 60
const BOSS_SCORE := 2000
const BOSS_SCALE := 2.2
const BOSS_HOVER_Z := -40.0
const BOSS_ENTER_SPEED := 25.0

# Apparition et disparition des entités.
const SPAWN_Z := -130.0
const WAVE_SPACING := 9.0               ## Écart entre les esprits d'une colonne (en profondeur).
const ROW_SPACING := 3.5                ## Écart entre les esprits d'une ligne (côte à côte).
const DESPAWN_Z := 14.0                 ## Derrière la caméra : l'entité disparaît.

# Campagne : fichiers de niveaux, dans l'ordre.
const LEVELS := ["res://levels/level1.json", "res://levels/level2.json"]
