#!/usr/bin/env bash
#
# clone-project.sh – clone the NovaProject iOS base into a new app.
#
# Renames project / target / folders, sets bundle id, display name, AES key/iv for ad units,
# AdMob app id, optional Facebook ids and team id, fixes the local SPNComponent path, then git-inits.
#
# Example:
#   scripts/clone-project.sh \
#     --name ScanPro --display-name "Scan Pro" --bundle-id com.spn.scanpro \
#     --ad-key lk76fceliyrc4k4j9x4ho8nyf9dosqil --ad-iv nne5see1wq7kqacp \
#     --admob-app-id ca-app-pub-1234567890123456~1234567890 \
#     --dest ~/Documents/Work/scanpro \
#     [--fb-app-id 123 --fb-client-token abc] [--team-id ABCDE12345] \
#     [--google-service ~/Downloads/GoogleService-Info.plist] [--spn-path ~/Documents/Work/SPNComponent] [--no-git]
#
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLD_NAME="NovaProject"
OLD_BUNDLE_ID="com.spn.novaprojectbase"
OLD_DISPLAY_NAME="Nova Project"

NAME=""; DISPLAY_NAME=""; BUNDLE_ID=""; AD_KEY=""; AD_IV=""; ADMOB_APP_ID=""
DEST=""; FB_APP_ID=""; FB_CLIENT_TOKEN=""; TEAM_ID=""; GOOGLE_SERVICE=""; SPN_PATH=""; GIT_INIT=1

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --display-name) DISPLAY_NAME="$2"; shift 2 ;;
    --bundle-id) BUNDLE_ID="$2"; shift 2 ;;
    --ad-key) AD_KEY="$2"; shift 2 ;;
    --ad-iv) AD_IV="$2"; shift 2 ;;
    --admob-app-id) ADMOB_APP_ID="$2"; shift 2 ;;
    --dest) DEST="$2"; shift 2 ;;
    --fb-app-id) FB_APP_ID="$2"; shift 2 ;;
    --fb-client-token) FB_CLIENT_TOKEN="$2"; shift 2 ;;
    --team-id) TEAM_ID="$2"; shift 2 ;;
    --google-service) GOOGLE_SERVICE="$2"; shift 2 ;;
    --spn-path) SPN_PATH="$2"; shift 2 ;;
    --no-git) GIT_INIT=0; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# ---------- validation ----------
