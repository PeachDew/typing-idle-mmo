# AGENTS.md — Typing Idle MMO (Godot 4.6)

Typing-based idle MMO. Player types to earn aura, buys upgrades, earns passive income.

## Persona & Boundaries

- Expert GDScript/Godot 4.6 developer. Prefer composition over inheritance.
- Never use direct references between gameplay and UI/audio systems — use signals.
- Never allocate inside `_process` or `_physics_process` loops. Pre-allocate or reuse.
- Ask before making major architectural changes (new autoloads, schema changes).

## GDScript & Godot API

When unsure about Godot APIs, GDScript syntax, node types, or signal patterns, use available tools (context7, zread, etc.) to look up current documentation instead of guessing.

## Design Principles

### Separate concerns
- UI nodes display data and capture input. They don't own game state.
- Autoloads own global data and logic. Other scripts read from them.
- When a node needs to act on game state, it goes through the appropriate autoload — not directly modifying another node's internals.

### Data-driven over hardcoded
- Game content (upgrades, costs, effects) lives in data structures, not scattered `if`/`match` blocks.
- Adding new content = adding a data entry, not rewriting logic.
- The `UpgradeManager.Upgrade` pattern (inner class with properties + methods) is the template for new systems.

### Signals for communication (Observer Pattern)
- Use signals for all cross-node communication, never direct method chains.
- Signal flow: UI emits intent → logic owner validates and mutates state → owner emits changed signal → UI reads updated state.
- Avoid bidirectional dependencies. If A listens to B, B shouldn't also listen to A.
- This decoupling lets you add new listeners (e.g., audio, achievements, analytics) without touching the emitting system.

### One owner per state
- Each piece of game state has exactly one owner. Score in one place, upgrade levels in one place.
- Other nodes read that state; they don't cache their own copy.
- If multiple systems need to react to state changes, the owner emits a signal.

## Performance

- Avoid `new` allocations inside `_process`/`_physics_process`. Reuse objects or use pre-allocated arrays.
- Use object pooling for any node spawned repeatedly (projectiles, particles, floating text).
- Profile before optimizing. Use Godot's built-in profiler to identify real bottlenecks.

## Technical Debt Management

- Regular small refactors beat massive rewrites. Improve structure without changing behavior.
- Every new feature should include cleanup of nearby code (leave the code better than you found it).
- Track known issues as TODO comments with context: `# TODO(why): description`.
- Don't over-engineer for hypothetical futures (YAGNI). Build what's needed now, architect for easy extension later.

## Save System Guidelines

- Save data must be decoupled from scene nodes. A save manager autoload serializes state to JSON.
- Each system that owns persistent state provides its own serialization methods.
- Every save format includes a version number. Migration scripts handle format changes across updates.

## `.tscn` Files

Use `edit` (targeted replacement) for existing `.tscn` files — preserves UIDs, SubResource IDs, node structure. `write` is fine for new files. Spawning nodes in code (`Timer.new()`, `add_child()`) is valid for dynamic/runtime content.

## Structure

```
scenes/        .tscn + .gd pairs, colocated
autoload/      global singletons (UpgradeManager, future: ScoreManager, etc.)
```

## Current Systems

| System | Owner | Role |
|---|---|---|
| Upgrades | `autoload/upgrade_manager.gd` | Inner `Upgrade` class, `try_purchase()`, cost scaling |
| Aura (currency) | `scenes/main.gd` (for now) | Earned by typing, spent on upgrades |
| Pause menu | `scenes/pause_menu.gd` | Displays upgrades from UpgradeManager, emits purchase intent |
| Idle income | Timer in `scenes/main.gd` | 1s tick, reads `UpgradeManager.upgrades[1].level` |
