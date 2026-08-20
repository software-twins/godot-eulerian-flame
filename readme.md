# FluidSim — CPU-based Fluid Simulation Library

`FluidSim` is a library for numerical simulation of continuous media, written in C++23 and designed for CPU execution rather than GPU. The mathematical core is an Eulerian grid-based solver for incompressible fluid. Using the fractional step (projection) method on a Staggered Grid (MAC) guarantees mass conservation (divergence-free velocity field) and completely eliminates "checkerboard pressure" artifacts.

This approach makes it a potential candidate for real-time applications, such as embedded systems, where predictability and control over the computational budget are important.

This is currently an unconfirmed characteristic: execution time benchmarks on different grid sizes, varying hardware, and worst-case scenarios have not yet been conducted. The demo video shows visually smooth operation in a specific Godot scene.

The implementation as a GDExtension for the Godot Engine, presented in this repository, is an illustration of the library's capabilities: a working, visually verifiable example of its integration into a specific runtime environment, rather than an end in itself. The simulation core (the entire numerical method) is independent of Godot and can be connected to any other C++ project or embedded platform.

## Quick Start

Download the project from this repository, open it in Godot, and press Play — the scene from the demo video will launch. You can then modify the scene and script for your specific task, using the provided example as a starting point.

### What Happens in the Project

The scene consists of a `FluidSim` node (`fluidsim_main.gd` script), connected to a texture for outputting the result and a control panel:

- **`_ready()`** initializes the simulation grid (`init_simulation`), creates an image texture where the result is filled every frame, and places two initial obstacles in the flow path.
- **`_process()`** adds combustible material to the flame (`add_force` + `add_density`) every frame, simulates wind, and updates the texture from `get_density_bytes()`.
- **The Control Panel** (`%Panel`) contains two sliders linked to `substance_amount` (flame intensity) and `wind_force` (wind strength), and switches that enable and disable two obstacles on the fly via `set_obstacle`.

## Core Library Functions Used in the Script

### Add Matter (Passive Scalar)

```gdscript
add_density(cx, cy, amount, delta)
```
Injects a local concentration of a passive scalar (smoke, dye, flame marker) into the grid cell `(cx, cy)`. `amount` sets the emission intensity.

The density field is advected (transported) by the calculated fluid velocity field, allowing for flow visualization. To create a convection effect (when a flame or hot smoke rises), this method is applied synchronously with the injection of momentum via `add_force`.

### External Momentum Source (Wind, Draft)

```gdscript
add_force(cx, cy, fx, fy, delta)
```
Applies a vector force `(fx, fy)` to the velocity field in cell `(cx, cy)`.

This allows for modeling external influences (wind, drafts) or emulating thermal buoyancy (Archimedes' principle). For example, `add_force(12, 32, 0.0, -800.0, delta)` creates a strong updraft, dragging the density marker (fire) with it.

### Dynamic Obstacles (No-Slip Condition)

```gdscript
set_obstacle(x, y, true)   # places a solid wall in the cell
set_obstacle(x, y, false)  # removes the placed wall
```
Applies Dirichlet boundary conditions (No-Slip condition) to the cell. In such cells, the normal and tangential components of the flow velocity are strictly zeroed out — the flow physically correctly bypasses the obstacle without losing mass.

Obstacles can be placed and removed "on the fly" without recalculating the entire grid (as in the `fluidsim_main.gd` example, where obstacles are toggled via the UI).

A rectangular area is marked like this:

```gdscript
func add_obstacle_rect(pos: Vector2, size: Vector2, solid: bool):
    for y in range(pos.y, pos.y + size.y):
        for x in range(pos.x, pos.x + size.x):
            set_obstacle(x, y, solid)
```

## Complete List of Methods

| Method | Purpose |
|---|---|
| `init_simulation(nx, ny, dx, dy, viscosity, density)` | Initializes the grid. Called once in `_ready()`. |
| `add_force(cx, cy, fx, fy, dt)` | Adds force/wind at a point. |
| `add_density(cx, cy, amount, dt)` | Adds smoke/dye at a point. |
| `get_density_bytes()` | Returns the entire density field at once — to fill the texture. |
| `set_obstacle(x, y, solid)` | Places or removes an obstacle. |

### `init_simulation` Parameters

- `nx`, `ny` — grid size in cells: the larger it is, the more detailed, but more expensive in performance.
- `dx`, `dy` — size of one cell. Usually `1.0` is enough.
- `viscosity` — viscosity: the larger the value, the more "viscous" and slowly dissipating the flow is. Small values (`0.0001`) are suitable for light smoke/fire.
- `density` — density of the medium. Affects how strongly pressure pushes the flow.

## Function Reference (Signatures)

Below are all the methods registered via `_bind_methods()` and available from GDScript. Types are indicated in GDScript notation.

### `init_simulation(nx: int, ny: int, dx: float, dy: float, viscosity: float, density: float) -> void`
Creates and zeroes out the simulation grid: velocity, pressure, and density fields, obstacle array. Called once before the first simulation frame (usually in `_ready()`). A repeated call recreates the grid from scratch.

- `nx`, `ny` — width and height of the grid in cells.
- `dx`, `dy` — physical size of one cell along X and Y.
- `viscosity` — kinematic viscosity of the medium.
- `density` — base density of the medium.

### `add_force(cx: int, cy: int, fx: float, fy: float, dt: float) -> void`
Adds a momentum impulse to cell `(cx, cy)`.

- `cx`, `cy` — grid cell coordinates.
- `fx`, `fy` — force components along X and Y.
- `dt` — time step, usually `delta` from `_process` is passed.

### `add_density(cx: int, cy: int, amount: float, dt: float) -> void`
Adds density ("smoke"/"dye"/"fire") to cell `(cx, cy)`. The value saturates at `100.0`.

- `cx`, `cy` — grid cell coordinates.
- `amount` — intensity of the added density.
- `dt` — time step.

### `get_density_bytes() -> PackedByteArray`
Returns the entire density field at once as a byte array of length `nx * ny` (one byte per cell, values `0–255`). Values before conversion are limited to the `[0.0, 1.0]` range. Ready for direct writing to a `FORMAT_R8` `Image` via `Image.set_data()`.

- No arguments.
- Returns: `PackedByteArray` of size `nx * ny`.

### `set_obstacle(x: int, y: int, is_solid: bool) -> void`
Marks cell `(x, y)` as a solid obstacle (`true`) or removes the mark (`false`). Outside the grid boundaries, the call is ignored.

- `x`, `y` — cell coordinates.
- `is_solid` — `true` to place an obstacle, `false` to remove it.


`substance_amount` and `wind_force` in the example are linked to UI sliders, so the fire intensity and wind strength can be tweaked directly while the plugin is running.

## Tips

- Keep the grid small (tens, not hundreds of cells per axis): the simulation is currently quite demanding on performance, and the node's `scale` allows you to stretch a small grid over the entire screen without losing picture quality.
- At too high flow velocities (due to large applied force values), a violation of the **CFL condition (Courant–Friedrichs–Lewy)** is possible, leading to numerical instability (the simulation "blows up"). Try to balance the cell size `dx/dy`, the time step `delta`, and the power of external forces.
- The density/smoke gradually fades over time by itself — there is no need to manually extinguish it.
- Obstacles can be turned on and off on the fly (for example, by an in-game event) — this does not require grid reinitialization.

## License

Add the project license here (e.g., MIT).
