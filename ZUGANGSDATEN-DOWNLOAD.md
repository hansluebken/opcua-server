# Zugangsdaten & Zertifikate herunterladen

**Server:** opcua.netz-fabrik.net (87.106.33.7)
**Methode:** SCP (Secure Copy)

---

## 📦 Komplettes Zugangsdatenset herunterladen

### Option 1: Einzelne Dateien (empfohlen)

```bash
# 1. Credentials (Username & Passwords)
scp root@opcua.netz-fabrik.net:/root/dev/opcua-server-repo/PRODUCTION-CREDENTIALS.txt .

# 2. Server-Zertifikat des Gateways (für Client-Validierung)
scp root@opcua.netz-fabrik.net:/opt/opcua/gateway/gateway-pki/own/certs/certificate.pem ./gateway-server-cert.pem

# 3. Dokumentation
scp root@opcua.netz-fabrik.net:/root/dev/opcua-server-repo/CLIENT-ACCESS.md .
scp root@opcua.netz-fabrik.net:/root/dev/opcua-server-repo/ZERTIFIKATE-ERSTELLEN.md .
scp root@opcua.netz-fabrik.net:/root/dev/opcua-server-repo/NODE-CONFIGURATION.md .
```

### Option 2: Komplettes Paket als ZIP

```bash
# Auf dem Server: Paket erstellen
ssh root@opcua.netz-fabrik.net << 'EOF'
cd /tmp
mkdir -p opcua-access-package

# Credentials
cp /root/dev/opcua-server-repo/PRODUCTION-CREDENTIALS.txt opcua-access-package/

# Server-Zertifikat
cp /opt/opcua/gateway/gateway-pki/own/certs/certificate.pem opcua-access-package/gateway-server-cert.pem

# Dokumentation
cp /root/dev/opcua-server-repo/CLIENT-ACCESS.md opcua-access-package/
cp /root/dev/opcua-server-repo/ZERTIFIKATE-ERSTELLEN.md opcua-access-package/
cp /root/dev/opcua-server-repo/NODE-CONFIGURATION.md opcua-access-package/
cp /root/dev/opcua-server-repo/S7-PRODUCTION-SETUP.md opcua-access-package/
cp /root/dev/opcua-server-repo/README.md opcua-access-package/

# ZIP erstellen
zip -r opcua-access-package.zip opcua-access-package/
echo "✅ Paket erstellt: /tmp/opcua-access-package.zip"
EOF

# Lokal: ZIP herunterladen
scp root@opcua.netz-fabrik.net:/tmp/opcua-access-package.zip .

# Entpacken
unzip opcua-access-package.zip
cd opcua-access-package/
```

### Option 3: Git Clone (empfohlen für Entwickler)

```bash
# Repository klonen (enthält Dokumentation + Credentials)
git clone https://github.com/hansluebken/opcua-server.git
cd opcua-server/

# Credentials sind im Repository
cat PRODUCTION-CREDENTIALS.txt

# Server-Zertifikat separat herunterladen
scp root@opcua.netz-fabrik.net:/opt/opcua/gateway/gateway-pki/own/certs/certificate.pem ./gateway-server-cert.pem
```

---

## 📋 Was ist im Zugangsdatenset enthalten?

### 1. PRODUCTION-CREDENTIALS.txt

**Inhalt:**
- 3 User-Rollen (Reader, Operator, Admin)
- Usernames & Passwörter
- Server-Endpoint-URLs

**Beispiel:**
```
╔════════════════════════════════════════════════════════════╗
║   OPC-UA Production Server - Zugangsdaten                  ║
╚════════════════════════════════════════════════════════════╝

Server Endpoint:
  URL:  opc.tcp://opcua.netz-fabrik.net:4840
  IP:   87.106.33.7:4840

User-Rollen:

1. Reader (Nur Lesen)
   Username: opcua-reader
   Password: gu/pHCAi1tQ4ekQkPFiGl4wAeimL4SoFvHaFmTmj1S4=

2. Operator (Lesen & Schreiben)
   Username: opcua-operator
   Password: ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=

3. Admin (Voller Zugriff)
   Username: opcua-admin
   Password: O+d5CkM1Gn9SGPKcuy+AThccTIbsCP2Dp/iW5hRXK8U0AllqPOE2bMoq8bEWmYTa
```

### 2. gateway-server-cert.pem

**Was ist das?**
Das öffentliche Zertifikat des OPC-UA Gateway-Servers.

**Wofür brauche ich das?**
- **Client-seitige Validierung:** Dein Client kann das Server-Zertifikat überprüfen
- **Trusted Certificates:** Du kannst es in deinen Client als "trusted" hinzufügen
- **Nicht zwingend erforderlich:** Gateway akzeptiert auch ohne Client-Validierung (auto-accept aktiv)

**Verwendung (Python asyncua):**
```python
# Optional: Server-Zertifikat explizit vertrauen
client.server_certificate = "gateway-server-cert.pem"
```

### 3. Dokumentation

- **CLIENT-ACCESS.md** - Client-Zugriffs-Anleitung
- **ZERTIFIKATE-ERSTELLEN.md** - Zertifikats-Erstellung (WICHTIG!)
- **NODE-CONFIGURATION.md** - 85 Simulations-Nodes
- **S7-PRODUCTION-SETUP.md** - Server-Management
- **README.md** - Repository-Übersicht

---

## ⚠️ Wichtig: Client-Zertifikate erstellen!

