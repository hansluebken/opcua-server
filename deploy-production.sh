#!/bin/bash
#
# OPC-UA Server - Production Deployment Script
# =============================================
# Dieses Skript aktiviert den Production-Modus auf dem Server
#
# Autor: NETZFABRIK
# Datum: 2025-10-15
# Server: opcua.netz-fabrik.net (87.106.33.7)

set -e  # Exit bei Fehler

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   OPC-UA Server - Production Deployment               ║"
echo "║   Security: Certificate-Based (wie S7-1500)           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Prüfe ob als root oder mit sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Dieses Skript muss als root ausgeführt werden${NC}"
   echo "   Verwende: sudo $0"
   exit 1
fi

# Variablen
SERVER_DIR="/opt/opcua/server"
BACKUP_DIR="/opt/opcua/backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}📍 Server-Verzeichnis: $SERVER_DIR${NC}"
echo ""

# Prüfe ob Server-Verzeichnis existiert
if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${RED}❌ Server-Verzeichnis nicht gefunden: $SERVER_DIR${NC}"
    exit 1
fi

cd "$SERVER_DIR"

# ========================================
# 1. BACKUP erstellen
# ========================================
echo -e "${BLUE}📦 Schritt 1: Backup der aktuellen Konfiguration${NC}"

mkdir -p "$BACKUP_DIR"

if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml "$BACKUP_DIR/docker-compose.yml.backup-$TIMESTAMP"
    echo -e "${GREEN}✅ Backup erstellt: $BACKUP_DIR/docker-compose.yml.backup-$TIMESTAMP${NC}"
else
    echo -e "${YELLOW}⚠️  Keine bestehende docker-compose.yml gefunden${NC}"
fi

echo ""

# ========================================
# 2. Server stoppen
# ========================================
echo -e "${BLUE}🛑 Schritt 2: Server stoppen${NC}"

if docker ps --filter name=opcua-server --format "{{.Names}}" | grep -q opcua-server; then
    echo "Stoppe Container..."
    docker compose down || true
    echo -e "${GREEN}✅ Server gestoppt${NC}"
else
    echo -e "${YELLOW}ℹ️  Server läuft nicht${NC}"
fi

echo ""

# ========================================
# 3. Production-Konfiguration aktivieren
# ========================================
echo -e "${BLUE}🔧 Schritt 3: Production-Konfiguration aktivieren${NC}"

# Prüfe ob Production-Config existiert
if [ ! -f "docker-compose.production.yml" ]; then
    echo -e "${RED}❌ Production-Konfiguration nicht gefunden!${NC}"
    echo "   Erwarteter Pfad: $SERVER_DIR/docker-compose.production.yml"
    echo ""
    echo "Bitte kopiere die Production-Config:"
    echo "   cp /path/to/docker-compose.production.yml $SERVER_DIR/"
    exit 1
fi

# Backup der alten Config (falls vorhanden)
if [ -f "docker-compose.yml" ]; then
    mv docker-compose.yml docker-compose.yml.old
    echo "   Alte Config gesichert: docker-compose.yml.old"
fi

# Production-Config aktivieren
cp docker-compose.production.yml docker-compose.yml
echo -e "${GREEN}✅ Production-Konfiguration aktiviert${NC}"

echo ""

# ========================================
# 4. Verzeichnisse vorbereiten
# ========================================
echo -e "${BLUE}📁 Schritt 4: Verzeichnisse vorbereiten${NC}"

# Erstelle benötigte Verzeichnisse falls nicht vorhanden
mkdir -p data logs certs config

# Setze Berechtigungen
chmod 777 data logs certs config
echo -e "${GREEN}✅ Verzeichnisse vorbereitet${NC}"

echo ""

# ========================================
# 5. Docker Network prüfen/erstellen
# ========================================
echo -e "${BLUE}🌐 Schritt 5: Docker Network prüfen${NC}"

