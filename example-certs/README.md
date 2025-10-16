# OPC-UA Client-Zertifikate - Beispiele

Dieses Verzeichnis enthält **vorgenerierte Beispiel-Zertifikate** für verschiedene Anwendungsfälle mit dem OPC-UA Server.

## 🔐 Wichtige Konzepte

### Warum separate Zertifikate?

Der OPC-UA Server identifiziert Clients anhand ihrer **Application URI** (aus dem Zertifikat).

**Problem:** Wenn zwei Clients das **gleiche Zertifikat** (= gleiche Application URI) verwenden:
- Der Server erlaubt möglicherweise nur **eine aktive Session** pro Application URI
- Der zweite Client wird abgelehnt oder die erste Session wird geschlossen

**Lösung:** Jede Anwendung sollte ihr **eigenes Zertifikat** mit eindeutiger Application URI haben.

---

## 📋 Verfügbare Zertifikate

### 1. Streamlit / Web-UI Zertifikat

**Dateien:**
- `streamlit-cert.pem` - Client-Zertifikat
- `streamlit-key.pem` - Private Key

**Application URI:** `urn:opcua-monitoring-ui`

**Verwendung:**
```python
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

client = Client("opc.tcp://opcua.netz-fabrik.net:4840")
client.application_uri = "urn:opcua-monitoring-ui"

await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="example-certs/streamlit-cert.pem",
    private_key="example-certs/streamlit-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)

client.set_user("opcua-operator")
client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

async with client:
    print("✅ Verbunden mit Web-UI Zertifikat")
```

**Ideal für:**
- Streamlit Monitoring Dashboards
- Web-basierte Management-UIs
- Interaktive Datenvisualisierung

---

### 2. Data Collector Zertifikat

**Dateien:**
- `data-collector-cert.pem` - Client-Zertifikat
- `data-collector-key.pem` - Private Key

**Application URI:** `urn:opcua-data-collector`

**Verwendung:**
```python
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

client = Client("opc.tcp://opcua.netz-fabrik.net:4840")
client.application_uri = "urn:opcua-data-collector"

await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="example-certs/data-collector-cert.pem",
    private_key="example-certs/data-collector-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)

client.set_user("opcua-operator")
client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

async with client:
    print("✅ Verbunden mit Data Collector Zertifikat")
```

**Ideal für:**
- Permanente Datenerfassung (24/7)
- Datenbank-Schreiber
- Time-Series Data Collection
- Hintergrund-Daemons

---

### 3. Test Client Zertifikat

**Dateien:**
- `test-client-cert.pem` - Client-Zertifikat
- `test-client-key.pem` - Private Key

**Application URI:** `urn:opcua-test-client`

**Verwendung:**
```python
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

client = Client("opc.tcp://opcua.netz-fabrik.net:4840")
client.application_uri = "urn:opcua-test-client"

await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="example-certs/test-client-cert.pem",
    private_key="example-certs/test-client-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)

client.set_user("opcua-reader")
client.set_password("gu/pHCAi1tQ4ekQkPFiGl4wAeimL4SoFvHaFmTmj1S4=")

async with client:
    print("✅ Verbunden mit Test Client Zertifikat")
```

**Ideal für:**
- Entwicklung und Testing
- Ad-hoc Verbindungen
- Debugging
- Einmalige Abfragen

---

## 🔍 Zertifikat-Details

### Streamlit Zertifikat

```
Subject: CN = OPC-UA Monitoring UI, O = Netz-Fabrik, C = DE
Application URI: urn:opcua-monitoring-ui
DNS: localhost, opcua-streamlit
Gültigkeit: 365 Tage
```

### Data Collector Zertifikat

```
Subject: CN = OPC-UA Data Collector, O = Netz-Fabrik, C = DE
Application URI: urn:opcua-data-collector
DNS: localhost, opcua-collector
Gültigkeit: 365 Tage
```

### Test Client Zertifikat

```
Subject: CN = OPC-UA Test Client, O = Netz-Fabrik, C = DE
Application URI: urn:opcua-test-client
DNS: localhost
Gültigkeit: 365 Tage
```

---

## 🎯 Wichtige Erkenntnisse (Server-Setup)

Basierend auf der tatsächlichen Installation:

### Server-Container
- **Name:** `opcua-gateway` (nicht NodeOPCUA-Server)
- **Port:** 4840 (extern)
- **Status:** Läuft mit Healthcheck

### PKI-Pfade (auf dem Server)
- **Vertrauenswürdige Zertifikate:** `/opt/opcua/gateway/gateway-pki/trusted/certs/`
- **Abgelehnte Zertifikate:** `/opt/opcua/gateway/gateway-pki/rejected/certs/`
- **Server-Zertifikat:** `/opt/opcua/gateway/gateway-pki/own/certs/certificate.pem`
- **Server Private Key:** `/opt/opcua/gateway/gateway-pki/own/private/private_key.pem`

