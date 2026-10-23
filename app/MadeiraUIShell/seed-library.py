#!/usr/bin/env python3
"""Writes madeira-library.json with the same mock games as app/CouchPreview.

Usage: seed-library.py <the app's Documents folder>
Artwork comes from Steam through each entry's steamID; nothing is installed.
"""
import json
import os
import sys
import time
import uuid

docs = sys.argv[1]
os.makedirs(docs, exist_ok=True)
now = time.time() - 978307200  # JSONEncoder's default Date: seconds since 2001
day = lambda d: now - d * 86400
gb = 1_000_000_000
games = [
    (367520, "Hollow Knight", day(0.2), 9 * gb), (1030300, "Hollow Knight: Silksong", day(1.5), 8 * gb),
    (1145350, "Hades II", day(3), 10 * gb), (268910, "Cuphead", day(9), 4 * gb), (620, "Portal 2", day(21), 12 * gb),
    (1809540, "Nine Sols", None, 11 * gb), (504230, "Celeste", day(40), 1_200_000_000),
    (413150, "Stardew Valley", None, 650_000_000), (292030, "The Witcher 3: Wild Hunt", None, 48 * gb),
    (1145360, "Hades", None, 15 * gb), (570940, "Dark Souls: Remastered", None, 8 * gb),
    (105600, "Terraria", None, 400_000_000), (391540, "Undertale", None, 200_000_000),
    (632470, "Disco Elysium", None, 20 * gb), (1229490, "ULTRAKILL", None, 2 * gb),
    (1868140, "DAVE THE DIVER", None, 10 * gb),
    (None, "Age of Empires II", day(12), 2 * gb), (None, "Half-Life (GOG)", None, 600_000_000),
]
entries = []
for steam_id, title, played, size in games:
    entry = {"id": str(uuid.uuid4()).upper(), "title": title,
             "relativePath": f"Games/{title.split(':')[0]}/game.exe", "bits": 64, "arguments": "",
             "resolution": "1408x648", "fpsMode": 1, "reducedX87": False, "liveLogs": False,
             "performance": False, "touchControls": False, "folderBytes": size}
    if steam_id:
        entry["steamID"] = steam_id
    if played:
        entry["lastPlayed"] = played
    entries.append(entry)
with open(os.path.join(docs, "madeira-library.json"), "w") as f:
    json.dump({"version": 1, "entries": entries}, f, indent=1)
print(f"{len(entries)} games written")
