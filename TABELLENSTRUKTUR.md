# OPC-UA Server - Tabellenstruktur für Datenerfassung

**Server:** opcua.netz-fabrik.net:4840
**Simulierte Daten:** 85 Nodes (20 Slow, 50 Fast, 10 Volatile, 5 GUID)

---

## 📊 Übersicht der simulierten Daten

| Node-Typ | Anzahl | Update-Rate | Datentyp | Wertebereich | Node-ID Beispiel |
|----------|--------|-------------|----------|--------------|------------------|
| **Slow Nodes** | 20 | 1 Sekunde | UInt32 | 0 - 4.294.967.295 | `ns=2;s=Slow.UInt.0` |
| **Fast Nodes** | 50 | 10 Sekunden | UInt32 | 0 - 4.294.967.295 | `ns=2;s=Fast.UInt.0` |
| **Volatile Nodes** | 10 | On-Demand | Variant | Variable | `ns=2;s=Volatile.0` |
| **GUID Nodes** | 5 | Deterministisch | GUID | UUID Format | `ns=2;s=Guid.0` |

**Gesamt:** 85 Datenpunkte

---

## 🗂️ Tabellenstruktur: Haupttabelle (Time-Series Daten)

### Tabelle: `opcua_timeseries`

Speichert alle Zeit-Serien Daten von den OPC-UA Nodes.

| Spalte | Datentyp | Nullable | Beschreibung | Beispielwert |
|--------|----------|----------|--------------|--------------|
| **id** | BIGINT | NOT NULL | Eindeutige ID (Primary Key) | 1, 2, 3, ... |
| **node_id** | VARCHAR(100) | NOT NULL | OPC-UA Node-ID | `ns=2;s=Fast.UInt.0` |
| **node_name** | VARCHAR(100) | NOT NULL | Lesbarer Name | `Fast.UInt.0` |
| **value_uint** | BIGINT | NULL | Wert für UInt32 Nodes | 1234 |
| **value_double** | DOUBLE | NULL | Wert für Double/Float Nodes | 123.45 |
| **value_string** | TEXT | NULL | Wert für String/GUID Nodes | `a1b2c3d4-...` |
| **value_bool** | BOOLEAN | NULL | Wert für Boolean Nodes | true / false |
| **status_code** | VARCHAR(20) | NOT NULL | Datenqualität | `Good`, `Bad`, `Uncertain` |
| **source_timestamp** | TIMESTAMP | NOT NULL | Zeitstempel vom OPC-UA Server | `2025-10-15 10:30:00` |
| **server_timestamp** | TIMESTAMP | NOT NULL | Zeitstempel vom Gateway | `2025-10-15 10:30:00` |
| **collected_at** | TIMESTAMP | NOT NULL | Zeitstempel vom Client | `2025-10-15 10:30:01` |

**Hinweis:** Pro Zeile wird nur **eine** der `value_*` Spalten gefüllt (je nach Datentyp).

---

## 🗂️ Tabellenstruktur: Node-Metadaten (optional)

### Tabelle: `opcua_nodes`

Speichert Metadaten über die konfigurierten Nodes.

| Spalte | Datentyp | Nullable | Beschreibung | Beispielwert |
|--------|----------|----------|--------------|--------------|
| **node_id** | VARCHAR(100) | NOT NULL | OPC-UA Node-ID (Primary Key) | `ns=2;s=Fast.UInt.0` |
| **node_name** | VARCHAR(100) | NOT NULL | Lesbarer Name | `Fast.UInt.0` |
| **node_type** | VARCHAR(20) | NOT NULL | Typ | `slow`, `fast`, `volatile`, `guid` |
| **data_type** | VARCHAR(20) | NOT NULL | Datentyp | `UInt32`, `GUID`, `Variant` |
| **update_rate_sec** | INT | NULL | Update-Rate in Sekunden | 1 (Slow), 10 (Fast), NULL (On-Demand) |
| **namespace_index** | INT | NOT NULL | OPC-UA Namespace | 2 |
| **description** | TEXT | NULL | Beschreibung | `Slow changing node, updates every 1 second` |

---

## 📋 Musterdaten (CSV-Format)

### Beispiel: Slow Nodes

