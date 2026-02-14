# Tower Defense - Game Design Document

## Context

Built in Godot 4.6, reusing the combat system from the autobattler project. The autobattler provides a working real-time auto-combat engine with 4 unit types (footman, cavalry, archer, flyer), ballistic projectile system, configurable stats, and team-based targeting AI -- all using 3D procedural box meshes. This is a game-jam-scoped project: focused, minimal, playable.

## Core Loop

```
Place Buildings -> Units Produce Over Time -> Wave Arrives ->
Auto-Combat -> Wave Defeated -> Earn Gold -> Place More Buildings -> Repeat
```

## Battlefield Layout

Lane-style, single map with two zones:

```
+---------------------+--------------------------------------+
|   PLAYER BASE       |           COMBAT ZONE                |
|   (Protected Zone)  |                                      |
|                     |                                      |
|  Grid-based         |   Player units rally here            |
|  building placement |               <- Enemy units approach|
|                     |                                      |
|                     |                          [SPAWN EDGE]|
|          [BASE HP]  |                                      |
+---------------------+--------------------------------------+
```

- **Player Base (left ~30%):** Protected grid zone where buildings are placed. Enemies cannot enter.
- **Combat Zone (right ~70%):** Open area where auto-combat happens. Player units rally at the zone boundary and engage approaching enemies.
- **Base Structure:** A structure at the left edge with HP. If enemies reach it, they deal damage. Game over when base HP = 0.

## Resource System

**Single resource: Gold**

- Starting gold: 150 (enough for 1-2 initial production buildings)
- Earned by: defeating waves (scaling with wave number)
- Spent on: placing buildings
- Passive income: Gold Mine buildings generate 5 gold per second

## Building Types

All buildings are placed on a grid in the protected base zone. Each occupies 1 grid cell (4x4 world units).

### Production Buildings

Spawn units periodically. Units auto-rally near the base zone boundary and engage enemies when they approach.

| Building | Cost | Produces | Interval |
|----------|------|----------|----------|
| Barracks | 50g | Footman | 10s |
| Archery Range | 75g | Archer | 14s |
| Stable | 100g | Cavalry | 16s |
| Aviary | 120g | Flyer | 18s |

- Multiple buildings of the same type = more units over time
- No resource cost per unit -- only time
- Production pauses when population cap is reached

### Upgrade Buildings

Global stat boosts with diminishing returns per stack (1st = 100%, 2nd = 75%, 3rd = 50%, 4th+ = 25%).

| Building | Cost | Effect |
|----------|------|--------|
| Armory | 80g | +20% damage (all units) |
| Fortification | 80g | +20% HP (all units) |
| Training Ground | 100g | +15% accuracy (archers) |
| War College | 120g | +10% attack speed (all units) |

### Economy Buildings

| Building | Cost | Effect |
|----------|------|--------|
| Gold Mine | 60g | Generates 5g per second |

### Population Buildings

| Building | Cost | Effect |
|----------|------|--------|
| House | 40g | +5 population cap |

**Population cap** limits total alive units. Default starting cap: 10. When cap is reached, production buildings pause until a unit dies.

## Player Units

Reused from the autobattler with identical combat AI:

| Unit | Role | Key Traits |
|------|------|------------|
| **Footman** | Tank/Melee | High HP (100), moderate damage (15), targets closest |
| **Cavalry** | Flanker | Fast (6 speed), high damage (25), targets farthest (backline) |
| **Archer** | Ranged DPS | Low HP (50), ballistic projectiles, aim deviation, prioritizes flyers |
| **Flyer** | Air Unit | Flies above melee, prioritizes air -> archers -> ground |

### Unit Behavior

- Player units spawn at the base zone boundary and rally there
- When enemies are detected, units move to engage
- When all enemies are dead (between waves), surviving units return to the rally point
- Units cannot leave the battlefield bounds

## Enemy Types

