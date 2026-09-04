#!/usr/bin/env python3
"""Build a Firebase Remote Config template from the app's bundled DefaultConfigs.json.

DefaultConfigs.json is plain JSON keyed by config name; Remote Config wants
{"parameters": {key: {"defaultValue": {"value": "<json string>"}, "valueType": "JSON"}}}.
Every top-level key becomes one JSON parameter, so the remote payload matches what
FirebaseRemoteConfigStore reads per key.

usage:
  scripts/make-remoteconfig-template.py                      # -> firebase/remoteconfig.template.json
  scripts/make-remoteconfig-template.py --merge current.json # keep parameters that exist only remotely
"""
import argparse, datetime, json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULTS = ROOT / "HWPViewer/HWPViewer/Resources/DefaultConfigs/DefaultConfigs.json"
OUT = ROOT / "firebase/remoteconfig.template.json"

ap = argparse.ArgumentParser()
ap.add_argument("--merge", help="existing template (from GET remoteConfig) to merge into")
ap.add_argument("--out", default=str(OUT))
args = ap.parse_args()

defaults = json.loads(DEFAULTS.read_text(encoding="utf-8"))
# Same shape as a console "Download current template" export: conditions + parameters + version.
template = {"conditions": [], "parameters": {}}
if args.merge:
    template = json.loads(pathlib.Path(args.merge).read_text(encoding="utf-8"))
    template.setdefault("conditions", [])
    template.setdefault("parameters", {})

for key, value in defaults.items():
    template["parameters"][key] = {
        "defaultValue": {"value": json.dumps(value, ensure_ascii=False, separators=(",", ":"))},
        "valueType": "JSON",
    }

template["version"] = {
    "versionNumber": str(int(template.get("version", {}).get("versionNumber", "0")) + 1),
    "updateTime": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
    "updateUser": {"email": "datnh@supernovajsc.com"},
    "updateOrigin": "CONSOLE",
    "updateType": "INCREMENTAL_UPDATE",
}
ordered = {"conditions": template["conditions"], "parameters": template["parameters"], "version": template["version"]}
pathlib.Path(args.out).write_text(json.dumps(ordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"wrote {args.out}: {len(defaults)} parameters" + (" (merged)" if args.merge else ""))
