# Aku — la sorcière de Cotonou

Un rail shooter en 3D, fait avec **Godot 4.7**.
La nuit, une sorcière sur son balai file au-dessus d'une avenue de Cotonou et combat les esprits
qui surgissent du fond de la brume. La caméra est derrière elle.

## Lancer le jeu

```bash
godot-4 --path .        # jouer
godot-4 -e              # ouvrir dans l'éditeur
```

| Touche | Action |
|---|---|
| Flèches | se déplacer (haut, bas, gauche, droite) ; le balai avance tout seul |
| Espace (appui court) | lancer un sort ; il annule une boule d'esprit qu'il touche |
| Espace (maintenir 1 s puis relâcher) | sort chargé : 5 dégâts, traverse les esprits |
| P | changer de vue : 3D (derrière la sorcière) ou 2D (de côté, façon R-Type) |
| Entrée | commencer / rejouer |
| Échap | quitter |

Une manette marche aussi : stick gauche pour voler, A pour tirer, Start pour commencer.

## Organisation du code

Le découpage reprend celui de notre R-Type :

| Fichier | Rôle | Équivalent R-Type |
|---|---|---|
| `scripts/config.gd` | tous les réglages (vitesses, vies, cadences) | `GameConfig.hpp` |
| `scripts/patterns.gd` | trajectoires : `linear`, `sine`, `zigzag`, `spiral`, `hover` | `LinearPattern`, `SinePattern`, `HoverPattern` |
| `levels/*.json` | vagues d'esprits de chaque niveau | `assets/levels/*.json` |
| `scripts/game.gd` | états, niveaux, collisions, santé, score | `LevelSystem`, `CollisionSystem`, `HealthSystem` |
| `scripts/witch.gd` | la sorcière : vol, sorts, charge | `PlayerControlSystem`, `ShootingSystem` |
| `scripts/enemy.gd`, `spirit.gd`, `boss.gd` | les esprits et le boss | entités Bydos / boss |
| `scripts/city.gd` | l'avenue de Cotonou qui défile vers la caméra | `Starfield` |
| `scripts/hud.gd` | score, vies, jauge de charge, barre du boss | `HudWidgets` |

Tout est construit en code avec des formes simples : il n'y a pas encore de modèles 3D.

## Atterrir et courir

Quand la sorcière descend près du sol, elle **atterrit toute seule et se met à courir** à pied,
son balai sur l'épaule. Elle peut toujours tirer et bouger à gauche/droite (un peu moins vite
qu'en vol), mais elle ne peut plus monter ni descendre : elle rase le sol, hors de portée
des esprits qui volent haut. Pour redécoller, **appuie deux fois vite sur la flèche du haut**
(moins de 0,35 s entre les deux appuis). Un seul appui ne fait rien.
Les réglages sont dans `scripts/config.gd` (section « Atterrissage et course »).

## Bonus

Les esprits vaincus lâchent parfois un bonus (20 % pour un feu follet, 55 % pour un esprit rouge).
Il dérive vers la sorcière : vole dedans pour le ramasser (il est attiré quand tu t'en approches).
Le texte flottant au-dessus dit ce que c'est.

| Bonus | Effet | Cumulable |
|---|---|---|
| **Force** (rouge) | +1 dégât par sort, +2 pour le sort chargé | oui, jusqu'à +4 |
| **Boules** (orange) | +1 boule de feu par tir, en éventail | oui, jusqu'à +4 (5 boules) |
| **Vitesse** (bleu) | +15 % de vitesse de vol | oui, jusqu'à +4 |
| **Cadence** (vert) | +25 % de cadence de tir | oui, jusqu'à +4 |
| **Vie** (rose) | +1 vie (5 maximum, sinon +500 points) | — |
| **Bouclier** (violet) | invincible 6 secondes | non, il se relance |

Les bonus actifs s'affichent sous les vies. Un bonus déjà au maximum rapporte des points à la place.
Plus la sorcière est puissante, plus le boss a de vie (+30 % par niveau de bonus), pour que le combat reste un défi.
Tous les chiffres sont dans `scripts/config.gd` (chercher « Bonus lâchés par les esprits »).

## Vue 2D (touche P)

La caméra glisse sur le côté et le jeu devient un shoot'em up classique : les esprits arrivent de la
droite, **←/→ font avancer et reculer** la sorcière, ↑/↓ la montent et la descendent.
La profondeur n'existe plus : les collisions et la visée l'ignorent (un esprit placé à `x = 4`
reste touchable). Les trajectoires `sine` et `spiral` bougent en partie dans la profondeur,
elles paraissent donc plus calmes en 2D. On peut changer de vue à tout moment, même en plein combat.

## Ajouter une vague

Dans `levels/level1.json` :

```json
{ "time": 12.0, "type": "esprit_rouge", "count": 3, "x": 0.0, "y": 2.0, "pattern": "hover", "formation": "row" }
```

- `time` : seconde d'apparition depuis le début du niveau. Les esprits naissent au fond de l'avenue et mettent environ 6 s à arriver.
- `type` : `feu_follet`, `esprit_rouge` ou `boss`.
- `count` : nombre d'esprits.
- `x` : position gauche/droite, de `-9` à `9`. `y` : hauteur, de `-4` à `7`.
- `pattern` : `linear` (tout droit), `sine` (vague gauche-droite), `zigzag` (haut-bas), `spiral` (en cercle), `hover` (s'arrête devant la sorcière pour tirer, puis fonce).
- `formation` : `column` (l'un derrière l'autre, par défaut) ou `row` (côte à côte).

## Mode test

Le jeu peut jouer tout seul et enregistrer une capture d'écran :

```bash
godot-4 --path . -- --screenshot=$HOME/capture.png --level=2 --time=36 --delay=8
```

`--level` et `--time` démarrent directement à un endroit du jeu (ici, le boss).
`--view=2d` démarre en vue de côté. `--power=3` démarre avec tous les bonus cumulables au niveau 3.
`--drop-all` fait lâcher un bonus à chaque esprit vaincu. `--run` démarre avec la sorcière à pied.

Test automatique de l'atterrissage et du décollage (envoie de vraies pressions de touches) :

```bash
godot-4 --headless --path . --script res://tests/selftest_run.gd
```
Le Godot installé par snap ne peut pas écrire dans `/tmp` : enregistre la capture dans ton dossier personnel.
