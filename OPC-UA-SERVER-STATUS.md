# OPC-UA Production Server - Installation Complete

**Server:** opcua.netz-fabrik.net (87.106.33.7)
**Installation Date:** 2025-10-15
**Status:** ✅ Operational & Secured

---

## 1. Server Access

### SSH Access
```bash
ssh root@87.106.33.7
# or
ssh root@opcua.netz-fabrik.net
```

### System Users (credentials in /root/opcua-credentials.txt)
- **opcua-admin** - Full sudo access
- **opcua-operator** - Service management
- **opcua-dev** - Development access

---

## 2. OPC-UA Server Connection

### Endpoints
```
Primary:   opc.tcp://opcua.netz-fabrik.net:4840
IP-based:  opc.tcp://87.106.33.7:4840
```

### Authentication
- **Anonymous:** ✅ Enabled (development mode)
- **Username/Password:** ✅ Enabled
- **Certificate:** ✅ Enabled
- **Auto-Accept Certificates:** ✅ Enabled (development mode)

### Node Configuration
- **Fast Nodes:** 70 (namespace ns=2;s=Fast.UInt.*)
- **GUID Nodes:** 5 (namespace ns=2;s=Guid.*)
- **Bad Nodes:** 2 (error simulation)
- **Update Rate:** 100ms (configurable)
- **Alarms:** ✅ Enabled

---

## 3. Service Management

### Check Status
```bash
systemctl status opcua-server.service
docker ps --filter name=opcua
```

### Control Commands
```bash
# Restart server
systemctl restart opcua-server.service

# Stop server
systemctl stop opcua-server.service

# Start server
systemctl start opcua-server.service

# View logs
docker logs opcua-plc-server
docker logs -f opcua-plc-server  # Follow mode
journalctl -u opcua-server.service -f
```

### Auto-Start
✅ Service is enabled and starts automatically on boot
```bash
# Verify auto-start
systemctl is-enabled opcua-server.service
# Output: enabled
```

---

## 4. Security Configuration

### Firewall (UFW)
```bash
# Status
ufw status numbered

# Active rules:
# [1] SSH (port 22) - LIMIT (rate limiting active)
# [2] OPC-UA (port 4840) - ALLOW
```

### Fail2ban
```bash
# Status
fail2ban-client status

# Check banned IPs
fail2ban-client status sshd

# Current: 2 IPs already blocked
# - 154.50.110.152
# - 165.232.93.231
```

### Kernel Hardening
- SYN flood protection: ✅ Enabled
- IP spoofing protection: ✅ Enabled
- Redirect blocking: ✅ Enabled
- Configuration: /etc/sysctl.d/99-opcua-security.conf

---

## 5. System Resources

### Current Usage
```
RAM:  840 MB used / 3.8 GB total (2.6 GB available)
Disk: 4.5 GB used / 117 GB total (112 GB free)
Load: 0.56 (1 min average)
```

### Docker Resources
```bash
# Container stats
docker stats opcua-plc-server

# Current working set: ~220 MB
```

---

## 6. Directory Structure

```
/opt/opcua/
├── server/               # OPC-UA server configuration
│   ├── docker-compose.yml
│   ├── README.md
│   ├── data/            # PKI certificates (auto-generated)
│   ├── certs/           # Additional certificates
│   ├── logs/            # Server logs
│   └── config/          # Configuration files
│
└── client/
    └── python/          # Python client development
        ├── README.md    # Comprehensive development guide
        └── requirements.txt
```

---

## 7. Python Client Development

### Download Documentation
```bash
# From your local machine:
scp root@87.106.33.7:/opt/opcua/client/python/README.md .
scp root@87.106.33.7:/opt/opcua/client/python/requirements.txt .
```

### Quick Test (Local Development)
```python
import asyncio
from asyncua import Client

async def test_connection():
    url = "opc.tcp://87.106.33.7:4840"
    async with Client(url=url) as client:
        print(f"Connected to {url}")
        namespaces = await client.get_namespace_array()
        print(f"Namespaces: {namespaces}")

asyncio.run(test_connection())
```

**Full documentation:** /opt/opcua/client/python/README.md (387 lines with examples)

---

## 8. Monitoring & Health Checks

### Quick Health Check
```bash
# All-in-one status check
echo "=== Container Status ===" && \
docker ps --filter name=opcua && \
echo -e "\n=== Service Status ===" && \
systemctl status opcua-server.service --no-pager -l && \
echo -e "\n=== Port Check ===" && \
ss -tln | grep 4840 && \
echo -e "\n=== Recent Logs ===" && \
docker logs --tail 10 opcua-plc-server
```