Das heruntergeladene Paket enthält **KEINE Client-Zertifikate** (die musst du selbst erstellen)!

### Warum?

- Jeder Client sollte sein **eigenes** Zertifikat haben (Sicherheit!)
- Client-Zertifikate sind **geheim** und dürfen nicht geteilt werden

### Wie erstelle ich Client-Zertifikate?

Siehe **ZERTIFIKATE-ERSTELLEN.md** für vollständige Anleitung:

**Option 1: Automatisch (Python asyncua)**
```python
# asyncua generiert automatisch
await client.set_security(
    SecurityPolicyBasic256Sha256,
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
```

**Option 2: Manuell (OpenSSL)**
```bash
# Siehe ZERTIFIKATE-ERSTELLEN.md für vollständige Befehle
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem \
  -out client-cert.pem \
  -days 365 \
  -nodes \
  -config opcua-client.cnf \
  -extensions v3_req
```

---

## 🔒 Sicherheitshinweise

### Credentials schützen!

```bash
# Berechtigungen setzen
chmod 600 PRODUCTION-CREDENTIALS.txt
chmod 600 client-key.pem  # (wenn manuell erstellt)

# NIEMALS in öffentliches Git Repository committen!
echo "PRODUCTION-CREDENTIALS.txt" >> .gitignore
echo "client-key.pem" >> .gitignore
echo "*.pem" >> .gitignore
```

### Zugangsdaten aufbewahren

**Empfohlene Struktur:**
```
~/opcua-client/
├── credentials/
│   ├── PRODUCTION-CREDENTIALS.txt       # Username & Passwords
│   ├── gateway-server-cert.pem          # Server-Zertifikat (public)
│   └── .gitignore                       # !! Credentials nicht committen
├── certs/
│   ├── client-cert.pem                  # Dein Client-Zertifikat (public)
│   └── client-key.pem                   # Dein Private Key (GEHEIM!)
├── docs/
│   ├── CLIENT-ACCESS.md
│   ├── ZERTIFIKATE-ERSTELLEN.md
│   └── NODE-CONFIGURATION.md
└── my_client.py                         # Dein Client-Code
```

### Backup erstellen

```bash
# Verschlüsseltes Backup (empfohlen)
tar -czf opcua-credentials-backup.tar.gz opcua-access-package/
gpg -c opcua-credentials-backup.tar.gz  # Verschlüsseln mit Passwort

# Oder: In Passwort-Manager speichern (1Password, LastPass, etc.)
```

---

## 🚀 Quick Start nach Download

### 1. Credentials prüfen

```bash
cat PRODUCTION-CREDENTIALS.txt
# Zeigt: Server-URL, Usernames, Passwords
```

### 2. Client-Zertifikat erstellen

```bash
# Siehe ZERTIFIKATE-ERSTELLEN.md
# ODER: asyncua generiert automatisch
```

### 3. Test-Verbindung (Python)

```python
import asyncio
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

async def test_connection():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.application_uri = "urn:mycompany:opcua:client"

    # Credentials aus PRODUCTION-CREDENTIALS.txt
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    # Zertifikat (asyncua generiert automatisch)
    await client.set_security(
        SecurityPolicyBasic256Sha256,
        mode=ua.MessageSecurityMode.SignAndEncrypt
    )

    async with client:
        print("✅ Verbunden mit OPC-UA Server!")

        # Test: Node lesen
        node = client.get_node("ns=2;s=Fast.UInt.0")
        value = await node.read_value()
        print(f"Fast.UInt.0 = {value}")

asyncio.run(test_connection())
```

---

## 🆘 Troubleshooting

### Problem: "Permission denied" beim SCP

**Ursache:** SSH-Zugriff nicht konfiguriert

**Lösung:**
```bash
# SSH-Key zum Server hinzufügen
ssh-copy-id root@opcua.netz-fabrik.net

# Oder: Password-basierter Login (nicht empfohlen für Production)
scp root@opcua.netz-fabrik.net:/path/to/file .
# Password eingeben
```

### Problem: "File not found" beim SCP

**Ursache:** Pfad existiert nicht oder ist falsch

**Lösung:**
```bash
# Pfad auf Server prüfen
ssh root@opcua.netz-fabrik.net "ls -la /root/dev/opcua-server-repo/PRODUCTION-CREDENTIALS.txt"

# Alternative Pfade:
# - Git-Repo: /root/dev/opcua-server-repo/
# - Gateway: /opt/opcua/gateway/
```

### Problem: "Connection refused"

**Ursache:** SSH-Port blockiert oder Server nicht erreichbar

**Lösung:**
```bash
# Ping testen
ping opcua.netz-fabrik.net

# Port 22 (SSH) testen
nc -zv opcua.netz-fabrik.net 22

# Falls Port 22 blockiert: Anderen SSH-Port verwenden
scp -P 2222 root@opcua.netz-fabrik.net:/path/to/file .
```

---

## 📚 Weiterführende Links

- **GitHub Repository:** https://github.com/hansluebken/opcua-server
- **Client-Zugriff:** CLIENT-ACCESS.md
- **Zertifikate erstellen:** ZERTIFIKATE-ERSTELLEN.md
- **Node-Konfiguration:** NODE-CONFIGURATION.md

---

**Erstellt:** 2025-10-15
**Server:** opcua.netz-fabrik.net (87.106.33.7)
**Zugriff:** SCP, Git Clone
