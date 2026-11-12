# cikcik – Roblox project

Brick-building / selling tycoon. This folder is the Roblox side of the repo
(managed with [Rojo](https://rojo.space)).

## Layout

```
roblox/
  default.project.json     Rojo project
  src/shared/              ReplicatedStorage.Shared
    Config.luau            units, scale, platform/limits
    PartDefs.luau          part table (matches tools/blender meshes)
    OccupancyGrid.luau     cell table: collision, support, save/load
    History.luau           undo/redo command stack
  src/server/              ServerScriptService.Server
  src/client/              StarterPlayerScripts.Client
  tests/run.luau           plain-Luau tests for the pure modules
```

## Core ideas

- Models are a list of `{part, rot, x, y, z, color}` in integer cells
  (x, y = studs, z = plates). Roblox units appear only at render time via `Config.SCALE`.
- `OccupancyGrid` is the source of truth. The server validates every placement with it.
- Brand-neutral naming: no "LEGO" in names, art or descriptions.

## Run

```bash
rojo serve roblox/default.project.json   # then connect from Studio
luau roblox/tests/run.luau               # logic tests (needs the Luau CLI)
```

Meshes: `python tools/blender/gen_bricks.py <out_dir>` (needs `pip install bpy`).
