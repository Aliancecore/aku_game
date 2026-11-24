class_name GameConfig
extends RefCounted
## Tous les réglages du jeu au même endroit (tailles, vitesses, cadences),
## comme GameConfig.hpp dans le R-Type. Les unités sont des mètres Godot.

# Caméra : vue de côté, le jeu se joue dans le plan z = 0.
const CAMERA_Z := 20.0
const CAMERA_FOV := 60.0

# Zone de vol de la sorcière (le sol de la ville est à GROUND_Y).
const PLAY_MIN := Vector2(-19.0, -8.0)
const PLAY_MAX := Vector2(19.0, 10.5)
const GROUND_Y := -9.5

# Défilement de la ville (mètres par seconde, au niveau du plan de jeu).
const SCROLL_SPEED := 4.0

# Sorcière.
const PLAYER_START := Vector3(-14.0, 0.0, 0.0)
const PLAYER_SPEED := 12.0
const PLAYER_RADIUS := 0.8
const PLAYER_LIVES := 3
const PLAYER_INVINCIBLE_TIME := 2.0     ## Secondes d'invincibilité après un coup.
const PLAYER_FIRE_COOLDOWN := 0.2       ## Secondes entre deux sorts.
const CHARGE_TIME := 1.0                ## Secondes à maintenir pour un sort chargé.

# Sorts de la sorcière.
const SHOT_SPEED := 32.0
const SHOT_RADIUS := 0.25
const CHARGED_SHOT_SPEED := 22.0
const CHARGED_SHOT_RADIUS := 1.0
const CHARGED_SHOT_DAMAGE := 5          ## Traverse les esprits.

# Esprits.
const SPIRIT_SPEED := 6.0
const SPIRIT_RADIUS := 0.9
const SINE_AMPLITUDE := 2.5             ## Hauteur de la vague.
const SINE_FREQUENCY := 0.5             ## Vagues par seconde.
const ZIGZAG_AMPLITUDE := 3.0
const ENEMY_SHOT_SPEED := 11.0
const ENEMY_SHOT_RADIUS := 0.3

# Boss : un seul, lancé par la dernière vague du dernier niveau.
const BOSS_NAME := "L'Esprit du Lac Nokoué"
const BOSS_HEALTH := 40
const BOSS_SCORE := 2000
const BOSS_RADIUS := 3.0
const BOSS_ENTER_SPEED := 4.0
const BOSS_HOVER_X := 12.0

# Apparition et disparition des entités.
const SPAWN_X := 23.0
const WAVE_SPACING := 2.6               ## Écart entre les esprits d'une même vague.
const OFFSCREEN_MARGIN := 6.0

# Campagne : fichiers de niveaux, dans l'ordre.
const LEVELS := ["res://levels/level1.json", "res://levels/level2.json"]
