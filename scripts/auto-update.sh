#!/bin/bash

# Configuration
BLOCKLIST_DIR="/opt/trustpositif-cdb"
RAW_FILE="${BLOCKLIST_DIR}/domains_isp"
INPUT_FILE="${BLOCKLIST_DIR}/domains.input"
CDB_FILE="${BLOCKLIST_DIR}/domains.cdb"
TMP_FILE="${BLOCKLIST_DIR}/domains.tmp"
SIZE_FILE="${BLOCKLIST_DIR}/.domains.size" # Nama file diganti agar sesuai konteks
SOURCE_URL="https://trustpositif.komdigi.go.id/assets/db/domains_isp"

# Lock configuration
LOCK_FILE="/run/lock/trustpositif-update.lock"
DNSDIST_USER="_dnsdist"
DNSDIST_GROUP="_dnsdist"
TAG="trustpositif-cdb"

set -e

# Minimalist logger
log_msg() {
    logger -t "$TAG" "$1"
}

# --- FITUR LOCK MULAI ---
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log_msg "WARNING: Script is already running by another process. Exiting."
    exit 0
fi
# --- FITUR LOCK SELESAI ---

# 1. Dependency Check
for cmd in wget awk cdbmake chown curl logger flock; do
    if ! command -v "$cmd" &> /dev/null; then
        log_msg "ERROR: Command '$cmd' not found."
        exit 1
    fi
done

# 2. Content-Length Validation & Comparison
# Mengambil Content-Length dari header HTTP
NEW_SIZE=$(curl -sI "$SOURCE_URL" | grep -i '^content-length:' | awk '{print $2}' | tr -d '\r' | xargs)

if [ -z "$NEW_SIZE" ]; then
    log_msg "ERROR: Could not fetch Content-Length from server."
    exit 1
fi

if [ -f "$SIZE_FILE" ]; then
    OLD_SIZE=$(cat "$SIZE_FILE" | xargs)
    # Jika ukuran masih sama, langsung exit tanpa proses
    if [ "$NEW_SIZE" == "$OLD_SIZE" ]; then
        exit 0
    fi
fi

# 3. Process Update
START_TIME=$(date +%s)
log_msg "New version detected (Size changed from ${OLD_SIZE:-0} to $NEW_SIZE). Starting update process..."

if ! wget -q -O "$RAW_FILE" "$SOURCE_URL"; then
    log_msg "ERROR: Download failed."
    exit 1
fi

if [ ! -s "$RAW_FILE" ]; then
    log_msg "ERROR: Downloaded file is empty."
    exit 1
fi

# 4. Conversion & CDB Build
awk '{ print "+" length($0) ",1:" $0 "->1" } END { print "" }' "$RAW_FILE" > "$INPUT_FILE"

if ! cdbmake "$CDB_FILE" "$TMP_FILE" < "$INPUT_FILE"; then
    log_msg "ERROR: CDB build failed."
    rm -f "$INPUT_FILE" "$TMP_FILE"
    exit 1
fi

# 5. Finalize
chown ${DNSDIST_USER}:${DNSDIST_GROUP} "$CDB_FILE"
chmod 644 "$CDB_FILE"
echo "$NEW_SIZE" > "$SIZE_FILE"
rm -f "$INPUT_FILE" "$TMP_FILE"

END_TIME=$(date +%s)
TOTAL_DOMAINS=$(wc -l < "$RAW_FILE")
DURATION=$((END_TIME - START_TIME))

log_msg "Update success. Domains: $TOTAL_DOMAINS. Duration: ${DURATION}s."
