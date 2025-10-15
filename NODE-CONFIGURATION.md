# OPC-UA Server Node Configuration

Diese Dokumentation beschreibt die aktuell konfigurierten Nodes auf dem OPC-UA Server und wie sie angepasst werden können.

## Aktuelle Node-Konfiguration

Basierend auf `server/docker-compose.yml`:

```yaml
command: >
  --pn=50000
  --ph=opcua-server
  --sn=20           # Slow Nodes
  --sr=1            # Slow Rate
  --st=uint         # Slow Type
  --fn=50           # Fast Nodes
  --fr=10           # Fast Rate
  --ft=uint         # Fast Type
  --vn=10           # Volatile Nodes
  --gn=5            # GUID Nodes
  --autoaccept=false
  --certdnsnames=opcua.netz-fabrik.net
  --certipaddrs=87.106.33.7
  --at=X509
  --aa              # Anonymous Authentication
```

### Übersicht der konfigurierten Nodes

| Node-Typ | Anzahl | Update-Rate | Datentyp | Namespace | Node-ID Pattern |
|----------|--------|-------------|----------|-----------|-----------------|
| **Slow Nodes** | 20 | 1 Sekunde | UInt | ns=2 | `ns=2;s=Slow.UInt.0` bis `ns=2;s=Slow.UInt.19` |
| **Fast Nodes** | 50 | 10 Sekunden | UInt | ns=2 | `ns=2;s=Fast.UInt.0` bis `ns=2;s=Fast.UInt.49` |
| **Volatile Nodes** | 10 | Variable | - | ns=2 | `ns=2;s=Volatile.*` |
| **GUID Nodes** | 5 | - | Mixed | ns=2 | `ns=2;s=Guid.*` (deterministisch) |

**Gesamt: 85 Nodes**

---

## Node-Typen im Detail

### 1. Slow Nodes (`--sn`, `--sr`, `--st`)

**Zweck:** Nodes mit langsamer Änderungsrate, typisch für Prozesswerte die sich selten ändern.

**Aktuelle Konfiguration:**
- `--sn=20` - 20 Slow Nodes
- `--sr=1` - Update alle **1 Sekunde**
- `--st=uint` - Datentyp: **Unsigned Integer**

**Node-IDs:**
```
ns=2;s=Slow.UInt.0
ns=2;s=Slow.UInt.1
...
ns=2;s=Slow.UInt.19
```

**Verfügbare Optionen:**
```bash
--sn, --slownodes <zahl>              # Anzahl (default: 1)
--sr, --slowrate <sekunden>           # Update-Rate (default: 10)
--st, --slowtype <typ>                # Datentyp (UInt, Double, Bool, UIntArray)
--stl, --slowtypelowerbound <wert>    # Untere Grenze
--stu, --slowtypeupperbound <wert>    # Obere Grenze
--str, --slowtyperandomization        # Zufallswerte aktivieren
--sts, --slowtypestepsize <wert>      # Inkrement-Schrittgröße (default: 1)
```

**Beispiel-Anpassung:**
```yaml
--sn=30              # 30 Slow Nodes
--sr=5               # Update alle 5 Sekunden
--st=double          # Double-Werte
--stl=0              # Minimum: 0
--stu=100            # Maximum: 100
--str                # Zufallswerte
```

---

### 2. Fast Nodes (`--fn`, `--fr`, `--ft`)

**Zweck:** Nodes mit schneller Änderungsrate, typisch für hochfrequente Sensordaten.

**Aktuelle Konfiguration:**
- `--fn=50` - 50 Fast Nodes
- `--fr=10` - Update alle **10 Sekunden**
- `--ft=uint` - Datentyp: **Unsigned Integer**

**Node-IDs:**
```
ns=2;s=Fast.UInt.0
ns=2;s=Fast.UInt.1
...
ns=2;s=Fast.UInt.49
```

**Verfügbare Optionen:**
```bash
--fn, --fastnodes <zahl>              # Anzahl (default: 1)
--fr, --fastrate <sekunden>           # Update-Rate (default: 1)
--ft, --fasttype <typ>                # Datentyp (UInt, Double, Bool, UIntArray)
--ftl, --fasttypelowerbound <wert>    # Untere Grenze
--ftu, --fasttypeupperbound <wert>    # Obere Grenze
--ftr, --fasttyperandomization        # Zufallswerte aktivieren
--fts, --fasttypestepsize <wert>      # Inkrement-Schrittgröße
```

