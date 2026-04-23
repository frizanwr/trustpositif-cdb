#!/bin/bash

# Configuration
BLOCKLIST_DIR="/opt/trustpositif-cdb"
RAW_FILE="${BLOCKLIST_DIR}/domains_isp"
INPUT_FILE="${BLOCKLIST_DIR}/domains.input"
CDB_FILE="${BLOCKLIST_DIR}/domains.cdb"
TMP_FILE="${BLOCKLIST_DIR}/domains.tmp"
SOURCE_URL="https://trustpositif.komdigi.go.id/assets/db/domains_isp"

DNSDIST_USER="_dnsdist"
DNSDIST_GROUP="_dnsdist"

set -e

# Function untuk timestamp proses
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 1. Dependency Check
for cmd in wget awk cdbmake chown; do
    if ! command -v "$cmd" &> /dev/null; then
        log_msg "ERROR: Command '$cmd' tidak ditemukan."
        exit 1
    fi
done

START_TIME=$(date +%s)
log_msg "Memulai proses pembaruan database TrustPositif"

# 2. Download Database
log_msg "Downloading database terbaru dari Komdigi"
if ! wget -q -O "$RAW_FILE" "$SOURCE_URL"; then
    log_msg "ERROR: Gagal mendownload database!"
    exit 1
fi

# 3. Validation
if [ ! -s "$RAW_FILE" ]; then
    log_msg "ERROR: Database hasil download kosong."
    exit 1
fi

# 4. Convert to CDB Format
log_msg "Mengonversi data ke format input CDB"
awk '{ print "+" length($0) ",1:" $0 "->1" } END { print "" }' "$RAW_FILE" > "$INPUT_FILE"

# 5. Build CDB Database
log_msg "Membangun database CDB"
if ! cdbmake "$CDB_FILE" "$TMP_FILE" < "$INPUT_FILE"; then
    log_msg "ERROR: Gagal membangun file CDB."
    rm -f "$INPUT_FILE" "$TMP_FILE"
    exit 1
fi

# 6. Permissions & Cleanup
chown ${DNSDIST_USER}:${DNSDIST_GROUP} "$CDB_FILE"
chmod 644 "$CDB_FILE"
rm -f "$INPUT_FILE" "$TMP_FILE"

log_msg "Pembaruan database trustpositif selesai."

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
TOTAL_DOMAINS=$(wc -l < "$RAW_FILE")

# Summary tanpa timestamp
echo "-------------------------------------------------------"
echo "Total domain yang diproses : $TOTAL_DOMAINS"
echo "Durasi eksekusi            : $DURATION detik"
echo "-------------------------------------------------------"