| Enemy | Description |
|-------|-------------|
| **Grunt** | Uses footman stats. Basic melee. |
| **Ranger** | Uses archer stats. Ranged attacker. |
| **Brute** | 200 HP, slow (2 speed), 30 damage. Mini-tank. |
| **Boss** | Scaled brute: 5x HP, 2x damage, 2x size. Every 5th wave. |

## Wave System

Waves arrive on a fixed timer regardless of player readiness.

| Parameter | Value |
|-----------|-------|
| Time between waves | 45s (first), scales down to 25s minimum |
| Wave scaling | +2 enemies per wave |
| Starting wave | 3 Grunts |
| Boss waves | Every 5th wave (5, 10, 15...) |
| Enemy composition | Grunts only -> Rangers (wave 3+) -> Brutes (wave 7+) |

### Wave Composition Examples

- **Wave 1:** 3 Grunts
- **Wave 3:** 4 Grunts + 2 Rangers
- **Wave 5:** 5 Grunts + 3 Rangers + 1 Boss
- **Wave 7:** 6 Grunts + 3 Rangers + 2 Brutes
- **Wave 10:** 8 Grunts + 4 Rangers + 3 Brutes + 1 Boss

### Rewards

- Base reward: 30g + (wave_number x 10g)
- Boss wave bonus: +50g extra

## Win/Lose Conditions

- **Lose:** Base HP reaches 0. Show final wave reached + stats.
- **Win:** No explicit win. Endless survival -- see how far you can get.
- **Base HP:** 100. Enemies that reach the base deal damage equal to their attack damage.

## UI Layout

```
+------------------------------------------------------+
| [Wave: 3]  [Next Wave: 15s]  [Gold: 230]  [Pop: 7/10] |  <- Top HUD
| [Base HP: ==================== 80/100]                  |
+------------------------------------------------------+
|                                                      |
|   GAME WORLD (3D viewport)                          |
|                                                      |
+------------------------------------------------------+
| [Barracks 50g] [Range 75g] [Stable 100g] [Aviary 120g] |  <- Build Bar
| [Armory 80g] [Fort 80g] [Training 100g] [College 120g] |
| [Gold Mine 60g] [House 40g]                          |
+------------------------------------------------------+
```

- Click building button to enter placement mode
- Click grid cell to place (green = valid, red = occupied)
- Right-click or Escape to cancel placement
- Buildings shown as colored boxes on the grid

## Camera

Isometric camera with WASD/QE/ZC controls and mouse wheel zoom. Default position shows the full map.

## Combat System (from Autobattler)

### State Machine

All units use a finite state machine: IDLE -> MOVING -> ATTACKING (+ MARCHING for enemies, RALLYING for player units).

### Targeting

- **Footman/Brute/Boss:** Target closest enemy. Cannot target airborne flyers.
- **Cavalry:** Target farthest (backline) enemy. Cannot target airborne flyers.
- **Archer:** Prioritizes flyers, then closest enemy in range. Ballistic projectiles with aim deviation.
- **Flyer:** Prioritizes enemy flyers, then archers, then other ground units. Lands to attack ground targets.

### Projectiles

- Ballistic trajectory with gravity (speed: 22, gravity: 10)
- Target movement prediction
- Friendly fire avoidance (archers check line of fire)
- Aim deviation for imperfect accuracy (~8 degrees, reduced by Training Ground)
- Hit stagger (0.5s stun on arrow hit)
- Arrows stick to hit units

### Friendly Avoidance

Units steer away from nearby friendlies to prevent clumping (2.0 unit radius for ground, 2.5 for flyers).

## Scope Boundaries

### In Scope

- 4 player unit types, 3 enemy types + boss
- 10 building types (4 production, 4 upgrade, 1 economy, 1 population)
- Grid placement, single resource, wave system, base HP
- Box-mesh art style, basic UI

### Out of Scope

- Tech trees or research
- Unit abilities or special attacks
- Multiple maps or levels
- Save/load system
- Sound effects or music
- Selling/moving buildings
- Rally points or unit control
- Multiplayer
- Story or narrative