**Beispiel-Anpassung:**
```yaml
--fn=100             # 100 Fast Nodes
--fr=1               # Update jede Sekunde
--ft=double          # Double-Werte
--ftl=-50            # Minimum: -50
--ftu=150            # Maximum: 150
--ftr                # Zufallswerte
```

---

### 3. Volatile Nodes (`--vn`)

**Zweck:** Nodes die bei jedem Lesen einen neuen Wert generieren.

**Aktuelle Konfiguration:**
- `--vn=10` - 10 Volatile Nodes

**Node-IDs:**
```
ns=2;s=Volatile.0
ns=2;s=Volatile.1
...
ns=2;s=Volatile.9
```

**Verhalten:** Diese Nodes generieren bei jedem Read-Request einen neuen Wert, unabhängig von Update-Zyklen.

---

### 4. GUID Nodes (`--gn`)

**Zweck:** Nodes mit deterministischen GUID-basierten Node-IDs.

**Aktuelle Konfiguration:**
- `--gn=5` - 5 GUID Nodes

**Node-IDs:**
```
ns=2;s=Guid.0
ns=2;s=Guid.1
...
ns=2;s=Guid.4
```

**Besonderheit:** Verwenden deterministische GUIDs als Node-Identifier.

---

## Verfügbare Datentypen

| Typ | Beschreibung | Beispielwert |
|-----|--------------|--------------|
| `UInt` | Unsigned Integer (32-bit) | 0 - 4294967295 |
| `Double` | Double-Precision Float | -1.7E+308 bis 1.7E+308 |
| `Bool` | Boolean | true / false |
| `UIntArray` | Array von UInts | [1, 2, 3, ...] |

---

## Erweiterte Konfiguration

### Custom Nodes via JSON

Für komplexe Node-Strukturen kann eine JSON-Datei verwendet werden:

```bash
--nodesfile=/app/config/custom-nodes.json
```

**Beispiel `custom-nodes.json`:**
```json
{
  "Folder": "MyCustomNodes",
  "NodeList": [
    {
      "NodeId": "ns=2;s=Temperature",
      "Name": "Temperature",
      "Description": "Current temperature",
      "DataType": "Double",
      "AccessLevel": "CurrentRead",
      "MinValue": -40,
      "MaxValue": 120,
      "StepSize": 0.5,
      "UpdateRate": 1000
    },
    {
      "NodeId": "ns=2;s=Pressure",
      "Name": "Pressure",
      "Description": "System pressure",
      "DataType": "Double",
      "AccessLevel": "CurrentRead",
      "MinValue": 0,
      "MaxValue": 10,
      "StepSize": 0.1,
      "UpdateRate": 2000
    }
  ]
}
```

### NodeSet2 XML Import

Für Standardkonforme Node-Definitionen:

```bash
--ns2=/app/config/nodeset2.xml
```

---

## Node-Konfiguration ändern

### 1. Docker Compose Methode (Empfohlen)

Editiere `server/docker-compose.yml`:

```yaml
services:
  opcua-server:
    command: >
      --pn=50000
      --ph=opcua-server
      --sn=30              # ← Geändert: 30 statt 20
      --sr=2               # ← Geändert: Update alle 2 Sekunden
      --st=double          # ← Geändert: Double statt UInt
      --fn=100             # ← Geändert: 100 statt 50
      --fr=1               # ← Geändert: Update jede Sekunde
      --ft=double          # ← Geändert: Double statt UInt
      --vn=10
      --gn=5
      ...
```

**Anwenden:**
```bash
cd /opt/opcua/server
docker compose down
docker compose up -d

# Oder mit systemd
systemctl restart opcua-server.service
```

### 2. Direkt über Docker Run

```bash
docker run -d \
  -p 4840:50000 \
  --name opcua-server \
  mcr.microsoft.com/iotedge/opc-plc:latest \
  --pn=50000 \
  --sn=50 --sr=2 --st=double \
  --fn=100 --fr=1 --ft=double \
  --gn=10 \
  --aa
```

---

## Beispiel-Konfigurationen

### Szenario 1: Hochfrequente Sensoren

Für IoT-Anwendungen mit schnellen Sensoren:

```yaml
--sn=10 --sr=5 --st=double --stl=0 --stu=100 --str
--fn=200 --fr=0.1 --ft=double --ftl=-50 --ftu=150 --ftr
--gn=20
```

