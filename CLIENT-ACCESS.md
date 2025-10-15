# OPC-UA Client-Zugriffs-Anleitung

**Server:** opcua.netz-fabrik.net:4840 (87.106.33.7:4840)
**Modus:** Production (S7-1500 Security)
**Endpoint:** `opc.tcp://opcua.netz-fabrik.net:4840`

---

## 📋 1. Was brauche ich für den Client-Zugriff?

### Minimal-Anforderungen

Um auf den OPC-UA Server zuzugreifen, benötigst du:

#### ✅ Pflichtangaben

1. **Server-Endpoint-URL**
   ```
   opc.tcp://opcua.netz-fabrik.net:4840
   ```

2. **Username & Password** (einer der drei Rollen)

   | Rolle | Username | Password | Rechte |
   |-------|----------|----------|--------|
   | Reader | `opcua-reader` | `gu/pHCAi1tQ4ekQkPFiGl4wAeimL4SoFvHaFmTmj1S4=` | Nur Lesen |
   | Operator | `opcua-operator` | `ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=` | Lesen & Schreiben |
   | Admin | `opcua-admin` | `O+d5CkM1Gn9SGPKcuy+AThccTIbsCP2Dp/iW5hRXK8U0AllqPOE2bMoq8bEWmYTa` | Voller Zugriff |

   **Quelle:** `PRODUCTION-CREDENTIALS.txt` (lokal auf Server, **NICHT** in Git)

3. **OPC-UA Client-Library**
   - Python: `asyncua` (empfohlen) oder `opcua-client`
   - Node.js: `node-opcua`
   - C#: `OPCFoundation.NetStandard.Opc.Ua`
   - GUI: UaExpert (Unified Automation)

#### 🔒 Optional (für erweiterte Sicherheit)

4. **Client-Zertifikat** (X.509) - wird automatisch erstellt, wenn nicht vorhanden
5. **Security Policy** - `Basic256Sha256` (Standard)
6. **Security Mode** - `SignAndEncrypt` (empfohlen) oder `Sign`

### Zusammenfassung: Daten-Checkliste

```
✅ Endpoint: opc.tcp://opcua.netz-fabrik.net:4840
✅ Username: opcua-operator (oder reader/admin)
✅ Password: ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=
✅ Client-Library: asyncua (Python) / node-opcua (Node.js)
☑️ Zertifikat: Automatisch generiert (optional manuell)
☑️ Security Policy: Basic256Sha256 (optional)
```

---

## 📤 2. Was liefert der Server dem Client?

### Server-Informationen

Beim Verbinden erhältst du:

#### A) Server-Endpoints & Capabilities

```python
# Beispiel: asyncua (Python)
endpoints = await client.get_server_endpoints()

# Liefert:
- Endpoint-URLs
- Supported Security Policies (None, Basic256Sha256)
- Supported Security Modes (None, Sign, SignAndEncrypt)
- Supported Authentication Methods (Username/Password, Certificate)
```

**Beispiel-Rückgabe:**
```
EndpointUrl: opc.tcp://opcua.netz-fabrik.net:4840
SecurityPolicy: http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256
SecurityMode: SignAndEncrypt
UserIdentityTokens:
  - Username/Password
  - X.509 Certificate
```

#### B) Namespaces

Der Server stellt folgende Namespaces bereit:

```python
namespaces = await client.get_namespace_array()

# Liefert:
[
    "http://opcfoundation.org/UA/",           # ns=0 (OPC-UA Standard)
    "urn:OPCUAGateway",                       # ns=1 (Gateway)
    "http://microsoft.com/Opc/OpcPlc/"        # ns=2 (Simulator - via Backend)
]
```

**Wichtig:**
- Namespace 0: OPC-UA Standard-Nodes (Server-Info, etc.)
- Namespace 1: Gateway-eigene Nodes (Status, Info)
- Namespace 2: Simulator-Nodes (**85 Simulations-Nodes**)

#### C) Address Space (Node-Hierarchie)

Beim Browsen der Address Space erhältst du:

```
Root (Objects Folder, ns=0;i=85)
├── Server (ns=0;i=2253) - Server-Informationen
│   ├── ServerStatus
│   ├── ServerCapabilities
│   └── ServerDiagnostics
│
├── Gateway (ns=1) - Gateway-Nodes
│   ├── ServerStatus (String)
│   └── Info (String)
│
└── OpcPlc (ns=2) - Simulator-Nodes (via Backend)
    ├── Telemetry/
    │   ├── Slow/ (20 Nodes)
    │   │   ├── Slow.UInt.0
    │   │   ├── Slow.UInt.1
    │   │   └── ...
    │   ├── Fast/ (50 Nodes)
    │   │   ├── Fast.UInt.0
    │   │   ├── Fast.UInt.1
    │   │   └── ...
    │   ├── Volatile/ (10 Nodes)
    │   └── Guid/ (5 Nodes)
    └── Methods/ (optional)
```

**Hinweis:** Die Backend-Proxy-Integration ist noch nicht vollständig. Aktuell zeigt der Gateway hauptsächlich eigene Nodes. Die Simulator-Nodes sind verfügbar, aber möglicherweise noch nicht vollständig im Gateway-Address-Space gemappt.

#### D) Node-Daten (Values)

Beim Lesen eines Nodes erhältst du:

```python
node = client.get_node("ns=2;s=Fast.UInt.0")
data_value = await node.read_data_value()

# Liefert: DataValue-Objekt mit:
{
    "Value": {
        "Value": 42,                    # Der Wert (z.B. UInt)
        "DataType": "UInt32",           # Datentyp
    },
    "StatusCode": "Good",               # Qualität (Good/Bad/Uncertain)
    "SourceTimestamp": "2025-10-15T10:30:00Z",  # Zeitstempel (Server)
    "ServerTimestamp": "2025-10-15T10:30:00Z"   # Zeitstempel (Server)
}
```

**Verfügbare Datentypen:**
- `UInt` (UInt32) - Fast & Slow Nodes
- `GUID` - GUID Nodes
- `Variant` - Volatile Nodes
- `String` - Info-Nodes

#### E) Node-Metadaten (Attribute)

Jeder Node bietet zusätzliche Attribute:

```python
# NodeId
node_id = await node.read_node_id()
# z.B.: ns=2;s=Fast.UInt.0

# BrowseName
browse_name = await node.read_browse_name()
# z.B.: Fast.UInt.0

# DisplayName
display_name = await node.read_display_name()
# z.B.: Fast UInt 0

# DataType
data_type = await node.read_data_type()
# z.B.: UInt32

# AccessLevel
access_level = await node.read_access_level()
# z.B.: CurrentRead | CurrentWrite

# Description
description = await node.read_description()
# z.B.: "Fast changing node with 10s update rate"
```

### Vollständiges Beispiel: Was bekomme ich?

```python
import asyncio
from asyncua import Client

async def show_server_info():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    async with client:
        # 1. Namespaces
        namespaces = await client.get_namespace_array()
        print(f"Namespaces: {namespaces}")

        # 2. Server-Info
        server_node = client.get_server_node()
        server_name = await server_node.read_display_name()
        print(f"Server: {server_name.Text}")

        # 3. Beispiel-Node lesen
        node = client.get_node("ns=2;s=Fast.UInt.0")
        value = await node.read_value()
        print(f"Fast.UInt.0 = {value}")

        # 4. Node-Metadaten
        display_name = await node.read_display_name()
        data_type = await node.read_data_type_as_variant_type()
        print(f"Node: {display_name.Text}, Type: {data_type}")

asyncio.run(show_server_info())
```

**Erwartete Ausgabe:**
```
Namespaces: ['http://opcfoundation.org/UA/', 'urn:OPCUAGateway', 'http://microsoft.com/Opc/OpcPlc/']
Server: OPC-UA Security Gateway
Fast.UInt.0 = 42
Node: Fast UInt 0, Type: VariantType.UInt32
```

---

## 🔄 3. Kann ich reale OPC-UA Server-Konfigurationen importieren?

### Kurze Antwort

**Ja, teilweise** - es hängt davon ab, was du importieren möchtest:

### Option A: Node-Konfiguration importieren ✅

**WAS:** Du möchtest die **Node-IDs und Struktur** eines realen Servers nachbilden.

**WIE:**

#### 1. Realen Server browsen und Node-Liste exportieren

**Mit UaExpert:**
1. Verbinde zu realem Server
2. Address Space → Rechtsklick auf Folder → "Export to NodeSet2"
3. Speichert `.xml` mit allen Nodes