if ! docker network ls | grep -q opcua-network; then
    echo "Erstelle opcua-network..."
    docker network create opcua-network
    echo -e "${GREEN}✅ Network erstellt: opcua-network${NC}"
else
    echo -e "${GREEN}✅ Network existiert bereits: opcua-network${NC}"
fi

echo ""

# ========================================
# 6. Server starten (Production Mode)
# ========================================
echo -e "${BLUE}🚀 Schritt 6: Server im Production-Modus starten${NC}"

# Pull latest image
echo "Lade aktuelles Server-Image..."
docker compose pull

# Start im Daemon-Modus
echo "Starte Server..."
docker compose up -d

# Warte auf Start
echo "Warte auf Server-Start..."
sleep 5

# Prüfe Status
if docker ps --filter name=opcua-server --filter status=running --format "{{.Names}}" | grep -q opcua-server; then
    echo -e "${GREEN}✅ Server läuft im Production-Modus!${NC}"
else
    echo -e "${RED}❌ Server konnte nicht gestartet werden${NC}"
    echo "Prüfe Logs mit: docker logs opcua-server"
    exit 1
fi

echo ""

# ========================================
# 7. Status anzeigen
# ========================================
echo -e "${BLUE}📊 Schritt 7: Server-Status${NC}"
echo ""

docker ps --filter name=opcua-server --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# ========================================
# 8. Konfiguration anzeigen
# ========================================
echo -e "${BLUE}📋 Production-Konfiguration:${NC}"
echo ""
echo "  Endpoint:       opc.tcp://opcua.netz-fabrik.net:4840"
echo "  IP:             87.106.33.7:4840"
echo ""
echo -e "${GREEN}  Security Mode:${NC}  Certificate-Based (wie S7-1500)"
echo "  ✅ Anonymous Auth:    DEAKTIVIERT"
echo "  ✅ Certificate Auth:  ERFORDERLICH"
echo "  ✅ Encryption:        SignAndEncrypt"
echo "  ✅ Security Policy:   Basic256Sha256"
echo ""

# ========================================
# 9. Logs anzeigen
# ========================================
echo -e "${BLUE}📄 Server-Logs (letzte 20 Zeilen):${NC}"
echo ""
docker logs --tail 20 opcua-server

echo ""

# ========================================
# 10. Nächste Schritte
# ========================================
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Production-Deployment erfolgreich!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📖 Nächste Schritte:${NC}"
echo ""
echo "1. Verbindung testen:"
echo "   ${BLUE}nc -zv opcua.netz-fabrik.net 4840${NC}"
echo ""
echo "2. Mit Client verbinden:"
echo "   Siehe: PRODUCTION-ACCESS-GUIDE.md"
echo "   - Du benötigst ein X.509 Zertifikat"
echo "   - Security: Basic256Sha256, SignAndEncrypt"
echo ""
echo "3. Credentials anzeigen:"
echo "   ${BLUE}cat PRODUCTION-CREDENTIALS.txt${NC}"
echo ""
echo "4. Server-Status prüfen:"
echo "   ${BLUE}docker logs -f opcua-server${NC}"
echo "   ${BLUE}systemctl status opcua-server.service${NC}"
echo ""
echo "5. Bei Problemen:"
echo "   ${BLUE}docker logs opcua-server${NC}"
echo "   ${BLUE}docker ps -a${NC}"
echo ""
echo -e "${YELLOW}⚠️  Wichtig:${NC}"
echo "   - Credentials sicher aufbewahren (PRODUCTION-CREDENTIALS.txt)"
echo "   - Regelmäßig Backups erstellen"
echo "   - Zertifikate regelmäßig erneuern (empfohlen: alle 365 Tage)"
echo ""
echo "Backup-Location: $BACKUP_DIR"
echo ""
echo -e "${GREEN}Server läuft jetzt im Production-Modus! 🎉${NC}"
echo ""
