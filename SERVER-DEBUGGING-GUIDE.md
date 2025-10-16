# OPC-UA Server - Debugging Guide

Praktische Anleitung zum Debuggen von OPC-UA Client-Verbindungen basierend auf der tatsächlichen Server-Installation.

---

## 🎯 Wichtigste Erkenntnisse

### 1. Container und Pfade

**Container-Name:** `opcua-gateway` ⚠️ **NICHT** `NodeOPCUA-Server`

```bash
# Korrekt:
docker logs opcua-gateway -f --tail 100

# Falsch:
docker logs NodeOPCUA-Server -f --tail 100
```

**PKI-Pfade auf dem Server:**

| Typ | Pfad |
|-----|------|
| Vertrauenswürdige Zertifikate | `/opt/opcua/gateway/gateway-pki/trusted/certs/` |
| Abgelehnte Zertifikate | `/opt/opcua/gateway/gateway-pki/rejected/certs/` |
| Server-Zertifikat | `/opt/opcua/gateway/gateway-pki/own/certs/certificate.pem` |
| Server Private Key | `/opt/opcua/gateway/gateway-pki/own/private/private_key.pem` |

⚠️ **NICHT** `/opt/opcua/gateway/gateway/pki/` verwenden!

### 2. Security-Konfiguration

**Aktuelle Einstellungen (Production-Modus):**

```javascript
// Nur sichere Policies erlaubt
securityPolicies: [
    opcua.SecurityPolicy.Basic256Sha256  // ✅ NUR SICHER
]

// Nur sichere Modes erlaubt
securityModes: [
    opcua.MessageSecurityMode.Sign,
    opcua.MessageSecurityMode.SignAndEncrypt  // ✅ NUR SICHER
]
```

**Umgebungsvariablen:**
```bash
ALLOW_ANONYMOUS=false                      # ❌ Anonym BLOCKIERT
REQUIRE_CERTIFICATE=true                   # ✅ Zertifikat ERFORDERLICH
automaticallyAcceptUnknownCertificate=true # ✅ Auto-Accept für Testing
```

**Bedeutung:**
- ✅ **Zertifikate sind PFLICHT**, nicht optional!
- ✅ **Username/Password ist PFLICHT**
- ❌ **Anonyme Verbindungen werden BLOCKIERT**
- ✅ **Neue Zertifikate werden automatisch vertraut** (Testing-Modus)

### 3. Keine Probleme gefunden

- ✅ Keine abgelehnten Zertifikate
- ✅ Viele erfolgreiche Authentifizierungen in den Logs
- ✅ System funktioniert korrekt

---

## 🔍 Debugging-Befehle

### 1. Server-Logs in Echtzeit überwachen

```bash
# Live-Logs anzeigen
docker logs opcua-gateway -f --tail 100

# Authentifizierungen filtern
docker logs opcua-gateway 2>&1 | grep -i "authenticated\|denied" | tail -20

# Session-Events filtern
docker logs opcua-gateway 2>&1 | grep -i "session.*created\|closing session" | tail -20
```

**Was Sie sehen sollten:**
```
✅ User authenticated: opcua-operator
✅ User authenticated: opcua-reader
❌ Authentication failed for user: wrong-user
```

**Fehlermeldungen:**
```
BadSecurityModeRejected          → Client verwendet kein Zertifikat
BadCertificateUntrusted          → Zertifikat nicht vertrauenswürdig
BadUserAccessDenied              → Falsches Passwort
BadIdentityTokenInvalid          → Anonyme Verbindung versucht
```

---

### 2. Zertifikat-Status prüfen

```bash
# Liste der vertrauenswürdigen Zertifikate
ls -la /opt/opcua/gateway/gateway-pki/trusted/certs/

# Aktuell vertrauenswürdige Clients anzeigen
ls -la /opt/opcua/gateway/gateway-pki/trusted/certs/ | grep -v "^d" | wc -l
```

**Erwartetes Ergebnis:**
```
-rw-r--r-- 1 root root 1532 Oct 15 10:19 NodeOPCUA@9ce456d8b988[hash].pem
-rw-r--r-- 1 root root 1293 Oct 15 10:49 OPC-UA Test Client[hash].pem
-rw-r--r-- 1 root root 1191 Oct 15 10:48 TestClient[hash].pem
-rw-r--r-- 1 root root 1512 Oct 15 13:23 opcua-postgres-client[hash].pem
```

Rechte sollten sein: `-rw-r--r--` (644)

---

### 3. Abgelehnte Zertifikate prüfen

```bash
# Rejected-Folder anschauen
ls -la /opt/opcua/gateway/gateway-pki/rejected/certs/

# Falls Zertifikat dort liegt
ls -la /opt/opcua/gateway/gateway-pki/rejected/certs/ | grep -i cert
```

**Falls Zertifikat in "rejected":**

```bash
# Zertifikat ins trusted-Verzeichnis verschieben
sudo mv /opt/opcua/gateway/gateway-pki/rejected/certs/MY-CERT.pem \
        /opt/opcua/gateway/gateway-pki/trusted/certs/

# Gateway neu starten
docker restart opcua-gateway

# Status prüfen
docker logs opcua-gateway --tail 20
```