### Security-Einstellungen (Production)
```javascript
// NUR sichere Policies erlaubt
securityPolicies: [
    opcua.SecurityPolicy.Basic256Sha256
]

// NUR sichere Modes erlaubt
securityModes: [
    opcua.MessageSecurityMode.Sign,
    opcua.MessageSecurityMode.SignAndEncrypt
]

// Umgebungsvariablen
ALLOW_ANONYMOUS=false                      // ❌ Anonym BLOCKIERT
REQUIRE_CERTIFICATE=true                   // ✅ Zertifikat ERFORDERLICH
automaticallyAcceptUnknownCertificate=true // ✅ Auto-Accept für Testing
```

### Server-Logs überwachen
```bash
# Live-Logs anzeigen
docker logs opcua-gateway -f --tail 100

# Authentifizierungen prüfen
docker logs opcua-gateway 2>&1 | grep -i "authenticated\|denied"

# Zertifikate prüfen
ls -la /opt/opcua/gateway/gateway-pki/trusted/certs/
ls -la /opt/opcua/gateway/gateway-pki/rejected/certs/
```

---

## 🛠️ Eigene Zertifikate erstellen

Falls Sie ein neues Zertifikat für eine andere Anwendung benötigen:

### 1. OpenSSL Config erstellen

```bash
cat > my-app-openssl.cnf <<'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = Meine OPC-UA Anwendung
O = Meine Firma
C = DE

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
URI.1 = urn:mycompany:opcua:myapp
DNS.1 = localhost
DNS.2 = myapp-hostname
EOF
```

### 2. Zertifikat generieren

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout my-app-key.pem \
  -out my-app-cert.pem \
  -days 365 -nodes \
  -config my-app-openssl.cnf \
  -extensions v3_req
```

### 3. Rechte setzen

```bash
chmod 644 my-app-cert.pem
chmod 600 my-app-key.pem
```

### 4. Zertifikat verifizieren

```bash
openssl x509 -in my-app-cert.pem -text -noout | grep -E "Subject:|URI:|DNS:"
```

**Wichtig:** Die **Application URI** muss im `subjectAltName` stehen!

---

## 🚨 Troubleshooting

### Problem: "BadSecurityModeRejected"

**Ursache:** Client versucht ohne Zertifikat zu verbinden

**Lösung:** Immer `set_security()` mit Zertifikat aufrufen:
```python
await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="path/to/cert.pem",
    private_key="path/to/key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
```

### Problem: "Session already exists with this Application URI"

**Ursache:** Zwei Clients verwenden das gleiche Zertifikat

**Lösung:**
1. Stoppen Sie den alten Client
2. ODER verwenden Sie ein anderes Zertifikat mit eindeutiger Application URI

```bash
# Laufende Clients finden
ps aux | grep python | grep opcua

# Client stoppen
kill <PID>
```

### Problem: "Certificate has no SubjectAlternativeName"

**Ursache:** Zertifikat wurde ohne SAN Extension erstellt

**Lösung:** Zertifikat neu generieren mit `-config` und `-extensions v3_req` (siehe oben)

### Problem: Zertifikat in rejected/ statt trusted/

**Ursache:** `automaticallyAcceptUnknownCertificate=false`

**Lösung:**
```bash
# Zertifikat manuell vertrauen
sudo mv /opt/opcua/gateway/gateway-pki/rejected/certs/MY-CERT.pem \
        /opt/opcua/gateway/gateway-pki/trusted/certs/

# Gateway neu starten
docker restart opcua-gateway
```

---

## 📚 Weitere Informationen

- **[ZERTIFIKATE-ERSTELLEN.md](../ZERTIFIKATE-ERSTELLEN.md)** - Vollständige Anleitung zur Zertifikat-Erstellung
- **[CLIENT-ACCESS.md](../CLIENT-ACCESS.md)** - Client-Verbindung und Authentifizierung
- **[S7-PRODUCTION-SETUP.md](../docs/S7-PRODUCTION-SETUP.md)** - Server-Setup und Management

---

## ⚠️ Sicherheitshinweise

1. **Private Keys schützen!**
   ```bash
   chmod 600 *-key.pem
   ```

2. **Niemals in Git committen!**
   ```bash
   echo "*.pem" >> .gitignore
   echo "*.key" >> .gitignore
   ```

3. **Produktions-Zertifikate separat aufbewahren**
   - Diese Beispiel-Zertifikate sind für Testing/Development
   - Für Production: Eigene Zertifikate mit stärkerer Verschlüsselung erstellen

4. **Zertifikate regelmäßig erneuern**
   - Diese Beispiele sind 365 Tage gültig
   - Setzen Sie Erinnerungen für Ablaufdaten

---

**Erstellt:** 2025-10-16
**Server:** opcua.netz-fabrik.net:4840
**Gültig bis:** 2026-10-16 (1 Jahr)
