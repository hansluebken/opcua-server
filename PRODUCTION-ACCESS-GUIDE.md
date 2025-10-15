# OPC-UA Production Server - Zugangs-Anleitung

**Server:** opcua.netz-fabrik.net:4840
**IP:** 87.106.33.7:4840
**Security:** Zertifikats-basiert (wie Siemens S7-1500)

---

## ⚠️ Wichtige Hinweise

### Authentifizierung wie bei echten S7-Servern

Dieser Server ist konfiguriert wie ein **Siemens S7-1500 OPC-UA Server**:

✅ **Zertifikats-basierte Authentifizierung** (X.509 Certificates)
✅ **Verschlüsselte Kommunikation** (Sign & Encrypt)
✅ **Security Policy: Basic256Sha256**
❌ **Keine anonyme Verbindung möglich**

### Unterschied zu Development-Modus

| Feature | Development | Production (aktuell) |
|---------|-------------|----------------------|
| Anonymous Auth | ✅ Erlaubt | ❌ Blockiert |
| Zertifikate | Optional | ✅ Erforderlich |
| Verschlüsselung | Optional | ✅ Erforderlich |
| Auto-Accept Certs | ✅ Ja | ✅ Ja (für Testing) |

---

## 📋 Was du brauchst

1. **Client-Zertifikat** (X.509)
2. **Private Key** für dein Zertifikat
3. **OPC-UA Client** (Python, Node.js, UaExpert, etc.)
4. **Server-Endpoint:** `opc.tcp://opcua.netz-fabrik.net:4840`

### Optional (für erweiterte Authentifizierung):
- Username/Password aus `PRODUCTION-CREDENTIALS.txt` (nur mit zusätzlichem Gateway)

---

## 🔐 Schritt 1: Zertifikat erstellen

### Option A: OpenSSL (Linux/Mac/Windows mit WSL)

```bash
# Selbstsigniertes Zertifikat für OPC-UA Client erstellen
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem \
  -out client-cert.pem \
  -days 365 \
  -nodes \
  -subj "/CN=OPC-UA-Client/O=YourCompany/C=DE/L=YourCity"

# Prüfen
ls -la client-*.pem
# Sollte anzeigen:
# client-cert.pem (öffentliches Zertifikat)
# client-key.pem  (privater Schlüssel)
```

**Wichtig:** Bewahre `client-key.pem` sicher auf! Dies ist dein privater Schlüssel.

### Option B: UaExpert generiert automatisch

UaExpert erstellt beim ersten Start automatisch ein Zertifikat für dich.

### Option C: Python asyncua generiert automatisch

Die asyncua-Library erstellt automatisch Zertifikate, wenn keine vorhanden sind.

---

## 🔧 Schritt 2: Verbindung herstellen

### Python (asyncua) - EMPFOHLEN

#### Installation

```bash
pip install asyncua
```

#### Beispiel 1: Einfache Verbindung mit Auto-Generated Zertifikat

```python
import asyncio
from asyncua import Client

async def connect_to_opcua():
    # Endpoint URL
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    # Client erstellen
    client = Client(url=url)

    # Sicherheitseinstellungen wie S7-1500
    client.set_security_string(
        "Basic256Sha256,SignAndEncrypt,client-cert.pem,client-key.pem"
    )

    try:
        # Verbinden
        await client.connect()
        print("✅ Verbunden mit OPC-UA Server")

        # Namespaces anzeigen
        namespaces = await client.get_namespace_array()
        print(f"Namespaces: {namespaces}")

        # Node lesen
        node = client.get_node("ns=2;s=Fast.UInt.0")
        value = await node.read_value()
        print(f"Fast.UInt.0 = {value}")

    finally:
        await client.disconnect()

# Ausführen
asyncio.run(connect_to_opcua())
```

#### Beispiel 2: Mit automatisch generiertem Zertifikat (einfachste Methode)

