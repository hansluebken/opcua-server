#!/bin/bash
#
# OPC-UA Access Package Creator
# =============================
# Erstellt ein ZIP-Paket mit allen Zugangsdaten und Dokumentation
#
# Verwendung:
#   ./create-access-package.sh
#
# Download:
#   scp root@opcua.netz-fabrik.net:/tmp/opcua-access-package.zip .

set -e

# Farben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   OPC-UA Access Package Creator                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Variablen
PACKAGE_DIR="/tmp/opcua-access-package"
OUTPUT_FILE="/tmp/opcua-access-package.zip"
REPO_DIR="/root/dev/opcua-server-repo"
GATEWAY_PKI="/opt/opcua/gateway/gateway-pki"

# Aufräumen falls vorhanden
rm -rf "$PACKAGE_DIR"
rm -f "$OUTPUT_FILE"

# Verzeichnis erstellen
mkdir -p "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/docs"
mkdir -p "$PACKAGE_DIR/credentials"
mkdir -p "$PACKAGE_DIR/server-certs"

echo -e "${BLUE}📦 Sammle Dateien...${NC}"
echo ""

# 1. Credentials
echo "  ✅ PRODUCTION-CREDENTIALS.txt"
cp "$REPO_DIR/PRODUCTION-CREDENTIALS.txt" "$PACKAGE_DIR/credentials/"

# 2. Server-Zertifikate (Gateway)
if [ -f "$GATEWAY_PKI/own/certs/certificate.pem" ]; then
    echo "  ✅ Gateway Server-Zertifikat"
    cp "$GATEWAY_PKI/own/certs/certificate.pem" "$PACKAGE_DIR/server-certs/gateway-server-cert.pem"
else
    echo "  ⚠️  Gateway Server-Zertifikat nicht gefunden"
fi

# 3. Dokumentation
echo "  ✅ Dokumentation (7 Dateien)"
cp "$REPO_DIR/README.md" "$PACKAGE_DIR/docs/"
cp "$REPO_DIR/CLIENT-ACCESS.md" "$PACKAGE_DIR/docs/"
cp "$REPO_DIR/ZERTIFIKATE-ERSTELLEN.md" "$PACKAGE_DIR/docs/"
cp "$REPO_DIR/ZUGANGSDATEN-DOWNLOAD.md" "$PACKAGE_DIR/docs/"
cp "$REPO_DIR/NODE-CONFIGURATION.md" "$PACKAGE_DIR/docs/"
cp "$REPO_DIR/S7-PRODUCTION-SETUP.md" "$PACKAGE_DIR/docs/"

# 4. README für das Paket
cat > "$PACKAGE_DIR/README.txt" <<'EOF'
╔════════════════════════════════════════════════════════════╗
║   OPC-UA Production Server - Access Package                ║
╚════════════════════════════════════════════════════════════╝

Server: opcua.netz-fabrik.net (87.106.33.7)
Endpoint: opc.tcp://opcua.netz-fabrik.net:4840

═══════════════════════════════════════════════════════════

📂 Inhalt dieses Pakets:

credentials/
  └── PRODUCTION-CREDENTIALS.txt     Usernames & Passwords (3 Rollen)

server-certs/
  └── gateway-server-cert.pem        Server-Zertifikat (optional)

docs/
  ├── README.md                      Repository-Übersicht
  ├── ZUGANGSDATEN-DOWNLOAD.md       Diese Anleitung (SCP-Download)
  ├── ZERTIFIKATE-ERSTELLEN.md       Client-Zertifikate erstellen (WICHTIG!)
  ├── CLIENT-ACCESS.md               Client-Zugriff und Verbindung
  ├── NODE-CONFIGURATION.md          85 Simulations-Nodes
  └── S7-PRODUCTION-SETUP.md         Server-Management

═══════════════════════════════════════════════════════════

🚀 Quick Start:

1. Credentials anzeigen:
   cat credentials/PRODUCTION-CREDENTIALS.txt

2. Client-Zertifikat erstellen:
   Siehe: docs/ZERTIFIKATE-ERSTELLEN.md
   (Zertifikate sind PFLICHT!)

3. Client-Code schreiben:
   Siehe: docs/CLIENT-ACCESS.md

4. Test-Verbindung (Python):

   import asyncio
   from asyncua import Client
   from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
   from asyncua import ua

   async def connect():
       url = "opc.tcp://opcua.netz-fabrik.net:4840"

       client = Client(url=url)
       client.application_uri = "urn:mycompany:opcua:client"
       client.set_user("opcua-operator")
       client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

       await client.set_security(
           SecurityPolicyBasic256Sha256,
           mode=ua.MessageSecurityMode.SignAndEncrypt
       )

       async with client:
           print("✅ Verbunden!")
           node = client.get_node("ns=2;s=Fast.UInt.0")
           value = await node.read_value()
           print(f"Wert: {value}")

   asyncio.run(connect())

═══════════════════════════════════════════════════════════

⚠️ WICHTIG:

1. Credentials schützen!
   chmod 600 credentials/PRODUCTION-CREDENTIALS.txt

2. NIEMALS in öffentliches Git committen!
   echo "credentials/" >> .gitignore

3. Client-Zertifikate MUSST du selbst erstellen!
   (Siehe docs/ZERTIFIKATE-ERSTELLEN.md)

═══════════════════════════════════════════════════════════

📚 Weitere Informationen:

- GitHub: https://github.com/hansluebken/opcua-server
- Support: siehe docs/S7-PRODUCTION-SETUP.md

Erstellt: $(date '+%Y-%m-%d %H:%M:%S')
Server: opcua.netz-fabrik.net
Modus: Production (S7-1500 Security)
EOF

echo ""
echo -e "${BLUE}📦 Erstelle ZIP-Archiv...${NC}"

# ZIP erstellen
cd /tmp
zip -r opcua-access-package.zip opcua-access-package/ > /dev/null

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Access Package erfolgreich erstellt!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Dateigröße
SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "  📦 Datei:  $OUTPUT_FILE"
echo "  📊 Größe:  $SIZE"
echo ""

echo -e "${YELLOW}📥 Download-Befehl:${NC}"
echo ""
echo "  scp root@opcua.netz-fabrik.net:/tmp/opcua-access-package.zip ."
echo ""

echo -e "${YELLOW}📂 Inhalt:${NC}"
unzip -l "$OUTPUT_FILE" | tail -n +4 | head -n -2
echo ""

echo -e "${YELLOW}🔓 Entpacken:${NC}"
echo ""
echo "  unzip opcua-access-package.zip"
echo "  cd opcua-access-package/"
echo "  cat README.txt"
echo ""

echo -e "${GREEN}Fertig!${NC}"