---

### 4. Server Security-Einstellungen prüfen

```bash
# Umgebungsvariablen anzeigen
docker exec opcua-gateway env | grep -E "ALLOW_ANONYMOUS|REQUIRE_CERTIFICATE"

# Gateway-Code prüfen
docker exec opcua-gateway cat /app/gateway.js | grep -A 10 "securityPolicies:"
```

**Erwartete Ausgabe:**
```bash
ALLOW_ANONYMOUS=false
REQUIRE_CERTIFICATE=true
```

---

### 5. Aktive Sessions prüfen

```bash
# Welche Clients sind verbunden?
docker logs opcua-gateway 2>&1 | grep -i "authenticated" | tail -20

# Session-Timeouts anzeigen
docker logs opcua-gateway 2>&1 | grep -i "closing SESSION" | tail -10
```

**Was bedeutet was:**
```
✅ User authenticated: opcua-operator
   → Client hat sich erfolgreich angemeldet

closing SESSION ... because of timeout
   → Normale Session-Timeout (kein Problem)

Cannot find suitable endpoints
   → Bekannte Warnung (nicht kritisch)
```

---

### 6. Zertifikat-Details analysieren

```bash
# Server-Zertifikat analysieren
openssl x509 -in /opt/opcua/gateway/gateway-pki/own/certs/certificate.pem \
  -text -noout | grep -E "Subject:|Issuer:|URI:|Not Before|Not After"

# Client-Zertifikat analysieren (Beispiel)
openssl x509 -in /opt/opcua/gateway/gateway-pki/trusted/certs/opcua-postgres-client*.pem \
  -text -noout | grep -E "Subject:|Issuer:|URI:|Not Before|Not After"
```

**Erwartete Ausgabe:**
```
Subject: CN = NodeOPCUA@9ce456d8b988
    Not Before: Oct 15 10:19:14 2025 GMT
    Not After : Oct 13 10:19:14 2035 GMT
        URI:urn:9ce456d8b988:NodeOPCUA-Server
```

**Wichtig:** Prüfen Sie:
- ✅ Ist das Zertifikat noch gültig? (Not After Datum)
- ✅ Hat es eine URI im SubjectAlternativeName?
- ✅ Stimmt die Application URI mit dem Client-Code überein?

---

## 🚨 Häufige Probleme und Lösungen

### Problem 1: "Session already exists with this Application URI"

**Ursache:** Zwei Clients verwenden das gleiche Zertifikat (= gleiche Application URI)

**Diagnose:**
```bash
# Laufende Python-Prozesse finden
ps aux | grep python | grep -v grep

# OPC-UA Prozesse finden
pgrep -af opcua
```

**Lösung:**
```bash
# Alten Client stoppen
kill <PID>

# ODER: Separates Zertifikat verwenden
# Siehe example-certs/README.md für vorgenerierte Zertifikate
```

**Bessere Langzeit-Lösung:**
Verwenden Sie separate Zertifikate für verschiedene Anwendungen:
- `example-certs/streamlit-cert.pem` - Für Web-UI
- `example-certs/data-collector-cert.pem` - Für Datensammler
- `example-certs/test-client-cert.pem` - Für Tests

---

### Problem 2: "BadSecurityModeRejected"

**Ursache:** Client versucht ohne Zertifikat zu verbinden

**Diagnose:**
```bash
# Prüfe ob Client set_security() aufruft
grep -n "set_security" your-client-script.py
```

**Lösung:**
```python
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

client = Client("opc.tcp://opcua.netz-fabrik.net:4840")
client.application_uri = "urn:mycompany:opcua:myapp"

# ✅ ERFORDERLICH!
await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="path/to/cert.pem",
    private_key="path/to/key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)

client.set_user("opcua-operator")
client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")
```

---

### Problem 3: "BadCertificateUriInvalid" oder "Certificate has no SubjectAlternativeName"

**Ursache:** Zertifikat wurde ohne SubjectAlternativeName Extension erstellt

**Diagnose:**
```bash
# Zertifikat prüfen
openssl x509 -in my-cert.pem -text -noout | grep -A 5 "Subject Alternative Name"
```

**Sollte zeigen:**
```
X509v3 Subject Alternative Name:
    URI:urn:mycompany:opcua:myapp, DNS:localhost
```

**Falls nicht vorhanden:**
Zertifikat neu erstellen mit `-config` und `-extensions v3_req`:

```bash
cat > my-openssl.cnf <<'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = My OPC-UA Client
O = My Company
C = DE

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
URI.1 = urn:mycompany:opcua:myapp
DNS.1 = localhost
EOF

openssl req -x509 -newkey rsa:2048 \
  -keyout my-key.pem -out my-cert.pem \
  -days 365 -nodes \
  -config my-openssl.cnf \
  -extensions v3_req
```

---

### Problem 4: "BadUserAccessDenied"

**Ursache:** Falsches Passwort oder falscher Username

