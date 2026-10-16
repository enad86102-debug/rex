"""Run with blender --background --python ... -- asset.glb.

Inspect import compatibility in Blender without altering the supplied asset.
This is an authoring intake tool, not a cinematic-character generator.
"""
import json
import sys
from pathlib import Path
import bpy

path = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(path))
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
report = {
    "path": str(path),
    "blender": bpy.app.version_string,
    "meshes": len(meshes),
    "triangles": sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes),
    "armatures": sum(o.type == "ARMATURE" for o in bpy.data.objects),
    "actions": [a.name for a in bpy.data.actions],
    "mesh_uv_layers": {o.name: len(o.data.uv_layers) for o in meshes},
    "release_approved": False,
}
print("REX_INTAKE_JSON=" + json.dumps(report))
