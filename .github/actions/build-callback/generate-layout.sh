#!/bin/bash
set -euo pipefail

cd "$BUILD_DIR"

subjects=""
for binary in avalanchego plugins/evm; do
  if [ -f "$binary" ]; then
    hash=$(sha256sum "$binary" | awk '{print $1}')
    subject_name=$(basename "$(readlink -m "$binary")")
    
    if [ -n "$subjects" ]; then
      subjects+=","
    fi
    
    printf -v subject \
      '{"name": "%s", "digest": {"sha256": "%s"}}' \
      "$subject_name" "$hash"
    subjects+="$subject"
  fi
done

cat <<EOF > "$SLSA_OUTPUTS_ARTIFACTS_FILE"
{
    "version": 1,
    "attestations":
    [
        {
            "name": "go-flare-binaries",
            "subjects":
            [
                ${subjects}
            ]
        }
    ]
}
EOF