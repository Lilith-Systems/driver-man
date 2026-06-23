#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path

DEST_DIR = Path("/home/tehlappy/Desktop/Lilith/data/gws_docs")

def log(msg: str):
    print(f"[gws-sync] {msg}", flush=True)

def run_gws(args: list[str]) -> str:
    cmd = ["gws"] + args
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"gws failed: {res.stderr or res.stdout}")
    return res.stdout.strip()

def download_file(file_id: str, file_name: str, mime_type: str):
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    out_path = DEST_DIR / file_name

    # Handle Google Doc types (Docs, Sheets, Slides) which must be exported
    if mime_type == "application/vnd.google-apps.document":
        log(f"Exporting document: {file_name}...")
        # Export Doc as PDF or Docx
        cmd = ["drive", "files", "export", "--params", json.dumps({"fileId": file_id, "mimeType": "application/pdf"}), "--output", str(out_path.with_suffix(".pdf"))]
    elif mime_type == "application/vnd.google-apps.spreadsheet":
        log(f"Exporting spreadsheet: {file_name}...")
        # Export Sheet as PDF or XLSX
        cmd = ["drive", "files", "export", "--params", json.dumps({"fileId": file_id, "mimeType": "application/pdf"}), "--output", str(out_path.with_suffix(".pdf"))]
    else:
        log(f"Downloading file: {file_name}...")
        cmd = ["drive", "files", "get", "--params", json.dumps({"fileId": file_id, "alt": "media"}), "--output", str(out_path)]

    try:
        run_gws(cmd)
        log(f"  ✓ Saved: {file_name}")
    except Exception as e:
        log(f"  ✗ Failed to download {file_name}: {e}")

def main():
    log("Checking gws auth status...")
    try:
        # Check if auth config exists by listing files
        files_json = run_gws(["drive", "files", "list", "--params", '{"pageSize": 100}', "--format", "json"])
        files_data = json.loads(files_json)
    except Exception as e:
        log("Google Workspace CLI not authenticated. Please run the following in your terminal first:")
        print("\n  polsia-business auth && gws auth login\n")
        sys.exit(2)

    files = files_data.get("files", []) if isinstance(files_data, dict) else []
    if not files:
        log("No files found in your Google Drive.")
        return

    log(f"Found {len(files)} files in Google Drive. Starting downloads...")
    for f in files:
        fid = f.get("id")
        fname = f.get("name", "unnamed_file")
        mime = f.get("mimeType", "")
        if fid and mime != "application/vnd.google-apps.folder":
            download_file(fid, fname, mime)

    log(f"Sync complete. Files saved to: {DEST_DIR}")

if __name__ == "__main__":
    main()
