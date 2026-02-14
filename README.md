# Tower Defense

A tower defense game built in Godot 4.6, reusing the combat system from the [autobattler](../autobattler/) project. Game-jam-scoped: focused, minimal, playable.

## How to Play

1. Open the project in Godot 4.6 and run the main scene
2. Use the **build panel** at the bottom to select a building
3. **Left-click** a grid cell in the base zone (left side, with grid lines) to place it
4. **Right-click** or **Escape** to cancel placement
5. Buildings produce units automatically — units rally near the base and engage incoming enemies
6. Survive as many waves as possible. Game over when base HP reaches 0.

## Controls

| Input | Action |
|-------|--------|
| Left Click | Place building (in placement mode) |
| Right Click / Escape | Cancel placement |
| WASD | Move camera |
| Q / E | Rotate camera |
| Z / C | Camera up / down |
| Mouse Wheel | Zoom in / out |

## Buildings

### Production (spawn units periodically)

| Building | Cost | Unit | Interval |
|----------|------|------|----------|
| Barracks | 50g | Footman | 10s |
| Archery Range | 75g | Archer | 14s |
| Stable | 100g | Cavalry | 16s |
| Aviary | 120g | Flyer | 18s |

### Upgrades (global stat boosts, diminishing returns)

| Building | Cost | Effect |
|----------|------|--------|
| Armory | 80g | +20% damage |
| Fortification | 80g | +20% HP |
| Training Ground | 100g | +15% accuracy |
| War College | 120g | +10% attack speed |

### Economy & Population

| Building | Cost | Effect |
|----------|------|--------|
| Gold Mine | 60g | +5 gold/second |
| House | 40g | +5 population cap |

## Project Structure

```
tower-defense/
├── project.godot
├── scenes/
│   ├── main.tscn              Main scene
│   ├── projectile.tscn        Arrow projectile
│   └── units/
│       ├── footman.tscn
│       ├── cavalry.tscn
│       ├── archer.tscn
│       └── flyer.tscn
└── scripts/
    ├── main.gd                Battlefield setup, input handling
    ├── game_config.gd         All game parameters (autoload)
    ├── game_manager.gd        Gold, population, base HP (autoload)
    ├── wave_manager.gd        Wave timing and enemy spawning (autoload)
    ├── building_system.gd     Grid and building placement (autoload)
    ├── camera_controller.gd   Isometric camera controls
    ├── projectile.gd          Ballistic projectile physics
    ├── units/
    │   ├── base_unit.gd       Core unit AI (state machine)
    │   ├── archer_unit.gd     Ranged attacks, target prediction
    │   └── flyer_unit.gd      Aerial combat, altitude management
    └── ui/
        ├── hud.gd             Top bar (wave, gold, pop, base HP)
        ├── build_panel.gd     Building selection buttons
        └── game_over_screen.gd
```
