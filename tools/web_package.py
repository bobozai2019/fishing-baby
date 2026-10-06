"""Verify the custom Godot template and package a Web export with Brotli."""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import shutil
from pathlib import Path


BUDGET_BYTES = 25 * 1024 * 1024
COMPRESS_SUFFIXES = {".html", ".js", ".json", ".pck", ".wasm"}
CONTENT_TYPES = {
    ".js": "application/javascript",
    ".pck": "application/octet-stream",
    ".wasm": "application/wasm",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_template(template: Path, provenance_path: Path, profile: Path) -> None:
    provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
    required = {
        "godot_version",
        "source_commit",
        "source_dirty",
        "emscripten_version",
        "scons_version",
        "build_profile_sha256",
        "scons_args",
        "template_sha256",
        "created_at",
    }
    missing = sorted(required - provenance.keys())
    if missing:
        raise SystemExit(f"provenance is missing fields: {', '.join(missing)}")
    if provenance["godot_version"] != "4.7.1.stable.official.a13da4feb":
        raise SystemExit(f"unexpected Godot version: {provenance['godot_version']}")
    if provenance["source_commit"] != "a13da4feb8d8aefc283c3763d33a2f170a18d541":
        raise SystemExit(f"unexpected source commit: {provenance['source_commit']}")
    if provenance["source_dirty"] is not False:
        raise SystemExit("custom template provenance reports a dirty source tree")
    actual_template_hash = sha256(template)
    if actual_template_hash != provenance["template_sha256"]:
        raise SystemExit(
            f"template hash mismatch: expected {provenance['template_sha256']}, "
            f"got {actual_template_hash}"
        )
    actual_profile_hash = sha256(profile)
    if actual_profile_hash != provenance["build_profile_sha256"]:
        raise SystemExit(
            f"build profile hash mismatch: expected {provenance['build_profile_sha256']}, "
            f"got {actual_profile_hash}"
        )
    print(f"[package] Verified custom template sha256={actual_template_hash}")


def package(directory: Path, template_kind: str, use_brotli: bool) -> None:
    if use_brotli:
        import brotli

    raw_paths = sorted(
        path
        for path in directory.rglob("*")
        if path.is_file()
        and path.name != "size-manifest.json"
        and path.suffix != ".br"
    )
    if not raw_paths:
        raise SystemExit(f"no Web export files found under {directory}")

    files = []
    payload_digest = hashlib.sha256()
    raw_total = 0
    transfer_total = 0
    for path in raw_paths:
        relative = path.relative_to(directory).as_posix()
        raw = path.read_bytes()
        raw_hash = hashlib.sha256(raw).hexdigest()
        raw_total += len(raw)
        payload_digest.update(relative.encode("utf-8"))
        payload_digest.update(bytes.fromhex(raw_hash))

        brotli_path = None
        brotli_bytes = None
        if use_brotli and path.suffix.lower() in COMPRESS_SUFFIXES:
            compressed = brotli.compress(raw, quality=11)
            if len(compressed) < len(raw):
                compressed_path = path.with_name(path.name + ".br")
                compressed_path.write_bytes(compressed)
                brotli_path = compressed_path.relative_to(directory).as_posix()
                brotli_bytes = len(compressed)

        transfer_total += brotli_bytes if brotli_bytes is not None else len(raw)
        files.append(
            {
                "path": relative,
                "raw_bytes": len(raw),
                "brotli_path": brotli_path,
                "brotli_bytes": brotli_bytes,
                "sha256": raw_hash,
            }
        )

    upload_total = sum(
        path.stat().st_size
        for path in directory.rglob("*")
        if path.is_file() and path.name != "size-manifest.json"
    )
    build_id = f"{template_kind}-{payload_digest.hexdigest()[:16]}"
    manifest = {
        "build_id": build_id,
        "template_kind": template_kind,
        "delivery_layout": "dual_representation" if use_brotli else "raw_only",
        "brotli_quality": 11 if use_brotli else None,
        "files": files,
        "raw_total_bytes": raw_total,
        "upload_artifact_bytes": upload_total,
        "brotli_transfer_bytes": transfer_total,
        "budget_bytes": BUDGET_BYTES,
        "budget_metric": "transfer",
        "budget_passed": transfer_total < BUDGET_BYTES,
    }
    manifest_path = directory / "size-manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"[package] raw={raw_total} upload={upload_total} "
        f"transfer={transfer_total} budget_passed={manifest['budget_passed']}"
    )
    if not manifest["budget_passed"]:
        raise SystemExit("Brotli transfer budget exceeded")


