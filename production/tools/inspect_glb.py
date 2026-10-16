#!/usr/bin/env python3
"""Structural GLB intake report. Passing structure never implies art approval.

No models are generated, promoted, modified, or copied into the mobile bundle.
"""
import argparse
import json
import struct
from pathlib import Path


def inspect(path: Path) -> dict:
    if path.is_symlink() or not path.is_file() or path.stat().st_size > 64 * 1024 * 1024:
        raise ValueError("expected a regular GLB no larger than 64 MiB")
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("truncated GLB")
    magic, version, length = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError("invalid GLB header")
    chunks = []
    offset = 12
    while offset < length:
        if offset + 8 > length:
            raise ValueError("truncated chunk header")
        size, kind = struct.unpack_from("<II", data, offset)
        offset += 8
        if size % 4 or offset + size > length:
            raise ValueError("invalid chunk length")
        chunks.append((kind, data[offset:offset + size]))
        offset += size
    if not chunks or chunks[0][0] != 0x4E4F534A:
        raise ValueError("first chunk must contain JSON")
    gltf = json.loads(chunks[0][1])
    if not isinstance(gltf, dict):
        raise ValueError("glTF JSON must be an object")
    if gltf.get("asset", {}).get("version") != "2.0":
        raise ValueError("unsupported glTF version")
    primitives = [p for m in gltf.get("meshes", []) for p in m.get("primitives", [])]
    skins = gltf.get("skins", [])
    clips = [a.get("name", "UNNAMED") for a in gltf.get("animations", [])]
    external = [x["uri"] for k in ("buffers", "images") for x in gltf.get(k, [])
                if "uri" in x and not x["uri"].startswith("data:")]
    return {
        "path": str(path), "bytes": length,
        "meshes": len(gltf.get("meshes", [])),
        "materials": len(gltf.get("materials", [])),
        "skins": len(skins), "joints": sum(len(s.get("joints", [])) for s in skins),
        "animation_clips": clips,
        "all_primitives_have_uv": bool(primitives) and all("TEXCOORD_0" in p.get("attributes", {}) for p in primitives),
        "all_primitives_have_normals": bool(primitives) and all("NORMAL" in p.get("attributes", {}) for p in primitives),
        "skinned_primitives": sum("JOINTS_0" in p.get("attributes", {}) and "WEIGHTS_0" in p.get("attributes", {}) for p in primitives),
        "external_dependencies": external,
        "guide_only": "GUIDE_ONLY" in path.name,
        "release_approved": False,
        "approval_note": "Requires provenance, editable source, visual and device review; structural inspection alone cannot approve release.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", type=Path, nargs="+")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    reports = []
    for path in args.paths:
        try:
            reports.append(inspect(path))
        except (ValueError, OSError, KeyError, TypeError) as exc:
            reports.append({"path": str(path), "error": str(exc), "release_approved": False})
    text = json.dumps(reports, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 1 if any("error" in r for r in reports) else 0


if __name__ == "__main__":
    raise SystemExit(main())