**Mit Python (asyncua):**
```python
import asyncio
from asyncua import Client
import json

async def export_nodes(real_server_url):
    """Exportiere Node-Liste von realem Server"""
    client = Client(url=real_server_url)

    async with client:
        # Root-Objekte durchsuchen
        objects = client.get_objects_node()
        children = await objects.get_children()

        nodes_list = []

        for child in children:
            node_id = child.nodeid.to_string()
            browse_name = await child.read_browse_name()
            data_type = await child.read_data_type_as_variant_type()

            nodes_list.append({
                "nodeId": node_id,
                "browseName": browse_name.Name,
                "dataType": str(data_type)
            })

        # Als JSON speichern
        with open("real_server_nodes.json", "w") as f:
            json.dump(nodes_list, f, indent=2)

        print(f"✅ {len(nodes_list)} Nodes exportiert")

# Beispiel: Siemens S7-1500
asyncio.run(export_nodes("opc.tcp://192.168.1.100:4840"))
```

#### 2. Simulator mit Custom Nodes konfigurieren

**Microsoft OPC PLC Simulator unterstützt:**

A) **JSON-basierte Custom Nodes** (ab Version 2.9.0):

```json
// custom_nodes.json
{
  "Nodes": [
    {
      "NodeId": "ns=2;s=MyMachine.Temperature",
      "Name": "Temperature",
      "DataType": "Double",
      "Value": 25.5,
      "AccessLevel": "CurrentRead"
    },
    {
      "NodeId": "ns=2;s=MyMachine.Pressure",
      "Name": "Pressure",
      "DataType": "Float",
      "Value": 1013.25,
      "AccessLevel": "CurrentReadOrWrite"
    }
  ]
}
```

**Simulator starten mit Custom Nodes:**
```yaml
# docker-compose.yml
services:
  opcua-simulator:
    command: >
      --pn=4841
      --autoaccept
      --nodesfile=/app/config/custom_nodes.json
    volumes:
      - ./custom_nodes.json:/app/config/custom_nodes.json:ro
```

B) **NodeSet2 XML Import** (Standard OPC-UA Format):

Der Microsoft OPC PLC Simulator kann **NodeSet2 XML** importieren:

```yaml
services:
  opcua-simulator:
    command: >
      --pn=4841
      --autoaccept
      --nodeset=/app/config/real_server_nodeset.xml
    volumes:
      - ./real_server_nodeset.xml:/app/config/real_server_nodeset.xml:ro
```

**Beispiel NodeSet2 XML:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<UANodeSet xmlns="http://opcfoundation.org/UA/2011/03/UANodeSet.xsd">
  <NamespaceUris>
    <Uri>http://yourcompany.com/OpcUa/</Uri>
  </NamespaceUris>
  <UAVariable NodeId="ns=2;s=MyMachine.Temperature" BrowseName="Temperature" DataType="Double">
    <DisplayName>Temperature</DisplayName>
    <References>
      <Reference ReferenceType="HasComponent" IsForward="false">ns=2;i=1000</Reference>
    </References>
    <Value>
      <Double>25.5</Double>
    </Value>
  </UAVariable>