### Expected Output
- Container: "Up X minutes"
- Service: "active (exited)" with Main PID exited successfully
- Port: 0.0.0.0:4840 LISTEN
- Logs: "OPC UA Server started" + simulation metrics

---

## 9. Troubleshooting

### Server Not Responding
```bash
# 1. Check if container is running
docker ps --filter name=opcua

# 2. Check logs for errors
docker logs --tail 100 opcua-plc-server

# 3. Restart service
systemctl restart opcua-server.service

# 4. Verify port is open
nc -zv localhost 4840
```

### Firewall Issues
```bash
# Check if port 4840 is allowed
ufw status | grep 4840

# Test external connectivity
curl -v telnet://87.106.33.7:4840 --max-time 5
# Should show "Connected to 87.106.33.7"
```

### Permission Issues
```bash
# Ensure opcua-operator can run Docker
groups opcua-operator
# Should include: docker

# Check directory permissions
ls -la /opt/opcua/server/
# data, certs, logs should be writable (777)
```

---

## 10. Installed Software Versions

- **OS:** Ubuntu 22.04.5 LTS
- **Kernel:** 5.15.0-131-generic
- **Docker:** 28.5.1
- **Docker Compose:** v2.40.0
- **OPC-UA Server:** mcr.microsoft.com/iotedge/opc-plc:latest
- **UFW:** 0.36.1
- **Fail2ban:** 0.11.2

---

## 11. Important Files

| File | Purpose |
|------|---------|
| /root/opcua-credentials.txt | All system and OPC-UA credentials |
| /opt/opcua/server/docker-compose.yml | OPC-UA server configuration |
| /etc/systemd/system/opcua-server.service | Auto-start service definition |
| /etc/ufw/user.rules | Firewall rules |
| /etc/fail2ban/jail.local | Intrusion prevention config |
| /etc/sysctl.d/99-opcua-security.conf | Kernel security settings |

---

## 12. Next Steps

### For Production Deployment

1. **Disable Development Mode**
   - Disable anonymous authentication
   - Configure username/password authentication
   - Set up certificate-based authentication
   - Disable auto-accept certificates

2. **Configure Monitoring** (Optional - Phase 8)
   - Set up automated backups
   - Configure health monitoring
   - Set up log rotation

3. **SSL/TLS Encryption** (If needed)
   - Install Let's Encrypt certificate
   - Configure OPC-UA with encryption

### For Client Development

1. **Download Client Documentation**
   ```bash
   scp root@87.106.33.7:/opt/opcua/client/python/* ./
   ```

2. **Set Up Local Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   pip install -r requirements.txt
   ```

3. **Test Connection**
   - Use examples from README.md
   - Start with basic connection test
   - Explore available nodes
   - Implement your client logic

---

## 13. Maintenance Commands

### Update OPC-UA Server Image
```bash
cd /opt/opcua/server
docker compose pull
systemctl restart opcua-server.service
```

### View Fail2ban Blocked IPs
```bash
fail2ban-client status sshd
```

### Unban an IP
```bash
fail2ban-client set sshd unbanip <IP_ADDRESS>
```

### System Updates
```bash
apt update && apt upgrade -y
# Reboot if kernel updated
```

---

## 14. Support & Documentation

- **OPC-UA Server Documentation:** /opt/opcua/server/README.md
- **Python Client Guide:** /opt/opcua/client/python/README.md
- **Microsoft OPC PLC:** https://github.com/Azure/iot-edge-opc-plc
- **asyncua Library:** https://github.com/FreeOpcUa/opcua-asyncio
- **OPC Foundation:** https://opcfoundation.org

---

## 15. Installation Summary

✅ **Completed Phases:**
- Phase 1: Base system setup (users, directories, tools)
- Phase 2: Docker & container runtime
- Phase 3: OPC-UA server installation & configuration
- Phase 5: Security hardening (firewall, fail2ban, kernel)
- Phase 7: Python client documentation
- Phase 9: Systemd service configuration
- Phase 10: Testing & validation

⏭️ **Skipped Phases:**
- Phase 4: Web stack (Grafana, Node-RED) - not needed for Python development
- Phase 6: Portainer - removed, SSH sufficient

⏸️ **Optional Phases:**
- Phase 8: Backup & recovery strategy - can be implemented later

---

**Server is ready for OPC-UA client development!**

For questions or issues, review the troubleshooting section or check the detailed documentation in /opt/opcua/.

Last Updated: 2025-10-15 08:20 UTC