**Ergebnis:**
- 10 Slow Nodes (alle 5s, Zufallswerte 0-100)
- 200 Fast Nodes (alle 0.1s = 100ms, Zufallswerte -50 bis 150)
- 20 GUID Nodes

### Szenario 2: Produktionslinie

Für Manufacturing/SCADA:

```yaml
--sn=50 --sr=10 --st=uint --stl=0 --stu=1000
--fn=20 --fr=1 --ft=double
--vn=5
--gn=5
```

**Ergebnis:**
- 50 Slow Nodes (Zählerwerte 0-1000)
- 20 Fast Nodes (Messwerte, jede Sekunde)
- 5 Volatile Nodes (On-Demand Werte)
- 5 GUID Nodes

### Szenario 3: Entwicklung/Testing

Für Entwickler:

```yaml
--sn=5 --sr=1 --st=uint
--fn=10 --fr=1 --ft=uint
--vn=3
--gn=2
```

**Ergebnis:** Minimal-Setup mit 20 Nodes total

---

## Node Discovery

### Via Python Client

```python
from asyncua import Client
import asyncio

async def discover_nodes():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    async with Client(url=url) as client:
        # Root-Ordner durchsuchen
        root = client.get_root_node()
        objects = await root.get_child(["0:Objects"])

        # Alle Child-Nodes
        children = await objects.get_children()

        for child in children:
            node_id = child.nodeid.to_string()
            browse_name = await child.read_browse_name()
            print(f"Node: {node_id} - {browse_name.Name}")

        # Spezifische Namespace durchsuchen
        # Namespace 2 enthält die simulierten Nodes
        nodes = await objects.get_children_descriptions(refs=2)

        for node in nodes:
            print(f"NS2 Node: {node.BrowseName.Name}")

asyncio.run(discover_nodes())
```

### Via UaExpert

1. Verbindung zu `opc.tcp://opcua.netz-fabrik.net:4840` herstellen
2. Address Space durchsuchen
3. Namespace 2 enthält alle simulierten Nodes
4. Ordnerstruktur:
   ```
   Objects/
   └── OpcPlc/
       └── Telemetry/
           ├── Fast/
           ├── Slow/
           ├── Guid/
           └── Volatile/
   ```

---

## Node-Performance

### Update-Raten optimieren

**Regel:** Je höher die Update-Rate, desto mehr Last auf Server und Netzwerk.

| Nodes | Update-Rate | CPU-Last | Netzwerk-Last | Empfehlung |
|-------|-------------|----------|---------------|------------|
| 100 | 1s | Niedrig | Niedrig | ✅ Optimal für meiste Anwendungen |
| 500 | 1s | Mittel | Mittel | ⚠️ Monitoring empfohlen |
| 1000 | 0.1s | Hoch | Hoch | ❌ Nur für High-Performance Setup |

**Aktuelle Konfiguration:**
- 70 Nodes mit Updates (20 slow @ 1s + 50 fast @ 10s)
- **CPU-Last:** Niedrig (~5-10% auf 2-Core-System)
- **RAM:** ~220 MB
- **Netzwerk:** Minimal

---

## Troubleshooting

### Nodes werden nicht angezeigt

```bash
# 1. Server-Logs prüfen
docker logs opcua-server

# 2. Namespace-Array prüfen (Python)
async with Client(url) as client:
    ns = await client.get_namespace_array()
    print(f"Namespaces: {ns}")
    # Erwartung: ['http://opcfoundation.org/UA/', 'http://microsoft.com/Opc/OpcPlc/', ...]
```

### Nodes ändern sich nicht

- Prüfe Update-Rate (`--sr`, `--fr`)
- Prüfe ob Randomization aktiviert ist (`--str`, `--ftr`)
- Prüfe Step-Size (`--sts`, `--fts`)

### Performance-Probleme

```bash
# Container-Ressourcen prüfen
docker stats opcua-server

# Reduziere Node-Anzahl oder Update-Raten
# Editiere docker-compose.yml und restart
```

---

## Weiterführende Ressourcen

- **Microsoft OPC PLC Dokumentation:** https://github.com/Azure-Samples/iot-edge-opc-plc
- **OPC Foundation Specs:** https://opcfoundation.org/developer-tools/specifications-unified-architecture
- **asyncua Python Client:** https://github.com/FreeOpcUa/opcua-asyncio

---

**Erstellt:** 2025-10-15
**Version:** 1.0
**Server:** opcua.netz-fabrik.net
