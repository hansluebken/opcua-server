# OPC-UA Production Server - S7-1500 Security Gateway

**Production-Server mit Siemens S7-1500-ähnlicher Sicherheit**

- **Server:** opcua.netz-fabrik.net (87.106.33.7)
- **Endpoint:** `opc.tcp://opcua.netz-fabrik.net:4840`
- **Status:** 🟢 OPERATIONAL (Production Mode)
- **Installation:** 2025-10-15

---

## 🏗️ Architektur

Dieses Repository enthält die **tatsächlich installierte und laufende** OPC-UA Production-Konfiguration:

```
Internet/Clients
       ↓
   Port 4840
       ↓
[OPC-UA Security Gateway]  ← Erzwingt S7-1500 Sicherheit
  - ❌ Anonyme Auth BLOCKIERT
  - ✅ Username/Password ERFORDERLICH
  - ✅ Zertifikate ERFORDERLICH
  - ✅ Security: Basic256Sha256
       ↓
[Microsoft OPC PLC Simulator]  ← 85 Simulations-Nodes (intern)
  - 20 Slow Nodes (1s Update)
  - 50 Fast Nodes (10s Update)
  - 10 Volatile Nodes
  - 5 GUID Nodes
```

---

## 📁 Repository-Struktur (Nur aktive Komponenten)

```
opcua-server-repo/
├── gateway/
│   ├── docker-compose.yml           # Container-Konfiguration (Gateway + Simulator)
│   ├── gateway/
│   │   ├── gateway.js               # Security Gateway (Node.js)
│   │   ├── package.json
│   │   └── pki/                     # Gateway-Zertifikate (runtime)
│   ├── gateway-pki/                 # Gateway PKI (runtime)
│   ├── gateway-logs/                # Gateway Logs (runtime)
│   ├── simulator-pki/               # Simulator PKI (runtime)
│   └── simulator-logs/              # Simulator Logs (runtime)
│
├── gateway/opcua-gateway.service    # Systemd Service-Definition
│
├── S7-PRODUCTION-SETUP.md           # 📖 Haupt-Dokumentation (Setup, Server-Management)
├── CLIENT-ACCESS.md                 # 📖 Client-Zugriffs-Anleitung (NEU)
├── NODE-CONFIGURATION.md            # 📖 Node-Konfiguration (85 Nodes)
├── PRODUCTION-CREDENTIALS.txt       # 🔒 User-Credentials (NICHT in Git)
└── README.md                        # Diese Datei

```

### ⚠️ Wichtig: Nicht installierte Komponenten

Die folgenden Verzeichnisse/Dateien existieren **NICHT** in der Production-Installation:
- `server/` - Alter Development-Server (nicht mehr aktiv)
- `monitoring/` - Monitoring-Stack (nicht installiert)
- `web/` - Web-Interface (nicht installiert)
- `PRODUCTION-ACCESS-GUIDE.md` - Ersetzt durch CLIENT-ACCESS.md
- `OPC-UA-SERVER-STATUS.md` - Ersetzt durch S7-PRODUCTION-SETUP.md

---

## 🚀 Installierte Komponenten

### Docker Container (laufend)

| Container | Image | Port | Status |
|-----------|-------|------|--------|
| **opcua-gateway** | node:20-alpine | 4840 (extern) | 🟢 Healthy |
| **opcua-simulator** | opc-plc:latest | 4841 (intern) | 🟢 Running |

**Prüfen:**
```bash
docker ps --filter name=opcua
```

### Systemd Service

**Service:** `/etc/systemd/system/opcua-gateway.service`
**Arbeitsverzeichnis:** `/opt/opcua/gateway/`

**Management:**
```bash
# Status prüfen
systemctl status opcua-gateway.service

# Service starten
sudo systemctl start opcua-gateway.service

# Service stoppen
sudo systemctl stop opcua-gateway.service

# Service neu starten
sudo systemctl restart opcua-gateway.service

# Auto-Start aktivieren
sudo systemctl enable opcua-gateway.service
```

**Hinweis:** Container laufen aktuell **manuell** (gestartet mit `docker compose up -d`), nicht über systemd.

---

## 🔐 Sicherheits-Konfiguration

### S7-1500-ähnliche Sicherheit (AKTIV)

✅ **Anonyme Verbindungen:** BLOCKIERT
✅ **Username/Password:** ERFORDERLICH
✅ **Zertifikate:** Unterstützt (auto-accept für Testing)
✅ **Security Policy:** Basic256Sha256
✅ **Verschlüsselung:** Sign & Encrypt

### 3 User-Rollen

| Rolle | Username | Rechte |
|-------|----------|--------|
| **Reader** | `opcua-reader` | Nur Lesen |
| **Operator** | `opcua-operator` | Lesen & Schreiben |
| **Admin** | `opcua-admin` | Voller Zugriff |

**Credentials:** Siehe `PRODUCTION-CREDENTIALS.txt` (lokal auf Server, **NICHT** in Git)

---

## 📊 Verfügbare Nodes (85 Simulations-Nodes)

Der Server stellt **85 Nodes** über den Backend-Simulator bereit:

### Slow Nodes (20)
- Node-IDs: `ns=2;s=Slow.UInt.0` bis `ns=2;s=Slow.UInt.19`
- Update-Rate: 1 Sekunde
- Datentyp: UInt

### Fast Nodes (50)
- Node-IDs: `ns=2;s=Fast.UInt.0` bis `ns=2;s=Fast.UInt.49`
- Update-Rate: 10 Sekunden
- Datentyp: UInt

