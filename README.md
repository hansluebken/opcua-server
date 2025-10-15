# OPC-UA Production Server Configuration

This repository contains the **active production configuration** for the OPC-UA server deployed at `opcua.netz-fabrik.net`.

## Server Information

- **Domain:** opcua.netz-fabrik.net
- **IP Address:** 87.106.33.7
- **OPC-UA Endpoint:** `opc.tcp://opcua.netz-fabrik.net:4840`
- **Status:** ✅ Operational

## Repository Contents

### Active Components

```
opcua-server/
├── server/
│   ├── docker-compose.yml      # OPC-UA server Docker configuration
│   ├── config/                 # Server configuration files
│   ├── data/                   # PKI certificates (generated at runtime)
│   ├── certs/                  # Additional certificates
│   └── logs/                   # Server logs (runtime only)
│
├── client/
│   └── python/                 # Python client development
│
├── scripts/                    # Utility scripts
│
├── ssl/                        # SSL/TLS certificates
│
├── OPC-UA-SERVER-STATUS.md     # Complete server documentation & status
├── NODE-CONFIGURATION.md       # Detailed node configuration guide
├── PRODUCTION-ACCESS-GUIDE.md  # 🔒 Production access & security guide
├── PRODUCTION-CREDENTIALS.txt  # 🔒 Production credentials (NOT in git)
├── deploy-production.sh        # Production deployment script
│
└── .env.example                # Environment variables template
```

### Excluded Components (Not in Production)

The following components exist in the development environment but are **NOT** actively deployed:

- Monitoring stack (Prometheus, Grafana, Loki, Alertmanager)
- Web stack (Node-RED, Nginx reverse proxy)
- Portainer (removed, SSH management used instead)

## 🔐 Server Modi

Der Server kann in zwei Modi betrieben werden:

### Development Mode (Aktuell)
- ✅ Anonymous Authentication (keine Credentials nötig)
- ⚠️ Schwache Sicherheit
- ✅ Einfaches Testing
- 📝 Konfiguration: `server/docker-compose.yml`

### Production Mode (Empfohlen für echten Betrieb)
- 🔒 Zertifikats-basierte Authentifizierung (wie S7-1500)
- ✅ Security: Basic256Sha256, SignAndEncrypt
- ❌ Keine anonyme Verbindung
- 📝 Konfiguration: `server/docker-compose.production.yml`
- 📖 **Siehe:** [PRODUCTION-ACCESS-GUIDE.md](./PRODUCTION-ACCESS-GUIDE.md)

**Production Mode aktivieren:**
```bash
sudo ./deploy-production.sh
```

---

## Quick Start

### 1. Server Deployment (Development Mode)

```bash
# Clone repository
git clone https://github.com/hansluebken/opcua-server.git
cd opcua-server

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Deploy server
cd server
docker compose up -d
```

### 2. Verify Server Status

```bash
# Check container
docker ps --filter name=opcua

# View logs
docker logs opcua-plc-server

# Test endpoint
curl -v telnet://opcua.netz-fabrik.net:4840 --max-time 5
```

### 3. Client Development

See [OPC-UA-SERVER-STATUS.md](./OPC-UA-SERVER-STATUS.md) for complete client development guide, including:

- Connection examples (Python, Node.js)
- Available nodes and namespaces
- Authentication methods
- Troubleshooting

## Security Configuration

### System Security (Aktiv)

- **Firewall (UFW):** Port 4840 (OPC-UA) and 22 (SSH with rate limiting)
- **Fail2ban:** Active SSH intrusion prevention
- **Kernel Hardening:** SYN flood protection, IP spoofing protection

### OPC-UA Server Security

#### 🟡 Development Mode (Aktuell aktiv)

⚠️ **Nur für Testing und Entwicklung:**
- Anonymous authentication: ✅ ENABLED
- Certificate requirement: ❌ Optional
- Encryption: ❌ Optional
- **Verbindung:** Kein Passwort/Zertifikat nötig

**Verwendung:** Testing, Entwicklung, Demo

#### 🟢 Production Mode (Verfügbar)

