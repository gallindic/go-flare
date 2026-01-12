#!/bin/bash
set -euo pipefail

echo "=== Debug: Environment Variables ==="
echo "SLSA_OUTPUTS_DIR: ${SLSA_OUTPUTS_DIR:-NOT SET}"
echo "SLSA_OUTPUTS_ARTIFACTS_FILE: ${SLSA_OUTPUTS_ARTIFACTS_FILE:-NOT SET}"
echo "BUILD_DIR: ${BUILD_DIR:-NOT SET}"
echo "PWD: $(pwd)"

echo -e "\n=== Debug: Directory Structure ==="
echo "Contents of ../"
ls -la ../ || echo "Failed to list ../"

echo -e "\nContents of SLSA_OUTPUTS_DIR ($SLSA_OUTPUTS_DIR):"
ls -la "$SLSA_OUTPUTS_DIR" || echo "SLSA_OUTPUTS_DIR does not exist or is not accessible"

echo -e "\nContents of BUILD_DIR ($BUILD_DIR):"
ls -la "$BUILD_DIR" || echo "BUILD_DIR does not exist or is not accessible"

echo -e "\n=== Debug: Checking for binaries ==="
for binary in "$BUILD_DIR/avalanchego" "$BUILD_DIR/plugins/evm"; do
  if [ -f "$binary" ]; then
    echo "✓ Found: $binary"
  else
    echo "✗ Missing: $binary"
  fi
done

echo -e "\n=== Debug: Output file path ==="
echo "Output dir: $(dirname "$SLSA_OUTPUTS_ARTIFACTS_FILE")"
echo "Output dir exists: $(test -d "$(dirname "$SLSA_OUTPUTS_ARTIFACTS_FILE")" && echo "YES" || echo "NO")"

# Create output directory
mkdir -p "$(dirname "$SLSA_OUTPUTS_ARTIFACTS_FILE")"
echo "Created output directory"

echo -e "\n=== Building subjects ==="
subjects=""
for binary in "$BUILD_DIR/avalanchego" "$BUILD_DIR/plugins/evm"; do
  if [ -f "$binary" ]; then
    hash=$(sha256sum "$binary" | awk '{print $1}')
    subject_name=$(basename "$binary")
    echo "Processing: $subject_name (hash: $hash)"
    
    [ -n "$subjects" ] && subjects+=","
    
    printf -v subject '{"name": "%s", "digest": {"sha256": "%s"}}' "$subject_name" "$hash"
    subjects+="$subject"
  fi
done

echo -e "\n=== Writing layout file ==="
cat <<EOF > "$SLSA_OUTPUTS_ARTIFACTS_FILE"
{
  "version": 1,
  "attestations": [{
    "name": "go-flare-binaries",
    "subjects": [${subjects}]
  }]
}
EOF

echo "Layout file written successfully"
cat "$SLSA_OUTPUTS_ARTIFACTS_FILE"