</UANodeSet>
```

**Quellen für NodeSet2-Dateien:**
- UaExpert: Export → NodeSet2 XML
- Reale S7-1500: OPC-UA Configurator (TIA Portal)
- OPC Foundation: Companion Specifications (z.B. PackML, EUROMAP)

#### 3. Gateway anpassen (optional)

Falls du die Nodes auch im Gateway sichtbar machen möchtest:

**gateway/gateway.js** - Backend-Nodes im Gateway-AddressSpace mappen:

```javascript
async function constructAddressSpace(server) {
    const addressSpace = server.engine.addressSpace;
    const namespace = addressSpace.getOwnNamespace();

    // Backend-Nodes browsen
    const browseResult = await backendSession.browse("ns=0;i=85"); // Objects folder

    for (const ref of browseResult.references) {
        const nodeId = ref.nodeId.toString();

        // Backend-Node lesen
        const dataValue = await backendSession.read({
            nodeId: nodeId,
            attributeId: opcua.AttributeIds.Value
        });

        // Im Gateway-AddressSpace erstellen (Proxy-Node)
        namespace.addVariable({
            browseName: ref.browseName.name,
            nodeId: nodeId,
            dataType: dataValue.value.dataType,
            value: {
                get: async function() {
                    // Live-Read vom Backend
                    const val = await backendSession.readVariableValue(nodeId);
                    return new opcua.Variant(val);
                }
            }
        });
    }
}
```

### Option B: Security-Konfiguration importieren ✅

**WAS:** Du möchtest die **Sicherheitseinstellungen** (Policies, User-Rollen) eines realen Servers übernehmen.

**WIE:**

#### 1. User-Rollen anpassen

**gateway/gateway.js** - Zeile 113-132:

```javascript
userManager: {
    isValidUser: function(userName, password) {
        // ✏️ Hier eigene User-Datenbank einbinden

        const users = {
            // Beispiel: Siemens S7-1500 User
            "s7admin": "hash_of_s7admin_password",
            "s7operator": "hash_of_s7operator_password",
            "s7viewer": "hash_of_s7viewer_password",

            // Oder: Externe Auth (LDAP, OAuth)
            // return await ldap.authenticate(userName, password);
        };

        return users[userName] === password;
    }
}
```

**Passwörter hashen:**
```bash
# Base64-encoded SHA256
echo -n "YourPassword" | sha256sum | awk '{print $1}' | xxd -r -p | base64
```

#### 2. Security Policies anpassen

**gateway/gateway.js** - Zeile 98-107:

```javascript
securityPolicies: [
    opcua.SecurityPolicy.None,                    // Für Testing
    opcua.SecurityPolicy.Basic256Sha256,          // S7-1500 Standard
    opcua.SecurityPolicy.Aes128_Sha256_RsaOaep,   // Für höhere Sicherheit
    opcua.SecurityPolicy.Aes256_Sha256_RsaPss,    // Maximum Security
],

securityModes: [
    opcua.MessageSecurityMode.Sign,               // Nur Signatur
    opcua.MessageSecurityMode.SignAndEncrypt,     // S7-Standard
],
```

#### 3. Zertifikats-Validierung konfigurieren

**gateway/gateway.js** - Zeile 138-141:

```javascript
serverCertificateManager: new opcua.OPCUACertificateManager({
    // ✏️ Für Production: NUR trusted Certificates akzeptieren
    automaticallyAcceptUnknownCertificate: false,  // false = nur trusted
    rootFolder: PKI_FOLDER
})
```

**Trusted Certificates manuell hinzufügen:**
```bash
# Client-Zertifikat zum Gateway hinzufügen
cp client-cert.pem /opt/opcua/gateway/gateway/pki/trusted/certs/

# Gateway neu starten
cd /opt/opcua/gateway
docker compose restart opcua-gateway
```

### Option C: Vollständiger Server-Ersatz 🚫 (Nicht empfohlen)

**WAS:** Du möchtest den gesamten Gateway+Simulator durch einen anderen Server ersetzen.

**ALTERNATIVEN:**

1. **Prosys OPC UA Simulation Server** (kommerziell)
   - Volle Konfigurierbarkeit
   - NodeSet2 Import
   - User-Management
   - https://www.prosysopc.com/products/opc-ua-simulation-server/

2. **open62541-based Server** (Open Source)
   - C-basiert, sehr konfigurierbar
   - NodeSet Compiler
   - https://github.com/open62541/open62541

3. **Node-RED mit node-red-contrib-opcua** (Low-Code)
   - Grafische Konfiguration
   - Custom Logic möglich
   - https://flows.nodered.org/node/node-red-contrib-opcua

4. **Echter Siemens S7-1500** (Hardware)
   - Wenn verfügbar, native S7 OPC-UA Server nutzen

---

## 🔌 4. Verbindungs-Beispiele

### Python (asyncua)

#### Einfaches Lesen

```python
import asyncio
from asyncua import Client

async def read_node():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    async with client:
        # Node lesen
        node = client.get_node("ns=2;s=Fast.UInt.0")
        value = await node.read_value()
        print(f"Wert: {value}")

asyncio.run(read_node())
```

#### Mehrere Nodes lesen

```python
async def read_multiple():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    async with client:
        # Mehrere Nodes
        node_ids = [
            "ns=2;s=Fast.UInt.0",
            "ns=2;s=Fast.UInt.1",
            "ns=2;s=Slow.UInt.0",
        ]

        nodes = [client.get_node(nid) for nid in node_ids]
        values = await asyncio.gather(*[n.read_value() for n in nodes])

        for nid, val in zip(node_ids, values):
            print(f"{nid} = {val}")

