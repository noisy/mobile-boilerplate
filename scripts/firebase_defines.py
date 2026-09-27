#!/usr/bin/env python3
"""Turns the Firebase config files into Flutter dart-defines.

Reads firebase/google-services.json (Android) and
firebase/GoogleService-Info.plist (iOS), checks that they belong to the
project and application id in app.env, and writes the values the app needs
(lib/core/config/firebase_config.dart) as a JSON file for
`flutter build/run --dart-define-from-file`.

    scripts/firebase_defines.py [--out build/firebase_defines.json]

Either file may be missing (e.g. an Android-only setup). With neither, it
writes nothing and exits 3, so callers build in demo mode.
"""

import argparse
import json
import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NO_CONFIG = 3

# google-services.json oauth_client types.
WEB_CLIENT = 3


class ConfigError(Exception):
    pass


def read_app_env(path):
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"')
    return values


def android_defines(google_services, app_id, project):
    info = google_services["project_info"]
    if info["project_id"] != project:
        raise ConfigError(
            f"google-services.json is for project {info['project_id']}, "
            f"app.env says {project}"
        )
    clients = [
        c
        for c in google_services["client"]
        if c["client_info"]["android_client_info"]["package_name"] == app_id
    ]
    if not clients:
        raise ConfigError(
            f"google-services.json has no Android app {app_id}; "
            "add it in the Firebase console and download the file again"
        )
    client = clients[0]
    web_clients = [
        o["client_id"]
        for o in client.get("oauth_client", [])
        + client.get("services", {})
        .get("appinvite_service", {})
        .get("other_platform_oauth_client", [])
        if o.get("client_type") == WEB_CLIENT
    ]
    defines = {
        "FIREBASE_PROJECT_ID": info["project_id"],
        "FIREBASE_MESSAGING_SENDER_ID": info["project_number"],
        "FIREBASE_STORAGE_BUCKET": info.get("storage_bucket", ""),
        "FIREBASE_ANDROID_APP_ID": client["client_info"]["mobilesdk_app_id"],
        "FIREBASE_ANDROID_API_KEY": client["api_key"][0]["current_key"],
    }
    if web_clients:
        defines["GOOGLE_SERVER_CLIENT_ID"] = web_clients[0]
    return defines


def ios_defines(plist, app_id, project):
    if plist["PROJECT_ID"] != project:
        raise ConfigError(
            f"GoogleService-Info.plist is for project {plist['PROJECT_ID']}, "
            f"app.env says {project}"
        )
    if plist["BUNDLE_ID"] != app_id:
        raise ConfigError(
            f"GoogleService-Info.plist is for bundle {plist['BUNDLE_ID']}, "
            f"app.env says {app_id}"
        )
    defines = {
        "FIREBASE_PROJECT_ID": plist["PROJECT_ID"],
        "FIREBASE_MESSAGING_SENDER_ID": plist["GCM_SENDER_ID"],
        "FIREBASE_STORAGE_BUCKET": plist.get("STORAGE_BUCKET", ""),
        "FIREBASE_IOS_APP_ID": plist["GOOGLE_APP_ID"],
        "FIREBASE_IOS_API_KEY": plist["API_KEY"],
        "FIREBASE_IOS_BUNDLE_ID": plist["BUNDLE_ID"],
    }
    if "CLIENT_ID" in plist:
        defines["GOOGLE_IOS_CLIENT_ID"] = plist["CLIENT_ID"]
        defines["GOOGLE_IOS_REVERSED_CLIENT_ID"] = plist["REVERSED_CLIENT_ID"]
    return defines


def collect(root):
    env = read_app_env(root / "app.env")
    app_id, project = env["APP_ID"], env["FIREBASE_PROJECT"]
    android = root / "firebase" / "google-services.json"
    ios = root / "firebase" / "GoogleService-Info.plist"
    defines = {}
    if android.exists():
        defines.update(android_defines(json.loads(android.read_text()), app_id, project))
    if ios.exists():
        with ios.open("rb") as f:
            defines.update(ios_defines(plistlib.load(f), app_id, project))
    return defines


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=str(ROOT / "build" / "firebase_defines.json"))
    args = parser.parse_args()
    try:
        defines = collect(ROOT)
    except ConfigError as e:
        print(f"firebase config: {e}", file=sys.stderr)
        return 1
    if not defines:
        print("firebase config: no files in firebase/, building in demo mode", file=sys.stderr)
        return NO_CONFIG
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(defines, indent=2) + "\n")
    print(f"firebase config: {len(defines)} values -> {out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