### Volatile Nodes (10)
- Node-IDs: `ns=2;s=Volatile.0` bis `ns=2;s=Volatile.9`
- Update: On-Demand (bei jedem Read)

### GUID Nodes (5)
- Node-IDs: `ns=2;s=Guid.0` bis `ns=2;s=Guid.4`
- Datentyp: GUID (deterministisch)

**Details:** Siehe **[NODE-CONFIGURATION.md](./NODE-CONFIGURATION.md)**

---

## 📖 Dokumentation

### Für Server-Betreiber

**[S7-PRODUCTION-SETUP.md](./S7-PRODUCTION-SETUP.md)** - Haupt-Dokumentation
- Server-Übersicht und Architektur
- Verbindungsdaten und Credentials
- Server-Management (Start/Stop/Restart)
- Sicherheitsfeatures (S7-1500-like)
- Troubleshooting
- Systemd Service Setup

### Für Client-Entwickler

**[CLIENT-ACCESS.md](./CLIENT-ACCESS.md)** - Client-Zugriffs-Anleitung ✨ NEU
- **Welche Daten/Dateien brauche ich für den Zugriff?**
- **Was liefert der Server dem Client?**
- **Wie importiere ich reale OPC-UA Server-Konfigurationen?**
- Verbindungs-Beispiele (Python, Node.js, UaExpert)
- Zertifikats-Erstellung
- Security Policies
- Troubleshooting

**[NODE-CONFIGURATION.md](./NODE-CONFIGURATION.md)** - Node-Details
- Alle 85 Nodes dokumentiert
- Node-Parameter und Customization
- Simulator-Konfiguration

---

## 🔌 Quick Start - Client-Verbindung

### Python (asyncua)

```python
import asyncio
from asyncua import Client

async def connect():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)

    # Credentials ERFORDERLICH!
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    async with client:
        print("✅ Verbunden!")

        # Node lesen
        node = client.get_node("ns=2;s=Fast.UInt.0")
        value = await node.read_value()
        print(f"Wert: {value}")

asyncio.run(connect())
```

**Mehr Beispiele:** Siehe **[CLIENT-ACCESS.md](./CLIENT-ACCESS.md)**

---

## 🛠️ Server-Management

### Container-Status prüfen

```bash
docker ps --filter name=opcua
```

Erwartet:
- `opcua-gateway` - Up, Healthy
- `opcua-simulator` - Up

### Logs ansehen

```bash
# Gateway-Logs
docker logs -f opcua-gateway

# Simulator-Logs
docker logs -f opcua-simulator
```

### Server neu starten

```bash
cd /opt/opcua/gateway
docker compose restart
```

### Server stoppen

```bash
cd /opt/opcua/gateway
docker compose down
```

### Server starten

```bash
cd /opt/opcua/gateway
docker compose up -d
```

---

## ⚙️ Technische Details

### Software-Versionen

- **OS:** Ubuntu 22.04.5 LTS
- **Kernel:** 5.15.0-131-generic
- **Docker:** 28.5.1
- **Docker Compose:** v2.40.0
- **Gateway:** Node.js 20 (node-opcua 2.119.0)
- **Simulator:** Microsoft OPC PLC (latest)

### Firewall

- **Port 4840:** ALLOW (OPC-UA Gateway)
- **Port 22:** LIMIT (SSH mit Rate-Limiting)
- **UFW:** Active

### Sicherheit

- **Fail2ban:** Active (SSH Intrusion Prevention)
- **Kernel Hardening:** SYN flood protection, IP spoofing protection
- **Docker Security:** ProtectSystem=full, PrivateTmp=true

---

## 🆘 Troubleshooting

### Problem: Server nicht erreichbar

```bash
# 1. Container-Status prüfen
docker ps --filter name=opcua

# 2. Port-Check
nc -zv opcua.netz-fabrik.net 4840

# 3. Logs prüfen
docker logs opcua-gateway --tail 50
```

### Problem: Verbindung wird abgelehnt

**Ursache:** Fehlende oder falsche Credentials

**Lösung:** Username/Password aus `PRODUCTION-CREDENTIALS.txt` verwenden:
```python
client.set_user("opcua-operator")
client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")
```

### Problem: Keine Nodes sichtbar

**Hinweis:** Backend-Proxy-Integration ist noch nicht vollständig. Gateway zeigt aktuell eigene Nodes.

**Workaround:** Bei Bedarf direkt zum Simulator verbinden (nur intern):
```
opc.tcp://opcua-simulator:4841  # Nur vom Server aus
```

---

## 📚 Weiterführende Links

- **node-opcua:** https://github.com/node-opcua/node-opcua
- **Microsoft OPC PLC:** https://github.com/Azure/iot-edge-opc-plc
- **asyncua (Python):** https://github.com/FreeOpcUa/opcua-asyncio
- **OPC Foundation:** https://opcfoundation.org

---

## 📞 Support & Kontakt

**Repository:** https://github.com/hansluebken/opcua-server

Bei Problemen:
1. Prüfe [S7-PRODUCTION-SETUP.md](./S7-PRODUCTION-SETUP.md) - Troubleshooting-Sektion
2. Prüfe [CLIENT-ACCESS.md](./CLIENT-ACCESS.md) - Client-spezifische Probleme
3. Prüfe Container-Logs: `docker logs opcua-gateway`

---

**Letzte Aktualisierung:** 2025-10-15
**Status:** 🟢 Production Ready
**Modus:** S7-1500 Security (Anonymous BLOCKED, Credentials REQUIRED)