```python
import asyncio
from asyncua import Client
from pathlib import Path

async def connect_simple():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    # asyncua erstellt automatisch Zertifikate im Verzeichnis
    cert_dir = Path.home() / ".opcua_client_certs"
    cert_dir.mkdir(exist_ok=True)

    client = Client(url=url)

    # asyncua generiert Zertifikate automatisch
    await client.set_security_string(
        "Basic256Sha256,SignAndEncrypt"
    )

    async with client:
        print("✅ Verbunden!")

        # Alle Nodes in namespace 2 durchsuchen
        objects = client.get_objects_node()
        children = await objects.get_children()

        for child in children:
            try:
                name = await child.read_browse_name()
                print(f"Node: {name.Name}")
            except:
                pass

asyncio.run(connect_simple())
```

#### Beispiel 3: Vollständiges Monitoring-Script

```python
import asyncio
from asyncua import Client
from asyncua.ua import MessageSecurityMode, SecurityPolicy
import logging

logging.basicConfig(level=logging.INFO)

class OPCUAMonitor:
    def __init__(self, url):
        self.url = url
        self.client = None

    async def connect(self):
        """Verbindung mit Production-Security herstellen"""
        self.client = Client(self.url)

        # Security wie S7-1500
        self.client.set_security(
            SecurityPolicy.Basic256Sha256,
            certificate_path="client-cert.pem",
            private_key_path="client-key.pem",
            mode=MessageSecurityMode.SignAndEncrypt
        )

        await self.client.connect()
        print("✅ Verbunden mit OPC-UA Server (Production Mode)")

    async def read_nodes(self, node_ids):
        """Mehrere Nodes gleichzeitig lesen"""
        nodes = [self.client.get_node(nid) for nid in node_ids]
        values = await asyncio.gather(*[n.read_value() for n in nodes])

        return dict(zip(node_ids, values))

    async def monitor_loop(self):
        """Kontinuierliches Monitoring"""
        node_ids = [
            "ns=2;s=Fast.UInt.0",
            "ns=2;s=Fast.UInt.1",
            "ns=2;s=Slow.UInt.0",
        ]

        try:
            while True:
                values = await self.read_nodes(node_ids)

                print("\n" + "="*50)
                for node_id, value in values.items():
                    print(f"{node_id}: {value}")

                await asyncio.sleep(2)

        except KeyboardInterrupt:
            print("\nMonitoring beendet")

    async def disconnect(self):
        if self.client:
            await self.client.disconnect()

async def main():
    monitor = OPCUAMonitor("opc.tcp://opcua.netz-fabrik.net:4840")

    try:
        await monitor.connect()
        await monitor.monitor_loop()
    finally:
        await monitor.disconnect()

if __name__ == "__main__":
    asyncio.run(main())
```

---

### Node.js (node-opcua)

#### Installation

```bash
npm install node-opcua node-opcua-client
```

#### Beispiel: Sichere Verbindung

```javascript
const opcua = require("node-opcua");
const fs = require("fs");

async function connectSecure() {
    const client = opcua.OPCUAClient.create({
        applicationName: "NodeOPCUA-Client",
        connectionStrategy: opcua.makeConnectionStrategy(),

        // Security Settings wie S7
        securityMode: opcua.MessageSecurityMode.SignAndEncrypt,
        securityPolicy: opcua.SecurityPolicy.Basic256Sha256,

        // Zertifikat laden
        certificateFile: "client-cert.pem",
        privateKeyFile: "client-key.pem",

        endpointMustExist: false,
    });

    const endpointUrl = "opc.tcp://opcua.netz-fabrik.net:4840";

    try {
        await client.connect(endpointUrl);
        console.log("✅ Verbunden mit OPC-UA Server (Production)");

        const session = await client.createSession();
        console.log("✅ Session erstellt");

        // Node lesen
        const dataValue = await session.readVariableValue("ns=2;s=Fast.UInt.0");
        console.log("Fast.UInt.0 =", dataValue.value.value);

        // Mehrere Nodes lesen
        const nodesToRead = [
            "ns=2;s=Fast.UInt.0",
            "ns=2;s=Fast.UInt.1",
            "ns=2;s=Slow.UInt.0"
        ];

        const values = await session.read(nodesToRead.map(nodeId => ({
            nodeId: nodeId,
            attributeId: opcua.AttributeIds.Value
        })));

        values.forEach((v, i) => {
            console.log(`${nodesToRead[i]} = ${v.value.value}`);
        });

        await session.close();
        await client.disconnect();

    } catch (err) {
        console.error("❌ Fehler:", err.message);
    }
}

connectSecure();
```