```csv
id,node_id,node_name,value_uint,status_code,source_timestamp,server_timestamp,collected_at
1,ns=2;s=Slow.UInt.0,Slow.UInt.0,1234,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
2,ns=2;s=Slow.UInt.0,Slow.UInt.0,1235,Good,2025-10-15 10:00:01,2025-10-15 10:00:01,2025-10-15 10:00:02
3,ns=2;s=Slow.UInt.0,Slow.UInt.0,1236,Good,2025-10-15 10:00:02,2025-10-15 10:00:02,2025-10-15 10:00:03
4,ns=2;s=Slow.UInt.1,Slow.UInt.1,5678,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
5,ns=2;s=Slow.UInt.1,Slow.UInt.1,5679,Good,2025-10-15 10:00:01,2025-10-15 10:00:01,2025-10-15 10:00:02
```

### Beispiel: Fast Nodes

```csv
id,node_id,node_name,value_uint,status_code,source_timestamp,server_timestamp,collected_at
1,ns=2;s=Fast.UInt.0,Fast.UInt.0,42,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
2,ns=2;s=Fast.UInt.0,Fast.UInt.0,43,Good,2025-10-15 10:00:10,2025-10-15 10:00:10,2025-10-15 10:00:11
3,ns=2;s=Fast.UInt.0,Fast.UInt.0,44,Good,2025-10-15 10:00:20,2025-10-15 10:00:20,2025-10-15 10:00:21
4,ns=2;s=Fast.UInt.1,Fast.UInt.1,100,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
5,ns=2;s=Fast.UInt.1,Fast.UInt.1,101,Good,2025-10-15 10:00:10,2025-10-15 10:00:10,2025-10-15 10:00:11
```

### Beispiel: GUID Nodes

```csv
id,node_id,node_name,value_string,status_code,source_timestamp,server_timestamp,collected_at
1,ns=2;s=Guid.0,Guid.0,a1b2c3d4-e5f6-7890-abcd-ef1234567890,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
2,ns=2;s=Guid.1,Guid.1,b2c3d4e5-f6a7-8901-bcde-f12345678901,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
3,ns=2;s=Guid.2,Guid.2,c3d4e5f6-a7b8-9012-cdef-123456789012,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
```

---

## 📊 Vollständige Node-Liste (85 Nodes)

### Slow Nodes (20)

```
ns=2;s=Slow.UInt.0   -> Update alle 1 Sekunde
ns=2;s=Slow.UInt.1
ns=2;s=Slow.UInt.2
ns=2;s=Slow.UInt.3
ns=2;s=Slow.UInt.4
ns=2;s=Slow.UInt.5
ns=2;s=Slow.UInt.6
ns=2;s=Slow.UInt.7
ns=2;s=Slow.UInt.8
ns=2;s=Slow.UInt.9
ns=2;s=Slow.UInt.10
ns=2;s=Slow.UInt.11
ns=2;s=Slow.UInt.12
ns=2;s=Slow.UInt.13
ns=2;s=Slow.UInt.14
ns=2;s=Slow.UInt.15
ns=2;s=Slow.UInt.16
ns=2;s=Slow.UInt.17
ns=2;s=Slow.UInt.18
ns=2;s=Slow.UInt.19
```

### Fast Nodes (50)

```
ns=2;s=Fast.UInt.0   -> Update alle 10 Sekunden
ns=2;s=Fast.UInt.1
ns=2;s=Fast.UInt.2
...
ns=2;s=Fast.UInt.47
ns=2;s=Fast.UInt.48
ns=2;s=Fast.UInt.49
```

### Volatile Nodes (10)

```
ns=2;s=Volatile.0    -> Ändert sich bei jedem Read
ns=2;s=Volatile.1
ns=2;s=Volatile.2
ns=2;s=Volatile.3
ns=2;s=Volatile.4
ns=2;s=Volatile.5
ns=2;s=Volatile.6
ns=2;s=Volatile.7
ns=2;s=Volatile.8
ns=2;s=Volatile.9
```

### GUID Nodes (5)

```
ns=2;s=Guid.0        -> Deterministischer GUID
ns=2;s=Guid.1
ns=2;s=Guid.2
ns=2;s=Guid.3
ns=2;s=Guid.4
```

---

## 💡 Verwendungshinweise

### Datentyp-Mapping

Abhängig vom Node-Typ wird nur **eine** der `value_*` Spalten verwendet:

| Node-Typ | Verwendete Spalte | SQL Bedingung |
|----------|-------------------|---------------|
| Slow Nodes | `value_uint` | `value_uint IS NOT NULL` |
| Fast Nodes | `value_uint` | `value_uint IS NOT NULL` |
| Volatile Nodes | `value_uint` oder andere | je nach Variant |
| GUID Nodes | `value_string` | `value_string IS NOT NULL` |

### Status Codes

| Status Code | Bedeutung | Verwendung |
|-------------|-----------|------------|
| `Good` | Daten sind valide | Normalfall, 99% der Werte |
| `Bad` | Daten sind ungültig | Verbindungsfehler, Node nicht erreichbar |
| `Uncertain` | Daten sind unsicher | Sensor-Problem, alte Daten |

### Timestamps

**Drei verschiedene Zeitstempel:**

1. **source_timestamp**: Zeitstempel vom OPC-UA Server (= wann wurde der Wert erzeugt?)
2. **server_timestamp**: Zeitstempel vom Gateway (= wann wurde der Wert empfangen?)
3. **collected_at**: Zeitstempel vom Client (= wann wurde der Wert in DB geschrieben?)

**Normalfall:** Alle drei sind fast identisch (Unterschied < 1 Sekunde)

---

## 📈 Typische Datenmengen

### Pro Tag

| Node-Typ | Updates/Tag | Datenpunkte (20/50/10/5 Nodes) |
|----------|-------------|--------------------------------|
| Slow (1s) | 86.400 | **1.728.000** (20 Nodes) |
| Fast (10s) | 8.640 | **432.000** (50 Nodes) |
| Volatile | Variable | Variable (On-Demand) |
| GUID | Variable | Variable |

**Gesamt pro Tag:** ~2.160.000 Datenpunkte (nur Slow + Fast)

### Speicherbedarf (Schätzung)

**Pro Datenpunkt:** ~150 Bytes (durchschnittlich)

- 1 Tag: ~324 MB
- 1 Woche: ~2,3 GB
- 1 Monat: ~9,7 GB
- 1 Jahr: ~118 GB

**Empfehlung:** Alte Daten nach 90 Tagen archivieren oder löschen.

---

## 🔍 Beispiel-Abfragen (konzeptionell)

### Letzter Wert eines Nodes

```
SELECT * FROM opcua_timeseries
WHERE node_id = 'ns=2;s=Fast.UInt.0'
ORDER BY source_timestamp DESC
LIMIT 1
```

### Alle Werte der letzten Stunde

```
SELECT * FROM opcua_timeseries
WHERE source_timestamp >= JETZT - 1 STUNDE
ORDER BY source_timestamp DESC
```

### Durchschnitt pro Node (letzte 24h)

```
SELECT
    node_id,
    COUNT(*) AS anzahl_werte,
    AVG(value_uint) AS durchschnitt,
    MIN(value_uint) AS minimum,
    MAX(value_uint) AS maximum
FROM opcua_timeseries
WHERE source_timestamp >= JETZT - 24 STUNDEN
  AND value_uint IS NOT NULL
GROUP BY node_id
```

### Alle "Bad" Status Codes

```
SELECT * FROM opcua_timeseries
WHERE status_code = 'Bad'
ORDER BY source_timestamp DESC
```

---

## 📦 CSV-Export Format

### Standard-Export

```csv
node_id,node_name,value,status_code,timestamp
ns=2;s=Slow.UInt.0,Slow.UInt.0,1234,Good,2025-10-15T10:00:00
ns=2;s=Slow.UInt.0,Slow.UInt.0,1235,Good,2025-10-15T10:00:01
ns=2;s=Fast.UInt.0,Fast.UInt.0,42,Good,2025-10-15T10:00:00
ns=2;s=Guid.0,Guid.0,a1b2c3d4-e5f6-7890-abcd-ef1234567890,Good,2025-10-15T10:00:00
```

### Erweitert (mit allen Timestamps)

```csv
node_id,value,status_code,source_timestamp,server_timestamp,collected_at
ns=2;s=Slow.UInt.0,1234,Good,2025-10-15 10:00:00,2025-10-15 10:00:00,2025-10-15 10:00:01
ns=2;s=Slow.UInt.0,1235,Good,2025-10-15 10:00:01,2025-10-15 10:00:01,2025-10-15 10:00:02
```

---

**Erstellt:** 2025-10-15
**Server:** opcua.netz-fabrik.net:4840
**Nodes:** 85 Simulierte Datenpunkte