✅ **Empfohlen für produktiven Betrieb:**
- Anonymous authentication: ❌ DISABLED
- Certificate requirement: ✅ REQUIRED (X.509)
- Encryption: ✅ SignAndEncrypt (Basic256Sha256)
- **Verbindung:** Client-Zertifikat erforderlich

**Konfiguration wie Siemens S7-1500 OPC-UA Server**

**Aktivieren:**
```bash
sudo ./deploy-production.sh
```

**Dokumentation:**
- 📖 [PRODUCTION-ACCESS-GUIDE.md](./PRODUCTION-ACCESS-GUIDE.md) - Zugangs-Anleitung
- 🔑 [PRODUCTION-CREDENTIALS.txt](./PRODUCTION-CREDENTIALS.txt) - Zugangsdaten

## Service Management

```bash
# Status
systemctl status opcua-server.service
docker ps --filter name=opcua

# Restart
systemctl restart opcua-server.service

# Logs
docker logs -f opcua-plc-server
journalctl -u opcua-server.service -f
```

## Node Configuration

The server provides **85 simulated nodes** across multiple types:

- **Slow Nodes:** 20 nodes (update every 1s, namespace `ns=2;s=Slow.UInt.*`)
- **Fast Nodes:** 50 nodes (update every 10s, namespace `ns=2;s=Fast.UInt.*`)
- **Volatile Nodes:** 10 nodes (on-demand values, namespace `ns=2;s=Volatile.*`)
- **GUID Nodes:** 5 nodes (deterministic GUIDs, namespace `ns=2;s=Guid.*`)

**📖 For detailed node configuration and customization:**
See **[NODE-CONFIGURATION.md](./NODE-CONFIGURATION.md)** for:
- Complete parameter reference
- How to modify node counts, types, and update rates
- Custom node creation via JSON
- Example configurations for different scenarios
- Node discovery and troubleshooting

## Documentation

### Server-Dokumentation

- **[OPC-UA-SERVER-STATUS.md](./OPC-UA-SERVER-STATUS.md)** - Complete server documentation
  - Server access and system credentials
  - Service management
  - Security configuration
  - Python client development guide
  - Troubleshooting

### Node-Konfiguration

- **[NODE-CONFIGURATION.md](./NODE-CONFIGURATION.md)** - Node configuration guide
  - Current node configuration (85 nodes)
  - All command-line parameters explained
  - How to customize nodes (count, type, rate)
  - Custom node creation via JSON
  - Example configurations for different use cases
  - Node discovery and performance tuning

### 🔒 Production Security

- **[PRODUCTION-ACCESS-GUIDE.md](./PRODUCTION-ACCESS-GUIDE.md)** - Production access guide
  - Certificate-based authentication (wie S7-1500)
  - Client-Zertifikat erstellen
  - Python/Node.js/UaExpert Beispiele
  - Security Policies (Basic256Sha256, SignAndEncrypt)
  - Troubleshooting

- **[PRODUCTION-CREDENTIALS.txt](./PRODUCTION-CREDENTIALS.txt)** - Access credentials
  - User-Rollen (Reader, Operator, Admin)
  - Sichere Passwörter
  - ⚠️ NICHT im Git-Repository (lokal aufbewahren!)

## System Requirements

- **OS:** Ubuntu 22.04 LTS or newer
- **Docker:** 20.10+
- **Docker Compose:** v2.0+
- **RAM:** 4GB minimum (server uses ~220MB)
- **Disk:** 10GB minimum

## Installed Software Versions

- **OS:** Ubuntu 22.04.5 LTS
- **Kernel:** 5.15.0-131-generic
- **Docker:** 28.5.1
- **Docker Compose:** v2.40.0
- **OPC-UA Server:** mcr.microsoft.com/iotedge/opc-plc:latest
- **UFW:** 0.36.1
- **Fail2ban:** 0.11.2

## Support

- **OPC-UA PLC Server:** https://github.com/Azure/iot-edge-opc-plc
- **OPC Foundation:** https://opcfoundation.org
- **asyncua (Python):** https://github.com/FreeOpcUa/opcua-asyncio

## License

This configuration is specific to the NETZFABRIK production environment.

---

**Last Updated:** 2025-10-15
**Maintained by:** NETZFABRIK
