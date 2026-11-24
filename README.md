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
| Flèches ou ZQSD | se déplacer (haut, bas, gauche, droite) ; le balai avance tout seul |
| Espace (appui court) | lancer un sort |
| Espace (maintenir 1 s puis relâcher) | sort chargé : 5 dégâts, traverse les esprits |
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
Le Godot installé par snap ne peut pas écrire dans `/tmp` : enregistre la capture dans ton dossier personnel.