asyncio.run(read_multiple())
```

#### Node schreiben

```python
async def write_node():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.set_user("opcua-operator")  # Braucht Write-Rechte!
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    async with client:
        node = client.get_node("ns=2;s=Fast.UInt.0")

        # Wert schreiben
        await node.write_value(100)
        print("✅ Wert geschrieben")

        # Lesen zur Verifikation
        value = await node.read_value()
        print(f"Neuer Wert: {value}")

asyncio.run(write_node())
```

### Node.js (node-opcua)

```javascript
const opcua = require("node-opcua");

async function connect() {
    const client = opcua.OPCUAClient.create({
        applicationName: "MyClient",
    });

    const endpointUrl = "opc.tcp://opcua.netz-fabrik.net:4840";

    await client.connect(endpointUrl);
    console.log("✅ Verbunden!");

    // Session mit Credentials
    const userIdentity = {
        userName: "opcua-operator",
        password: "ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU="
    };

    const session = await client.createSession(userIdentity);
    console.log("✅ Session erstellt!");

    // Node lesen
    const dataValue = await session.readVariableValue("ns=2;s=Fast.UInt.0");
    console.log("Wert:", dataValue.value.value);

    await session.close();
    await client.disconnect();
}

connect().catch(console.error);
```

### UaExpert (GUI)

1. **Server hinzufügen:**
   - Custom Discovery → `opc.tcp://opcua.netz-fabrik.net:4840`

2. **Verbindung konfigurieren:**
   - Security Policy: `Basic256Sha256` (oder `None` für Testing)
   - Security Mode: `SignAndEncrypt` (oder `Sign`)
   - Authentication: **Username/Password**
     - Username: `opcua-operator`
     - Password: `ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=`

3. **Verbinden und Browsen:**
   - Address Space → Objects → Gateway / OpcPlc
   - Nodes in Data Access View ziehen für Live-Monitoring

---

## 🆘 5. Troubleshooting

### Problem: "BadUserAccessDenied"

**Ursache:** Falsche oder fehlende Credentials

**Lösung:**
```python
# Credentials korrekt setzen
client.set_user("opcua-operator")
client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")
```

### Problem: "BadIdentityTokenInvalid"

**Ursache:** Anonyme Verbindung versucht, aber blockiert

**Lösung:** Username/Password setzen (siehe oben)

### Problem: "Connection timeout"

**Ursache:** Server nicht erreichbar oder Firewall

**Lösung:**
```bash
# Port-Check
nc -zv opcua.netz-fabrik.net 4840

# Ping
ping opcua.netz-fabrik.net

# Server-Status (auf Server)
docker ps --filter name=opcua
```

### Problem: "No matching endpoint"

**Ursache:** Security Policy nicht unterstützt

**Lösung:** Verfügbare Endpoints auflisten:
```python
from asyncua import Client

client = Client("opc.tcp://opcua.netz-fabrik.net:4840")
endpoints = await client.connect_and_get_server_endpoints()

for ep in endpoints:
    print(f"Policy: {ep.SecurityPolicyUri}")
    print(f"Mode: {ep.SecurityMode}")
```

### Problem: Keine Nodes sichtbar

**Hinweis:** Backend-Proxy-Integration noch nicht vollständig.

**Lösung:** Bei Bedarf direkt zum Simulator verbinden (nur intern vom Server):
```
opc.tcp://opcua-simulator:4841
```

---

## 📚 6. Weitere Ressourcen

- **S7-PRODUCTION-SETUP.md** - Server-Administration, Troubleshooting
- **NODE-CONFIGURATION.md** - Details zu allen 85 Nodes
- **asyncua Doku:** https://github.com/FreeOpcUa/opcua-asyncio
- **node-opcua Doku:** https://github.com/node-opcua/node-opcua
- **OPC Foundation:** https://opcfoundation.org
- **NodeSet Compiler:** https://github.com/open62541/open62541/tree/master/tools/nodeset_compiler

---

**Erstellt:** 2025-10-15
**Server:** opcua.netz-fabrik.net:4840
**Modus:** Production (S7-1500 Security)
