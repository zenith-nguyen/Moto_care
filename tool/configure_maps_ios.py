"""Copy an ignored local iOS map key into Xcode settings without logging it."""
import json
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "config/maps.local.json"
config = json.loads(source.read_text())
key = config.get("GOOGLE_MAPS_IOS_API_KEY", "")
if not isinstance(key, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", key):
    sys.exit("Set GOOGLE_MAPS_IOS_API_KEY in the local configuration first.")
(root / "ios/Flutter/MapsKeys.xcconfig").write_text(
    "// Generated from local configuration; never commit this file.\n"
    + "GOOGLE_MAPS_IOS_API_KEY = " + key + "\n"
)
print("iOS Maps settings configured.")