---

### UaExpert (GUI Client)

#### 1. UaExpert herunterladen

https://www.unified-automation.com/downloads/opc-ua-clients.html

#### 2. Zertifikat konfigurieren

1. **Settings → Manage Certificates**
2. **Trust "opc.tcp://opcua.netz-fabrik.net:4840" Server Zertifikat**
3. UaExpert erstellt automatisch Client-Zertifikat

#### 3. Server hinzufügen

1. **Server → Add → Custom Discovery**
2. **URL:** `opc.tcp://opcua.netz-fabrik.net:4840`
3. **Security Policy:** `Basic256Sha256`
4. **Message Security Mode:** `Sign & Encrypt`
5. **Verbinden**

#### 4. Nodes durchsuchen

- Address Space → Objects → OpcPlc → Telemetry
- Namespace 2 enthält alle Nodes
- Drag & Drop in Data Access View für Monitoring

---

## 🔒 Security Policies erklärt

### Wie bei Siemens S7-1500

| Policy | Verschlüsselung | Signatur | Empfehlung |
|--------|-----------------|----------|------------|
| **None** | ❌ | ❌ | ❌ Nicht für Production |
| **Basic128Rsa15** | 128-bit | SHA1 | ⚠️ Veraltet |
| **Basic256** | 256-bit | SHA1 | ⚠️ Veraltet |
| **Basic256Sha256** | 256-bit | SHA256 | ✅ **EMPFOHLEN** |
| **Aes128_Sha256_RsaOaep** | AES128 | SHA256 | ✅ Gut |
| **Aes256_Sha256_RsaPss** | AES256 | SHA256 | ✅ Beste |

**Unser Server:** Basic256Sha256 (Standard bei S7-1500)

### Message Security Modes

| Mode | Beschreibung | Verwendung |
|------|--------------|------------|
| **None** | Keine Sicherheit | ❌ Entwicklung only |
| **Sign** | Nur Signatur | ⚠️ Akzeptabel |
| **SignAndEncrypt** | Signatur + Verschlüsselung | ✅ **PRODUCTION** |

---

## 🧪 Verbindung testen

### Quick Test Script (Python)

Erstelle `test_connection.py`:

```python
#!/usr/bin/env python3
import asyncio
from asyncua import Client

async def test():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    print(f"Teste Verbindung zu {url}...")

    client = Client(url=url)

    # Mit automatischem Zertifikat
    await client.set_security_string("Basic256Sha256,SignAndEncrypt")

    try:
        await client.connect()
        print("✅ Verbindung erfolgreich!")

        # Server-Info
        server_info = await client.get_server_node().read_display_name()
        print(f"Server: {server_info.Text}")

        # Namespaces
        ns = await client.get_namespace_array()
        print(f"Namespaces: {ns}")

        # Test-Node lesen
        node = client.get_node("ns=2;s=Fast.UInt.0")
        value = await node.read_value()
        print(f"Test-Node (Fast.UInt.0): {value}")

        await client.disconnect()
        print("✅ Test erfolgreich!")

    except Exception as e:
        print(f"❌ Fehler: {e}")
        return False

    return True

if __name__ == "__main__":
    success = asyncio.run(test())
    exit(0 if success else 1)
```

Ausführen:

```bash
chmod +x test_connection.py
python3 test_connection.py
```

---

## ❓ Troubleshooting

### Problem: "BadSecurityChecksFailed"

**Ursache:** Zertifikat wird nicht akzeptiert

**Lösung:**
```python
# In Python: Server-Zertifikat manuell akzeptieren
# Das Server-Zertifikat wird beim ersten Connect in ~/.opcua gespeichert
# Du musst es als "trusted" markieren
```

Oder: Server mit `--autoaccept` läuft bereits (ist der Fall).

### Problem: "Connection timeout"

**Ursache:** Firewall oder Server nicht erreichbar

