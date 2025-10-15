# Client-Zertifikate für OPC-UA erstellen

**Server:** opcua.netz-fabrik.net:4840
**Erforderlich:** Zertifikate sind PFLICHT (nicht optional!)

---

## ⚠️ Wichtig: Zertifikate sind ERFORDERLICH!

Seit der Sicherheitskonfiguration vom 2025-10-15 erzwingt der Gateway **zertifikatsbasierte Authentifizierung**:

✅ **Security Policy:** Basic256Sha256 (PFLICHT)
✅ **Security Mode:** Sign oder SignAndEncrypt (PFLICHT)
❌ **Keine unsicheren Verbindungen:** SecurityPolicy.None und MessageSecurityMode.None sind BLOCKIERT

**Du kannst NICHT ohne Zertifikat verbinden!**

---

## 🔐 Option 1: Automatisch generiertes Zertifikat (Python asyncua)

Die einfachste Methode - asyncua erstellt automatisch ein Zertifikat:

```python
import asyncio
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

async def connect_with_auto_cert():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.application_uri = "urn:mycompany:opcua:client"  # WICHTIG!
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    # asyncua generiert automatisch ein Zertifikat
    await client.set_security(
        SecurityPolicyBasic256Sha256,
        mode=ua.MessageSecurityMode.SignAndEncrypt
    )

    await client.connect()
    print("✅ Verbunden!")

    await client.disconnect()

asyncio.run(connect_with_auto_cert())
```

**Vorteile:**
- Keine manuelle Zertifikats-Erstellung nötig
- Funktioniert sofort

**Nachteile:**
- Zertifikat wird bei jedem Start neu erstellt
- Nicht für Production geeignet (da nicht wiederverwendbar)

---

## 🔐 Option 2: Eigenes Zertifikat erstellen (OpenSSL)

### Schritt 1: OpenSSL-Konfiguration erstellen

```bash
cat > opcua-client.cnf <<'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = Mein OPC-UA Client
O = Meine Firma
C = DE

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
URI.1 = urn:mycompany:opcua:client
DNS.1 = localhost
DNS.2 = opcua.netz-fabrik.net
EOF
```

**Wichtig:**
- `URI.1` muss mit `client.application_uri` übereinstimmen!
- `CN` (Common Name) = Dein Client-Name
- `O` (Organization) = Deine Firma
- `DNS.2` = Server-Hostname (opcua.netz-fabrik.net)

### Schritt 2: Zertifikat generieren

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem \
  -out client-cert.pem \
  -days 365 \
  -nodes \
  -config opcua-client.cnf \
  -extensions v3_req
```

**Ergebnis:**
- `client-cert.pem` - Öffentliches Zertifikat
- `client-key.pem` - Privater Schlüssel (GEHEIM HALTEN!)

### Schritt 3: Zertifikat verifizieren

```bash
# SubjectAlternativeName prüfen (MUSS vorhanden sein!)
openssl x509 -in client-cert.pem -text -noout | grep -A 3 "Subject Alternative Name"

# Sollte zeigen:
# X509v3 Subject Alternative Name:
#     URI:urn:mycompany:opcua:client, DNS:localhost, DNS:opcua.netz-fabrik.net
```

**Wichtig:** Wenn "Subject Alternative Name" fehlt, funktioniert die Verbindung NICHT!

### Schritt 4: Mit Zertifikat verbinden (Python)

```python
import asyncio
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

async def connect_with_cert():
    url = "opc.tcp://opcua.netz-fabrik.net:4840"

    client = Client(url=url)
    client.application_uri = "urn:mycompany:opcua:client"  # MUSS mit URI im Zertifikat übereinstimmen!
    client.set_user("opcua-operator")
    client.set_password("ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=")

    # Mit eigenem Zertifikat
    await client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate="client-cert.pem",
        private_key="client-key.pem",
        mode=ua.MessageSecurityMode.SignAndEncrypt
    )

    await client.connect()
    print("✅ Verbunden mit eigenem Zertifikat!")

    # Beispiel: Node lesen
    node = client.get_node("ns=2;s=Fast.UInt.0")
    value = await node.read_value()
    print(f"Fast.UInt.0 = {value}")

    await client.disconnect()

asyncio.run(connect_with_cert())
```

---

## 🔐 Option 3: UaExpert (GUI Client)

UaExpert erstellt automatisch ein Zertifikat beim ersten Start.

### Schritt 1: UaExpert herunterladen
https://www.unified-automation.com/downloads/opc-ua-clients.html

### Schritt 2: Server hinzufügen
1. **Custom Discovery** → `opc.tcp://opcua.netz-fabrik.net:4840`
2. **Endpoints** anzeigen

