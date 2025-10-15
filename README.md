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
│
└── .env.example                # Environment variables template
```

### Excluded Components (Not in Production)

The following components exist in the development environment but are **NOT** actively deployed:

- Monitoring stack (Prometheus, Grafana, Loki, Alertmanager)
- Web stack (Node-RED, Nginx reverse proxy)
- Portainer (removed, SSH management used instead)

## Quick Start

### 1. Server Deployment

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

Current production security setup:

- **Firewall (UFW):** Port 4840 (OPC-UA) and 22 (SSH with rate limiting)
- **Fail2ban:** Active SSH intrusion prevention
- **Kernel Hardening:** SYN flood protection, IP spoofing protection
- **Docker:** Rootless mode (optional, not yet configured)

### Development Mode Settings

⚠️ **Currently in development mode:**
- Anonymous authentication: ENABLED
- Certificate auto-accept: ENABLED
- Username/password: ENABLED (with weak dev credentials)

**For production:** Disable anonymous authentication and configure proper certificate validation.

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

The server provides the following nodes:

- **Fast Nodes:** 70 nodes (namespace `ns=2;s=Fast.UInt.*`)
- **GUID Nodes:** 5 nodes (namespace `ns=2;s=Guid.*`)
- **Bad Nodes:** 2 nodes (error simulation)
- **Update Rate:** 100ms (configurable)
- **Alarms:** Enabled

## Documentation

- **[OPC-UA-SERVER-STATUS.md](./OPC-UA-SERVER-STATUS.md)** - Complete server documentation
  - Server access and credentials
  - Service management
  - Security configuration
  - Python client development guide
  - Troubleshooting

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
