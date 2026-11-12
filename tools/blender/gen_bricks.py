"""Procedural brick mesh generator (Blender / bpy, headless).

Usage:
    python gen_bricks.py [output_dir]

Units: 1 Blender unit = 1 stud pitch (20 LDU). So a brick is 1.2 units tall,
a plate 0.4. The mesh origin (pivot) is the minimum corner of the part's
occupied cell box, which matches storing a part position as its lowest cell.
Blender is Z-up; FBX/OBJ are exported Y-up (Roblox / Unity convention).
"""
import math
import os
import sys

import bpy
import bmesh

PLATE_H = 8 / 20      # 0.4 stud pitch
BRICK_H = 24 / 20     # 1.2 stud pitch
STUD_D = 12 / 20      # stud diameter 0.6
STUD_H = 4 / 20       # stud height 0.2
INSET = 0.01          # body slightly smaller than its cell so neighbours show a seam
BEVEL = 0.03          # soft plastic edge
STUD_SEGMENTS = 12    # low poly: many copies will be on screen

# name: (width, depth, height in plates, has_studs)
PARTS = {}
for w, d in [(1, 1), (1, 2), (1, 3), (1, 4), (1, 6), (2, 2), (2, 3), (2, 4), (2, 6)]:
    PARTS[f"brick_{w}x{d}"] = (w, d, 3, True)
    PARTS[f"plate_{w}x{d}"] = (w, d, 1, True)
    PARTS[f"tile_{w}x{d}"] = (w, d, 1, False)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def build_part(name, w, d, h_plates, studs):
    h = h_plates * PLATE_H
    bm = bmesh.new()

    # body: box from (0,0,0) to (w,d,h), inset on the sides
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x = INSET + (v.co.x + 0.5) * (w - 2 * INSET)
        v.co.y = INSET + (v.co.y + 0.5) * (d - 2 * INSET)
        v.co.z = (v.co.z + 0.5) * h

    # soften all body edges (done before studs so studs stay crisp)
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=BEVEL, segments=1, affect="EDGES")

    if studs:
        for ix in range(w):
            for iy in range(d):
                res = bmesh.ops.create_cone(
                    bm,
                    cap_ends=True,
                    segments=STUD_SEGMENTS,
                    radius1=STUD_D / 2,
                    radius2=STUD_D / 2,
                    depth=STUD_H,
                )
                cx, cy = ix + 0.5, iy + 0.5
                bmesh.ops.translate(bm, verts=res["verts"], vec=(cx, cy, h + STUD_H / 2))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = False
    return obj


def export_part(obj, out_dir):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    fbx = os.path.join(out_dir, f"{obj.name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx,
        use_selection=True,
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        global_scale=1.0,
        mesh_smooth_type="FACE",
    )
    return fbx


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "meshes"
    os.makedirs(out_dir, exist_ok=True)
    clear_scene()
    for name, (w, d, hp, studs) in PARTS.items():
        obj = build_part(name, w, d, hp, studs)
        path = export_part(obj, out_dir)
        tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
        print(f"{name}: {tris} tris -> {path}")
        bpy.data.objects.remove(obj, do_unlink=True)


if __name__ == "__main__":
    main()
