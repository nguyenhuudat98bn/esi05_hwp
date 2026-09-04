# Firebase Remote Config

`remoteconfig.template.json` is generated from `HWPViewer/HWPViewer/Resources/DefaultConfigs.json`
(`scripts/make-remoteconfig-template.py`) — one JSON parameter per top-level key, exactly what
`FirebaseRemoteConfigStore` reads. Do not edit it by hand: change DefaultConfigs.json, regenerate, upload.

## Before uploading

The app currently ships the **base project's** `GoogleService-Info.plist` (`novabaseproject`,
`1:910522807817:ios:…`). Uploading a full template there overwrites the Remote Config shared by other
apps. Create the Firebase project/app for `com.spn.hwpviewer.editor`, replace
`HWPViewer/HWPViewer/GoogleService-Info.plist`, then upload to that project.

## Upload

Publishing a template replaces **every** parameter, so merge with what is already there:

```bash
PROJECT=<firebase-project-id>
TOKEN=$(gcloud auth print-access-token)      # account must have Firebase Remote Config Admin
API=https://firebaseremoteconfig.googleapis.com/v1/projects/$PROJECT/remoteConfig

# 1. current template (+ ETag needed for the PUT)
curl -s -D headers.txt -H "Authorization: Bearer $TOKEN" $API -o current.json
ETAG=$(grep -i '^etag:' headers.txt | awk '{print $2}' | tr -d '\r')

# 2. merge DefaultConfigs.json into it
scripts/make-remoteconfig-template.py --merge current.json

# 3. publish
curl -s -X PUT $API \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json; UTF8" -H "If-Match: $ETAG" \
  --data @firebase/remoteconfig.template.json
```

Or with the Firebase CLI (`npm i -g firebase-tools`, `firebase login`): `firebase use $PROJECT`,
`firebase remoteconfig:get -o current.json`, regenerate with `--merge`, then
`firebase deploy --only remoteconfig` (reads `firebase.json`).

Values are strings in the template (`defaultValue.value` = compact JSON); the console shows them as
type JSON and lets you edit per key afterwards.
