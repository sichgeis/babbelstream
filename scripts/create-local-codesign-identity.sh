#!/usr/bin/env bash
set -euo pipefail

IDENTITY_NAME="${LOCAL_CODESIGN_IDENTITY:-BabbelStream Local Code Signing}"
KEYCHAIN="${KEYCHAIN:-$HOME/Library/Keychains/login.keychain-db}"
DAYS="${DAYS:-3650}"
FORCE="${FORCE:-false}"

if [[ "$FORCE" != "true" ]] && security find-certificate -c "$IDENTITY_NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "Code-signing identity already exists: $IDENTITY_NAME"
  exit 0
fi

security delete-identity -c "$IDENTITY_NAME" "$KEYCHAIN" >/dev/null 2>&1 || true
security delete-certificate -c "$IDENTITY_NAME" "$KEYCHAIN" >/dev/null 2>&1 || true

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

KEY_PATH="$TMP_DIR/local-codesign.key"
CERT_PATH="$TMP_DIR/local-codesign.crt"
P12_PATH="$TMP_DIR/local-codesign.p12"
P12_PASSWORD="$(uuidgen)"

openssl req \
  -newkey rsa:2048 \
  -nodes \
  -keyout "$KEY_PATH" \
  -x509 \
  -days "$DAYS" \
  -out "$CERT_PATH" \
  -subj "/CN=$IDENTITY_NAME/" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature,keyCertSign" \
  -addext "extendedKeyUsage=codeSigning" \
  -addext "subjectKeyIdentifier=hash" >/dev/null 2>&1

openssl pkcs12 \
  -export \
  -legacy \
  -out "$P12_PATH" \
  -inkey "$KEY_PATH" \
  -in "$CERT_PATH" \
  -name "$IDENTITY_NAME" \
  -passout "pass:$P12_PASSWORD" >/dev/null 2>&1

security import "$P12_PATH" \
  -k "$KEYCHAIN" \
  -P "$P12_PASSWORD" \
  -T /usr/bin/codesign >/dev/null

if ! security find-certificate -c "$IDENTITY_NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "Imported identity, but certificate was not found in keychain: $KEYCHAIN" >&2
  exit 1
fi

security add-trusted-cert \
  -r trustRoot \
  -p codeSign \
  -k "$KEYCHAIN" \
  "$CERT_PATH" >/dev/null

if ! security find-identity -v -p codesigning "$KEYCHAIN" | grep -F "\"$IDENTITY_NAME\"" >/dev/null; then
  echo "Imported certificate, but no valid code-signing identity was found: $IDENTITY_NAME" >&2
  exit 1
fi

echo "Created local code-signing identity: $IDENTITY_NAME"
echo "Keychain: $KEYCHAIN"
echo "Run scripts/install-dev-app.sh, drag BabbelStream.app to Applications, then remove and re-add /Applications/BabbelStream.app in Accessibility once."