fail() { echo "error: $*" >&2; exit 1; }
[[ -n "$NAME" ]] || fail "--name is required (Xcode project / target name, e.g. ScanPro)"
[[ "$NAME" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || fail "--name must be an identifier (letters, digits, _), got '$NAME'"
[[ -n "$BUNDLE_ID" ]] || fail "--bundle-id is required"
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || fail "--bundle-id looks invalid: $BUNDLE_ID"
[[ -n "$AD_KEY" ]] || fail "--ad-key is required (32 chars, AES-256 key)"
[[ ${#AD_KEY} -eq 32 ]] || fail "--ad-key must be exactly 32 characters (got ${#AD_KEY})"
[[ -n "$AD_IV" ]] || fail "--ad-iv is required (16 chars)"
[[ ${#AD_IV} -eq 16 ]] || fail "--ad-iv must be exactly 16 characters (got ${#AD_IV})"
[[ -n "$ADMOB_APP_ID" ]] || fail "--admob-app-id is required (ca-app-pub-…~…)"
[[ "$ADMOB_APP_ID" =~ ^ca-app-pub-[0-9]+~[0-9]+$ ]] || fail "--admob-app-id looks invalid: $ADMOB_APP_ID"
[[ -n "$DISPLAY_NAME" ]] || DISPLAY_NAME="$NAME"
[[ -n "$DEST" ]] || DEST="$(dirname "$BASE_DIR")/$(echo "$NAME" | tr '[:upper:]' '[:lower:]')"
[[ -n "$SPN_PATH" ]] || SPN_PATH="$(dirname "$BASE_DIR")/SPNComponent"
[[ -e "$DEST" ]] && fail "destination already exists: $DEST"
[[ -f "$SPN_PATH/Package.swift" ]] || echo "warning: SPNComponent not found at $SPN_PATH (path will still be written)"
if [[ -n "$GOOGLE_SERVICE" ]]; then [[ -f "$GOOGLE_SERVICE" ]] || fail "GoogleService plist not found: $GOOGLE_SERVICE"; fi

echo "==> Cloning $OLD_NAME → $NAME"
echo "    dest:        $DEST"
echo "    bundle id:   $BUNDLE_ID"
echo "    display:     $DISPLAY_NAME"
echo "    admob app:   $ADMOB_APP_ID"
echo "    SPNComponent: $SPN_PATH"

# ---------- 1. copy ----------
mkdir -p "$DEST"
rsync -a "$BASE_DIR/" "$DEST/" \
  --exclude .git --exclude '*.xcuserdatad' --exclude xcuserdata --exclude DerivedData --exclude build \
  --exclude .DS_Store --exclude '.build*' --exclude 'project.xcworkspace/xcuserdata'

# ---------- 2. rename folders ----------
mv "$DEST/$OLD_NAME" "$DEST/$NAME"
mv "$DEST/$NAME/$OLD_NAME.xcodeproj" "$DEST/$NAME/$NAME.xcodeproj"
mv "$DEST/$NAME/$OLD_NAME" "$DEST/$NAME/$NAME"
PROJECT_DIR="$DEST/$NAME"
SRC_DIR="$PROJECT_DIR/$NAME"
PBXPROJ="$PROJECT_DIR/$NAME.xcodeproj/project.pbxproj"
INFO_PLIST="$SRC_DIR/Info.plist"

# ---------- 3. text replacements ----------
# Portable in-place sed (macOS BSD sed).
sedi() { LC_ALL=C sed -i '' "$@"; }

# Project / target / folder name in pbxproj, schemes, sources, plists, strings.
find "$PROJECT_DIR" -type f \( -name '*.pbxproj' -o -name '*.xcscheme' -o -name '*.swift' -o -name '*.plist' -o -name '*.strings' -o -name '*.yml' -o -name '*.md' \) -print0 \
  | xargs -0 grep -l "$OLD_NAME" 2>/dev/null \
  | while IFS= read -r f; do sedi "s/$OLD_NAME/$NAME/g" "$f"; done

# Bundle id.
grep -rIl "$OLD_BUNDLE_ID" "$PROJECT_DIR" 2>/dev/null | while IFS= read -r f; do sedi "s/$OLD_BUNDLE_ID/$BUNDLE_ID/g" "$f"; done

# Display name in every Localizable.strings ("ApplicationName" = "…";).
ESCAPED_DISPLAY="$(printf '%s' "$DISPLAY_NAME" | sed 's/[&/\]/\\&/g')"
find "$SRC_DIR/Resources/Localizables" -name 'Localizable.strings' | while IFS= read -r f; do
  sedi -E "s/^\"ApplicationName\" = \".*\";/\"ApplicationName\" = \"$ESCAPED_DISPLAY\";/" "$f"
done

# Team id (optional).
if [[ -n "$TEAM_ID" ]]; then
  sedi -E "s/(\"DEVELOPMENT_TEAM\[sdk=iphoneos\*\]\" = )[A-Z0-9]+;/\1$TEAM_ID;/g" "$PBXPROJ"
  sedi -E "s/(DEVELOPMENT_TEAM = )\"\";/\1$TEAM_ID;/g" "$PBXPROJ"
fi

# ---------- 4. secrets ----------
SECRETS="$SRC_DIR/AppEnvironment/AppSecrets.swift"
[[ -f "$SECRETS" ]] || fail "AppSecrets.swift not found at $SECRETS"
sedi -E "s/key: \"[^\"]*\"/key: \"$AD_KEY\"/" "$SECRETS"
sedi -E "s/iv: \"[^\"]*\"/iv: \"$AD_IV\"/" "$SECRETS"

# ---------- 5. Info.plist ----------
PB="/usr/libexec/PlistBuddy"
"$PB" -c "Set :GADApplicationIdentifier $ADMOB_APP_ID" "$INFO_PLIST" 2>/dev/null \
  || "$PB" -c "Add :GADApplicationIdentifier string $ADMOB_APP_ID" "$INFO_PLIST"
"$PB" -c "Set :FacebookDisplayName $DISPLAY_NAME" "$INFO_PLIST" 2>/dev/null || true
if [[ -n "$FB_APP_ID" ]]; then
  "$PB" -c "Set :FacebookAppID $FB_APP_ID" "$INFO_PLIST" 2>/dev/null || "$PB" -c "Add :FacebookAppID string $FB_APP_ID" "$INFO_PLIST"
  "$PB" -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 fb$FB_APP_ID" "$INFO_PLIST" 2>/dev/null || true
fi
if [[ -n "$FB_CLIENT_TOKEN" ]]; then
  "$PB" -c "Set :FacebookClientToken $FB_CLIENT_TOKEN" "$INFO_PLIST" 2>/dev/null || "$PB" -c "Add :FacebookClientToken string $FB_CLIENT_TOKEN" "$INFO_PLIST"
fi

# ---------- 6. GoogleService-Info.plist ----------
if [[ -n "$GOOGLE_SERVICE" ]]; then
  cp "$GOOGLE_SERVICE" "$SRC_DIR/GoogleService-Info.plist"
fi

# ---------- 7. SPNComponent local package path ----------
REL_SPN="$(python3 - "$PROJECT_DIR" "$SPN_PATH" <<'EOF'
import os, sys
print(os.path.relpath(os.path.abspath(sys.argv[2]), os.path.abspath(sys.argv[1])))
EOF
)"
ESCAPED_REL="$(printf '%s' "$REL_SPN" | sed 's/[&/\]/\\&/g')"
sedi -E "s#relativePath = [^;]+SPNComponent;#relativePath = $ESCAPED_REL;#" "$PBXPROJ"
sedi -E "s#XCLocalSwiftPackageReference \"[^\"]*SPNComponent\"#XCLocalSwiftPackageReference \"$ESCAPED_REL\"#g" "$PBXPROJ"

# ---------- 8. cleanup + git ----------
rm -rf "$DEST/scripts/__pycache__" "$DEST/docs/spn-component-architecture-draft.md"
if [[ $GIT_INIT -eq 1 ]]; then
  ( cd "$DEST" && git init -q && git add -A && git commit -qm "Initial commit: clone from $OLD_NAME as $NAME" )
fi

# ---------- 9. sanity ----------
LEFTOVER="$(grep -rIl "$OLD_NAME\|$OLD_BUNDLE_ID" "$PROJECT_DIR" 2>/dev/null | grep -v '\.git/' || true)"
[[ -z "$LEFTOVER" ]] || { echo "warning: '$OLD_NAME' still referenced in:"; echo "$LEFTOVER"; }
if command -v xcodebuild >/dev/null 2>&1; then
  ( cd "$PROJECT_DIR" && xcodebuild -list -project "$NAME.xcodeproj" >/dev/null 2>&1 ) && echo "==> project.pbxproj parses OK" || echo "warning: xcodebuild -list failed, check project.pbxproj"
fi

cat <<EOF

==> Done: $DEST

Next steps:
  1. Replace $SRC_DIR/GoogleService-Info.plist with the Firebase config of $BUNDLE_ID$( [[ -n "$GOOGLE_SERVICE" ]] && echo " (done)" )
  2. Update $SRC_DIR/Resources/DefaultConfigs/DefaultConfigs.json (encrypted ad unit ids for key/iv above, places, flags)
  3. Replace assets: Splash/logo, Intro/img_intro_1..3, Purchases/*, AppIcon; adjust OnboardingConfigs.swift + AppTheme.swift
  4. Update strings: LoadData.SubTitle, Introduce.Step*.Title, Purchase.* in Resources/Localizables/*.lproj
  5. Set appStoreUrl / privacyUrl / termOfUseUrl in AppEnvironment/AppConstants.swift and product ids in Purchase/PurchaseEntity.swift
  6. Open $PROJECT_DIR/$NAME.xcodeproj, set signing team, build:
       xcodebuild -project $NAME.xcodeproj -scheme $NAME -destination 'generic/platform=iOS Simulator' build
EOF