**Diagnose:**
```bash
# Aktuelle Credentials prüfen
cat PRODUCTION-CREDENTIALS.txt
```

**Gültige Credentials:**
```
opcua-reader   | gu/pHCAi1tQ4ekQkPFiGl4wAeimL4SoFvHaFmTmj1S4=
opcua-operator | ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=
opcua-admin    | O+d5CkM1Gn9SGPKcuy+AThccTIbsCP2Dp/iW5hRXK8U0AllqPOE2bMoq8bEWmYTa
```

**Lösung:**
```python
# Exakt diese Credentials verwenden
client.set_user("opcua-operator")
client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")
```

---

### Problem 5: Gateway startet nicht

**Diagnose:**
```bash
# Container-Status prüfen
docker ps -a | grep opcua-gateway

# Logs anzeigen
docker logs opcua-gateway --tail 50

# Systemd-Service prüfen
systemctl status opcua-gateway.service
```

**Lösung:**
```bash
# Container neu starten
docker restart opcua-gateway

# ODER mit systemd
systemctl restart opcua-gateway.service

# ODER komplett neu erstellen
cd /opt/opcua/gateway
docker compose down
docker compose up -d
```

---

## 📊 Monitoring-Checkliste

Führen Sie diese Checks regelmäßig durch:

### ✅ Tägliche Checks

```bash
# 1. Gateway läuft?
docker ps | grep opcua-gateway

# 2. Aktuelle Authentifizierungen
docker logs opcua-gateway --tail 100 | grep -i "authenticated" | tail -10

# 3. Fehler in letzter Stunde
docker logs opcua-gateway --since 1h 2>&1 | grep -i "error\|failed"
```

### ✅ Wöchentliche Checks

```bash
# 1. Vertrauenswürdige Zertifikate
ls -la /opt/opcua/gateway/gateway-pki/trusted/certs/ | wc -l

# 2. Abgelehnte Zertifikate
ls -la /opt/opcua/gateway/gateway-pki/rejected/certs/

# 3. Disk Space
df -h /opt/opcua/gateway/gateway-pki/

# 4. Zertifikate die bald ablaufen
find /opt/opcua/gateway/gateway-pki/trusted/certs/ -name "*.pem" -exec \
  openssl x509 -in {} -noout -enddate \; 2>/dev/null
```

### ✅ Monatliche Checks

```bash
# 1. Gateway-Logs archivieren
docker logs opcua-gateway > /backup/gateway-logs-$(date +%Y%m%d).log

# 2. Alte Zertifikate aufräumen
# Manuelle Prüfung: Welche Clients sind noch aktiv?

# 3. Passwörter rotieren (alle 90 Tage)
openssl rand -base64 32  # Neues Passwort generieren
```

---

## 🔧 Nützliche Skripte

### Quick Status Check

```bash
#!/bin/bash
# check-opcua-status.sh

echo "=== OPC-UA Gateway Status ==="
echo ""

# Container Status
echo "📦 Container:"
docker ps | grep opcua-gateway && echo "✅ Running" || echo "❌ Stopped"
echo ""

# Letzte Authentifizierungen
echo "🔐 Letzte Logins:"
docker logs opcua-gateway 2>&1 | grep "authenticated" | tail -5
echo ""

# Vertrauenswürdige Zertifikate
echo "📜 Vertrauenswürdige Zertifikate:"
ls /opt/opcua/gateway/gateway-pki/trusted/certs/*.pem 2>/dev/null | wc -l
echo ""

# Abgelehnte Zertifikate
echo "❌ Abgelehnte Zertifikate:"
ls /opt/opcua/gateway/gateway-pki/rejected/certs/*.pem 2>/dev/null | wc -l
echo ""

# Fehler in letzter Stunde
echo "⚠️  Fehler (letzte Stunde):"
docker logs opcua-gateway --since 1h 2>&1 | grep -i "error" | wc -l
```

### Zertifikat-Cleanup

```bash
#!/bin/bash
# cleanup-old-certs.sh

# Zeige alle vertrauenswürdigen Zertifikate mit Ablaufdatum
echo "=== Vertrauenswürdige Zertifikate ==="
for cert in /opt/opcua/gateway/gateway-pki/trusted/certs/*.pem; do
    echo "Datei: $(basename $cert)"
    openssl x509 -in "$cert" -noout -subject -enddate 2>/dev/null
    echo ""
done
```

---

## 📚 Weiterführende Dokumentation

- **[example-certs/README.md](example-certs/README.md)** - Vorgenerierte Zertifikate und Verwendung
- **[ZERTIFIKATE-ERSTELLEN.md](ZERTIFIKATE-ERSTELLEN.md)** - Zertifikat-Erstellung im Detail
- **[CLIENT-ACCESS.md](CLIENT-ACCESS.md)** - Client-Verbindung und Authentifizierung
- **[S7-PRODUCTION-SETUP.md](docs/S7-PRODUCTION-SETUP.md)** - Server-Management und Konfiguration

---

**Erstellt:** 2025-10-16
**Server:** opcua.netz-fabrik.net:4840
**Modus:** Production mit S7-1500-ähnlicher Sicherheit
