class_name GameConfig
extends RefCounted
## Tous les réglages du jeu au même endroit (tailles, vitesses, cadences),
## comme GameConfig.hpp dans le R-Type. Les unités sont des mètres Godot.
##
## Repère : la sorcière vole dans le plan z = 0, vers le fond (-Z).
## La caméra est derrière elle (z positif). Les esprits arrivent du fond.

# Caméra (derrière la sorcière, elle la suit en partie).
const CAMERA_Z := 6.0
const CAMERA_HEIGHT := 2.0
const CAMERA_FOV := 70.0
const CAMERA_FOLLOW := 0.6              ## Part du déplacement de la sorcière que la caméra suit.

# Vue de côté (touche P), façon R-Type : la caméra passe sur le côté, les esprits
# arrivent de la droite (le -Z du jeu devient la droite de l'écran).
const SIDE_CAMERA := Vector3(28.0, 2.0, -7.0)
const SIDE_LOOK := Vector3(0.0, 0.0, -7.0)
const SIDE_FOV := 28.0
const SIDE_Z_RANGE := Vector2(-10.0, 3.0)   ## Zone de vol en profondeur (min, max) : l'écran en 2D.
const SIDE_VIEW_FAR_Z := -19.0              ## Au-delà (hors écran à droite), les esprits ne tirent pas.
const SIDE_SPAWN_Z := -45.0                 ## Apparition juste hors écran, pour que ça arrive vite.
const SIDE_HOVER_Z := -14.0                 ## Les esprits "hover" s'arrêtent ici en vue de côté.
const SIDE_BOSS_HOVER_Z := -15.0
const VIEW_BLEND_SPEED := 2.5               ## Vitesse du changement de vue (1 / seconde).

# Zone de vol de la sorcière, dans le plan z = 0.
const PLAY_MIN := Vector2(-9.0, -4.0)
const PLAY_MAX := Vector2(9.0, 5.5)
const GROUND_Y := -6.0

# Atterrissage et course : près du sol, la sorcière descend et court. Deux appuis rapides
# sur la flèche du haut la font décoller.
const LAND_TRIGGER_Y := -3.3            ## En vol, à cette hauteur ou moins, elle atterrit.
const RUN_HEIGHT := 0.95                ## Hauteur de son centre au-dessus du sol quand elle court (elle mesure 1,9 m).
const RUN_Y := GROUND_Y + RUN_HEIGHT
const LAND_SPEED := 9.0                 ## Vitesse de descente (mètres par seconde).
const TAKEOFF_SPEED := 12.0             ## Vitesse de montée au décollage.
const TAKEOFF_Y := -2.0                 ## Hauteur où le décollage rend la main au vol libre.
const RUN_SPEED_FACTOR := 0.85          ## À pied, elle va un peu moins vite qu'en vol.
const DOUBLE_TAP_TIME := 0.35           ## Délai max entre les deux appuis pour décoller.

# Saut (à pied) : un appui sur la flèche du haut. Assez haut pour passer par-dessus une voiture (1,6 m).
const JUMP_HEIGHT := 2.6                ## Hauteur du saut, en mètres.
const JUMP_TIME := 0.8                  ## Durée en l'air, en secondes.

# Obstacles : ils ne gênent que ce qui est près du sol.
const PLAYER_BODY_RADIUS := 0.4         ## Largeur de la sorcière pour les obstacles (elle mesure 1,9 m de haut).
const OBSTACLE_ZONE := 2.0              ## Poteaux et troncs ne comptent que sous cette hauteur : en vol, on passe au-dessus.

# Vitesse de vol : la ville défile vers la caméra.
const SCROLL_SPEED := 18.0

# Sorcière.
const PLAYER_START := Vector3(0.0, 0.5, 0.0)
const PLAYER_SPEED := 10.0
const PLAYER_RADIUS := 0.6
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

# Bonus lâchés par les esprits. Force, boules, vitesse et cadence se cumulent jusqu'à MAX_POWER.
const MAX_POWER := 4                    ## Niveau maximum de chaque bonus cumulable.
const MAX_LIVES := 5
const BONUS_DROP_SPEED := 11.0          ## Les bonus dérivent vers la sorcière (+Z).
const BONUS_PICKUP_RADIUS := 1.4        ## Distance de ramassage (en plus du rayon de la sorcière).
const BONUS_MAGNET_RANGE := 7.0         ## Près de la sorcière, un bonus est attiré vers elle.
const BONUS_MAGNET_SPEED := 16.0
const SHIELD_TIME := 6.0                ## Secondes d'invincibilité du bouclier.
const SPEED_PER_LEVEL := 0.15           ## +15 % de vitesse de vol par niveau.
const CADENCE_PER_LEVEL := 0.25         ## +25 % de cadence de tir par niveau.
const SHOT_SPREAD_ANGLE := 0.07         ## Écart (radians) entre deux boules de l'éventail.
const SHOT_SPREAD_OFFSET := 0.45        ## Écart (mètres) entre deux boules au départ.
const BOSS_POWER_SCALE := 0.3           ## Le boss gagne 30 % de vie par niveau de bonus de la sorcière.

# Esprits.
const SPIRIT_SPEED := 22.0             ## Vitesse d'approche vers la caméra.
const SPIRIT_RADIUS := 1.5
const SINE_AMPLITUDE := 4.0             ## Largeur de la vague.
const SINE_FREQUENCY := 0.4             ## Vagues par seconde.
const ZIGZAG_AMPLITUDE := 3.0
const SPIRAL_RADIUS := 3.0
const HOVER_Z := -32.0                  ## Les esprits "hover" s'arrêtent à cette distance…
const HOVER_TIME := 5.0                 ## …pendant ce temps, puis foncent.
const FIRE_ZONE := Vector2(-95.0, -14.0) ## Les esprits ne tirent qu'entre ces profondeurs.
const ENEMY_SHOT_SPEED := 30.0
const ENEMY_SHOT_RADIUS := 0.45
const SHOT_CANCEL_MARGIN := 0.7         ## Marge pour qu'un sort annule facilement une boule d'esprit.

# Boss : un seul, lancé par la dernière vague du dernier niveau.
const BOSS_NAME := "L'Esprit du Lac Nokoué"
const BOSS_HEALTH := 60
const BOSS_SCORE := 2000
const BOSS_SCALE := 3.0
const BOSS_HOVER_Z := -26.0
const BOSS_ENTER_SPEED := 25.0

# Apparition et disparition des entités.
const SPAWN_Z := -130.0
const WAVE_SPACING := 9.0               ## Écart entre les esprits d'une colonne (en profondeur).
const ROW_SPACING := 3.5                ## Écart entre les esprits d'une ligne (côte à côte).
const DESPAWN_Z := 14.0                 ## Derrière la caméra : l'entité disparaît.

# Campagne : fichiers de niveaux, dans l'ordre.
const LEVELS := ["res://levels/level1.json", "res://levels/level2.json"]
