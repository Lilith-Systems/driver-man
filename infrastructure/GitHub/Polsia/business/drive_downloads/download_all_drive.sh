#!/bin/bash
# Post-auth download of Google Drive docs
DOWNLOAD_DIR="${1:-$HOME/Desktop/Lilith/business/drive_downloads}"
mkdir -p "$DOWNLOAD_DIR"/{docs,sheets,slides,binaries,folders}

echo "=== Google Drive Download Script (gws + GAPI) ==="
echo "Target: $DOWNLOAD_DIR"

# Prefer gws if authed
if gws auth status 2>/dev/null | grep -q "authenticated"; then
  echo "gws authenticated - listing and downloading..."
  gws drive files list --params '{"pageSize":100}' --format json > "$DOWNLOAD_DIR/all_files.json" 2>/dev/null || true
  # Download example - in practice loop over IDs or specific q
  echo "Use: gws drive files get --params '{\"fileId\":\"ID\"}' -o $DOWNLOAD_DIR/binaries/file"
  echo "For Docs: add exportMimeType=application/pdf in params or use GAPI"
else
  echo "Using Hermes GAPI..."
  GAPI_PY="/home/tehlappy/.hermes/skills/productivity/google-workspace/scripts/google_api.py"
  if [ -f "$GAPI_PY" ]; then
    $GAPI_PY drive search "" --max 50 > "$DOWNLOAD_DIR/gapi_search.json" 2>/dev/null || echo "Run after Hermes setup"
    echo "Example download:"
    echo "  $GAPI_PY drive download FILE_ID --output $DOWNLOAD_DIR/docs/name.pdf --export-mime application/pdf"
  fi
fi

# Specific business folders
echo "Recommended queries:"
echo "  q: 'name = \"Polsia_Business\"' or parents in 'FOLDER_ID'"
echo "Download personal docs too."

ls -l "$DOWNLOAD_DIR"
echo ""
echo "=== Post auth example commands ==="
echo "gws drive files list --params '{\"pageSize\":20,\"q\":\"mimeType=\\'application/vnd.google-apps.document\\'\"}' --format table"
echo "For export: use GAPI or gws with export params"
echo "Hermes GAPI setup:"
echo "  python ~/.hermes/skills/productivity/google-workspace/scripts/setup.py --client-secret /path/to/json"
echo "  python .../setup.py --auth-url"
echo "  python .../setup.py --auth-code 'http://localhost:1/?code=....'"
echo "  python .../google_api.py drive download FILE_ID --output out.pdf --export-mime application/pdf"