### Schritt 3: Sicheren Endpoint wählen
- **Security Policy:** `Basic256Sha256`
- **Security Mode:** `SignAndEncrypt` (empfohlen) oder `Sign`
- **Authentication:** `Username & Password`
  - Username: `opcua-operator`
  - Password: `ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=`

### Schritt 4: Zertifikat trust

en (beim ersten Connect)
1. UaExpert zeigt Server-Zertifikat → **Trust** klicken
2. Server akzeptiert Client-Zertifikat automatisch (auto-accept ist aktiv)

### Schritt 5: Verbinden
- Klicke **Connect**
- ✅ Verbunden!

---

## 🆘 Troubleshooting

### Problem: "BadSecurityModeRejected"

**Ursache:** Du versuchst ohne Zertifikat zu verbinden (z.B. mit SecurityPolicy.None)

**Lösung:** Zertifikatsbasierte Verbindung verwenden (siehe Optionen oben)

```python
# ❌ FALSCH - wird blockiert:
await client.connect()  # ohne set_security()

# ✅ RICHTIG:
await client.set_security(
    SecurityPolicyBasic256Sha256,
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
await client.connect()
```

### Problem: "certificate has no SubjectAlternativeName"

**Ursache:** Zertifikat wurde ohne SAN erstellt

**Lösung:** Neues Zertifikat mit `-extensions v3_req` erstellen (siehe Option 2)

```bash
# Zertifikat überprüfen:
openssl x509 -in client-cert.pem -text -noout | grep "Subject Alternative Name"

# Wenn leer/nicht vorhanden: Zertifikat neu erstellen mit Config!
```

### Problem: "BadCertificateUriInvalid"

**Ursache:** `client.application_uri` stimmt nicht mit URI im Zertifikat überein

**Lösung:** URIs müssen exakt übereinstimmen:

```python
# Im Code:
client.application_uri = "urn:mycompany:opcua:client"

# Im Zertifikat (opcua-client.cnf):
[alt_names]
URI.1 = urn:mycompany:opcua:client  # MUSS GLEICH SEIN!
```

### Problem: "Connection timeout"

**Ursache:** Server nicht erreichbar oder falsche URL

**Lösung:**
```bash
# Port-Check
nc -zv opcua.netz-fabrik.net 4840

# Ping
ping opcua.netz-fabrik.net

# Server-Status (auf Server prüfen)
docker ps --filter name=opcua-gateway
```

---

## 📋 Checkliste: Was brauche ich?

✅ **Für asyncua (automatisch):**
- Python-Code mit `client.set_security()` und `application_uri`
- Username & Password aus PRODUCTION-CREDENTIALS.txt
- Fertig! asyncua erstellt Zertifikat automatisch.

✅ **Für asyncua (eigenes Zertifikat):**
- `client-cert.pem` (mit SubjectAlternativeName!)
- `client-key.pem`
- `application_uri` im Code = URI im Zertifikat
- Username & Password

✅ **Für UaExpert:**
- UaExpert installiert
- Username & Password
- Security Policy: Basic256Sha256
- UaExpert erstellt Zertifikat automatisch

---

## 🔒 Sicherheits-Hinweise

### Privaten Schlüssel schützen!

```bash
# Berechtigungen setzen (nur Owner darf lesen)
chmod 600 client-key.pem

# NIEMALS in Git committen!
echo "client-key.pem" >> .gitignore
```

### Zertifikat-Gültigkeit

```bash
# Gültigkeit prüfen
openssl x509 -in client-cert.pem -noout -dates

# Ausgabe:
# notBefore=Oct 15 10:49:11 2025 GMT
# notAfter=Oct 15 10:49:11 2026 GMT  # 365 Tage gültig
```

**Empfehlung:** Zertifikate jährlich erneuern!

### Production-Zertifikate

Für Production solltest du:
1. **Separate Zertifikate pro Client** (nicht ein Zertifikat für alle!)
2. **Kürzere Gültigkeitsdauer** (z.B. 90-180 Tage statt 365)
3. **Zertifikats-Management** (CA, Widerruf-Listen)
4. **automaticallyAcceptUnknownCertificate=false** im Gateway (siehe gateway.js:139)

---

## 📚 Weiterführende Links

- **OpenSSL Dokumentation:** https://www.openssl.org/docs/
- **asyncua Security:** https://github.com/FreeOpcUa/opcua-asyncio
- **OPC UA Security:** https://opcfoundation.org/developer-tools/specifications-unified-architecture/part-2-security/
- **UaExpert:** https://www.unified-automation.com/

---

**Erstellt:** 2025-10-15
**Server:** opcua.netz-fabrik.net:4840
**Status:** Zertifikate ERFORDERLICH (nicht optional!)