def publish_brotli(source: Path, destination: Path) -> None:
    source = source.resolve()
    destination = destination.resolve()
    if source == destination:
        raise SystemExit("source and destination must be different directories")
    manifest_path = source / "size-manifest.json"
    if not manifest_path.is_file():
        raise SystemExit(f"size manifest not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("delivery_layout") != "dual_representation":
        raise SystemExit("Brotli publishing requires a dual-representation build")
    if destination.exists() and any(destination.iterdir()):
        raise SystemExit(f"publish destination is not empty: {destination}")
    destination.mkdir(parents=True, exist_ok=True)

    deployed_files = []
    payload_bytes = 0
    for item in manifest["files"]:
        request_path = item["path"]
        stored_path = item["brotli_path"] or request_path
        source_path = source / stored_path
        target_path = destination / stored_path
        if not source_path.is_file():
            raise SystemExit(f"publish source file not found: {source_path}")
        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, target_path)
        size = target_path.stat().st_size
        payload_bytes += size
        suffix = Path(request_path).suffix.lower()
        content_type = CONTENT_TYPES.get(suffix) or mimetypes.guess_type(request_path)[0]
        deployed_files.append(
            {
                "request_path": request_path,
                "stored_path": stored_path,
                "content_encoding": "br" if item["brotli_path"] else None,
                "content_type": content_type or "application/octet-stream",
                "bytes": size,
                "sha256": sha256(target_path),
            }
        )

    deploy_manifest = {
        "build_id": manifest["build_id"],
        "layout": "brotli_only",
        "required_request_header": "Accept-Encoding: br",
        "required_response_headers": {
            "Cross-Origin-Opener-Policy": "same-origin",
            "Cross-Origin-Embedder-Policy": "require-corp",
            "Cross-Origin-Resource-Policy": "cross-origin",
        },
        "payload_bytes": payload_bytes,
        "files": deployed_files,
    }
    (destination / "deployment-manifest.json").write_text(
        json.dumps(deploy_manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"[package] Brotli-only release: {destination} "
        f"payload={payload_bytes} files={len(deployed_files)}"
    )


def finalize_split(source: Path, destination: Path) -> None:
    source = source.resolve()
    destination = destination.resolve()
    manifest_path = source / "size-manifest.json"
    deploy_manifest_path = destination / "deployment-manifest.json"
    if not manifest_path.is_file() or not deploy_manifest_path.is_file():
        raise SystemExit("split finalization requires both build manifests")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    deploy_manifest = json.loads(deploy_manifest_path.read_text(encoding="utf-8"))
    if manifest.get("delivery_layout") != "dual_representation":
        raise SystemExit("split finalization requires a dual-representation source")
    if manifest["build_id"] != deploy_manifest.get("build_id"):
        raise SystemExit("source and Brotli release build IDs do not match")

    for item in manifest["files"]:
        relative_brotli = item["brotli_path"]
        if not relative_brotli:
            continue
        brotli_path = (source / relative_brotli).resolve()
        if not brotli_path.is_relative_to(source):
            raise SystemExit(f"unsafe Brotli path in manifest: {relative_brotli}")
        if not brotli_path.is_file():
            raise SystemExit(f"Brotli source file not found: {brotli_path}")
        brotli_path.unlink()
        item["brotli_path"] = f"../{destination.name}/{relative_brotli}"

    manifest["delivery_layout"] = "split_directories"
    manifest["brotli_publish_directory"] = f"../{destination.name}"
    manifest["upload_artifact_bytes"] = sum(
        path.stat().st_size
        for path in source.rglob("*")
        if path.is_file() and path.name != "size-manifest.json"
    )
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"[package] Split release finalized: raw={source} brotli={destination}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify-template")
    verify.add_argument("--template", type=Path, required=True)
    verify.add_argument("--provenance", type=Path, required=True)
    verify.add_argument("--profile", type=Path, required=True)

    build = subparsers.add_parser("package")
    build.add_argument("--directory", type=Path, required=True)
    build.add_argument(
        "--template-kind", choices=("stock", "custom_release", "custom_e2e"), required=True
    )
    build.add_argument("--brotli", action="store_true")
    publish = subparsers.add_parser("publish-br")
    publish.add_argument("--source", type=Path, required=True)
    publish.add_argument("--destination", type=Path, required=True)
    split = subparsers.add_parser("finalize-split")
    split.add_argument("--source", type=Path, required=True)
    split.add_argument("--destination", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.command == "verify-template":
        verify_template(args.template, args.provenance, args.profile)
    elif args.command == "package":
        package(args.directory, args.template_kind, args.brotli)
    elif args.command == "publish-br":
        publish_brotli(args.source, args.destination)
    else:
        finalize_split(args.source, args.destination)


if __name__ == "__main__":
    main()