**Lösung:**
```bash
# Port-Check
nc -zv opcua.netz-fabrik.net 4840

# Ping
ping opcua.netz-fabrik.net

# Server-Status prüfen (auf Server)
docker ps --filter name=opcua
docker logs opcua-server
```

### Problem: "No matching endpoint"

**Ursache:** Security Policy nicht unterstützt

**Lösung:**
```python
# Liste alle verfügbaren Endpoints
from asyncua import Client

client = Client("opc.tcp://opcua.netz-fabrik.net:4840")
endpoints = await client.connect_and_get_server_endpoints()

for ep in endpoints:
    print(f"Endpoint: {ep.EndpointUrl}")
    print(f"  Security: {ep.SecurityPolicyUri}")
    print(f"  Mode: {ep.SecurityMode}")
```

### Problem: Certificate-Fehler

**Lösung 1:** Zertifikate neu erstellen
```bash
rm -rf ~/.opcua_client_certs
# asyncua erstellt neue beim nächsten Connect
```

**Lösung 2:** Explizites Zertifikat verwenden
```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem -out client-cert.pem \
  -days 365 -nodes \
  -subj "/CN=MyClient/O=Company"
```

---

## 📊 Verfügbare Nodes

Der Server stellt **85 Nodes** bereit:

### Slow Nodes (20 Stück)
```
ns=2;s=Slow.UInt.0
ns=2;s=Slow.UInt.1
...
ns=2;s=Slow.UInt.19
```
**Update-Rate:** 1 Sekunde

### Fast Nodes (50 Stück)
```
ns=2;s=Fast.UInt.0
ns=2;s=Fast.UInt.1
...
ns=2;s=Fast.UInt.49
```
**Update-Rate:** 10 Sekunden

### Volatile Nodes (10 Stück)
```
ns=2;s=Volatile.0
...
ns=2;s=Volatile.9
```
**Update:** On-Demand (bei jedem Read)

### GUID Nodes (5 Stück)
```
ns=2;s=Guid.0
...
ns=2;s=Guid.4
```

**Siehe auch:** [NODE-CONFIGURATION.md](./NODE-CONFIGURATION.md)

---

## 🔐 Username/Password Authentication (Optional)

### ⚠️ Wichtiger Hinweis

Der Microsoft OPC PLC Server unterstützt **KEINE** nativen Username/Password-Kombinationen.

Für echte Username/Password-Authentifizierung wie bei S7 benötigst du:

### Option 1: OPC-UA Gateway (EMPFOHLEN)

Verwende einen Gateway/Proxy vor dem Server:

- **Prosys OPC UA Gateway**
- **Industrial Gateway OPC UA**
- **Nginx mit OPC-UA Plugin**

Der Gateway validiert Username/Password und leitet zum OPC-Server weiter.

### Option 2: Produktiven OPC-UA Server verwenden

Wechsel zu einem Server mit voller Auth-Unterstützung:

- **Prosys OPC UA Simulation Server** (kommerziell)
- **open62541-based Server** (Open Source, konfigurierbar)
- **Echter S7-1500 OPC-UA Server** (Hardware)

### Credentials (für zukünftigen Gateway)

Siehe `PRODUCTION-CREDENTIALS.txt` für:
- opcua-reader (Read-Only)
- opcua-operator (Read/Write)
- opcua-admin (Full Access)

---

## 📚 Weiterführende Links

- **asyncua Dokumentation:** https://github.com/FreeOpcUa/opcua-asyncio
- **node-opcua Dokumentation:** https://github.com/node-opcua/node-opcua
- **OPC Foundation:** https://opcfoundation.org
- **Siemens S7-1500 OPC UA:** https://support.industry.siemens.com

---

## 📞 Support

Bei Problemen:

1. Prüfe Firewall-Regeln (Port 4840)
2. Prüfe Server-Status: `docker ps --filter name=opcua`
3. Prüfe Server-Logs: `docker logs opcua-server`
4. Siehe: [OPC-UA-SERVER-STATUS.md](./OPC-UA-SERVER-STATUS.md)

---

**Erstellt:** 2025-10-15
**Server:** opcua.netz-fabrik.net (87.106.33.7)
**Security:** Production Mode (Certificate-Based)
