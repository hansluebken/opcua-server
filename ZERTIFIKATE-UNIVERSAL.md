# Universelle OPC-UA Client-Zertifikate

Umfassende Anleitung zur Erstellung von Client-Zertifikaten, die mit verschiedenen OPC-UA Server-Implementierungen funktionieren.

---

## ⚠️ Das Problem

Verschiedene OPC-UA Server-Implementierungen haben **unterschiedliche Anforderungen** an Client-Zertifikate:

| Server-Implementierung | CA:TRUE erforderlich? | Besonderheiten |
|------------------------|----------------------|----------------|
| **node-opcua** | ✅ JA (sonst BadCertificateUseNotAllowed) | Unser opcua-gateway basiert darauf |
| **Siemens S7-1500/1200** | ❌ NEIN (lehnt CA:TRUE ab) | Client-Zerts dürfen KEINE CAs sein |
| **Unified Automation SDK** | ❌ NEIN | Strenge OPC Foundation Spec Compliance |
| **Prosys OPC UA SDK** | ❌ NEIN | Strenge OPC Foundation Spec Compliance |
| **open62541** | ⚠️ Beides OK | Toleranter |
| **B&R Automation** | ❌ NEIN | IEC 62541 strict |
| **Beckhoff TwinCAT** | ⚠️ Konfigurierbar | Je nach Einstellung |

**Laut OPC Foundation Specification (IEC 62541):**
> Client-Zertifikate sollten **NICHT** `CA:TRUE` haben, weil sie keine Certificate Authority sind.

**Aber:** node-opcua Server **benötigen** `CA:TRUE` und lehnen Zertifikate ohne diese Flag ab.

---

## ✅ Lösung: Drei Zertifikat-Varianten

### Variante 1: Für node-opcua Server (inkl. unser Gateway)

**Verwendung:** opcua.netz-fabrik.net:4840, andere node-opcua basierte Server

**OpenSSL Config:**

```bash
cat > client-nodejs-opcua.cnf <<'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
CN = My OPC-UA Client
O = My Company
C = DE

[v3_ca]
# WICHTIG: CA:TRUE ist für node-opcua ERFORDERLICH!
basicConstraints = critical,CA:TRUE
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names

[alt_names]
URI.1 = urn:mycompany:opcua:client
DNS.1 = localhost
DNS.2 = my-hostname
EOF
```

**Zertifikat generieren:**

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-nodejs-key.pem \
  -out client-nodejs-cert.pem \
  -days 365 -nodes \
  -config client-nodejs-opcua.cnf \
  -extensions v3_ca
```

**Verifizierung:**

```bash
openssl x509 -in client-nodejs-cert.pem -text -noout | grep -A 10 "X509v3 extensions"
```

**Sollte zeigen:**
```
X509v3 Basic Constraints: critical
    CA:TRUE                                    ← WICHTIG!
X509v3 Key Usage: critical
    Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
X509v3 Extended Key Usage:
    TLS Web Server Authentication, TLS Web Client Authentication
X509v3 Subject Alternative Name:
    URI:urn:mycompany:opcua:client, DNS:localhost, DNS:my-hostname
```

---

### Variante 2: OPC Foundation Spec-konform (Siemens, UA SDK, Prosys, B&R)

**Verwendung:** Siemens S7-1500/1200, Unified Automation, Prosys, B&R, die meisten industriellen PLCs

**OpenSSL Config:**

```bash
cat > client-spec-compliant.cnf <<'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = My OPC-UA Client
O = My Company
OU = Engineering
L = Berlin
ST = Berlin
C = DE

[v3_req]
# WICHTIG: CA:FALSE für spec-konforme Server!
basicConstraints = critical,CA:FALSE
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer

[alt_names]
URI.1 = urn:mycompany:opcua:client
DNS.1 = localhost
DNS.2 = my-hostname
EOF
```

**Zertifikat generieren:**

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-spec-key.pem \
  -out client-spec-cert.pem \
  -days 365 -nodes \
  -config client-spec-compliant.cnf \
  -extensions v3_req
```

**Verifizierung:**

```bash
openssl x509 -in client-spec-cert.pem -text -noout | grep -A 10 "X509v3 extensions"
```

**Sollte zeigen:**
```
X509v3 Basic Constraints: critical
    CA:FALSE                                   ← WICHTIG!
X509v3 Key Usage: critical
    Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
X509v3 Extended Key Usage:
    TLS Web Client Authentication
X509v3 Subject Alternative Name:
    URI:urn:mycompany:opcua:client, DNS:localhost, DNS:my-hostname
X509v3 Subject Key Identifier:
    XX:XX:XX:...
X509v3 Authority Key Identifier:
    keyid:XX:XX:XX:...
```

---

### Variante 3: Universal-Zertifikat (funktioniert meistens)

**Verwendung:** Wenn Sie nicht wissen, welche Server-Implementierung verwendet wird

**OpenSSL Config:**

```bash
cat > client-universal.cnf <<'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = My OPC-UA Client
O = My Company
OU = Engineering
C = DE

[v3_req]
# CA:FALSE - funktioniert bei den meisten Servern
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
URI.1 = urn:mycompany:opcua:client
DNS.1 = localhost
EOF
```

**Zertifikat generieren:**

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-universal-key.pem \
  -out client-universal-cert.pem \
  -days 365 -nodes \
  -config client-universal.cnf \
  -extensions v3_req
```

---

## 📊 Vergleichstabelle der Varianten

| Parameter | Variante 1 (node-opcua) | Variante 2 (Spec-konform) | Variante 3 (Universal) |
|-----------|--------------------------|----------------------------|------------------------|
| **basicConstraints** | `critical,CA:TRUE` | `critical,CA:FALSE` | `CA:FALSE` |
| **keyUsage (critical)** | ✅ Ja | ✅ Ja | ❌ Nein |
| **digitalSignature** | ✅ Ja | ✅ Ja | ✅ Ja |
| **nonRepudiation** | ✅ Ja | ✅ Ja | ✅ Ja |
| **keyEncipherment** | ✅ Ja | ✅ Ja | ✅ Ja |
| **dataEncipherment** | ✅ Ja | ✅ Ja | ✅ Ja |
| **extendedKeyUsage** | `clientAuth, serverAuth` | `clientAuth` | `clientAuth` |
| **subjectAltName (URI)** | ✅ PFLICHT | ✅ PFLICHT | ✅ PFLICHT |
| **subjectKeyIdentifier** | ❌ Optional | ✅ Empfohlen | ❌ Optional |
| **authorityKeyIdentifier** | ❌ Optional | ✅ Empfohlen | ❌ Optional |

---

## 🎯 Welche Variante für welchen Server?

### Für opcua.netz-fabrik.net:4840

**Verwenden Sie:** Variante 1 (node-opcua)

```bash
# Zertifikat ist bereits vorhanden:
example-certs/streamlit-cert.pem        # CA:TRUE
example-certs/data-collector-cert.pem   # CA:TRUE
example-certs/test-client-cert.pem      # CA:TRUE
```

**Diese funktionieren SOFORT!**

---

### Für Siemens S7-1500 / S7-1200

**Verwenden Sie:** Variante 2 (Spec-konform) mit `CA:FALSE`

**Zusätzliche Schritte für Siemens:**

1. **Zertifikat erstellen** (siehe Variante 2)

2. **Zertifikat in DER-Format konvertieren:**
   ```bash
   openssl x509 -in client-spec-cert.pem -outform DER -out client-spec-cert.der
   ```

3. **In TIA Portal importieren:**
   - TIA Portal öffnen → CPU-Eigenschaften
   - "Protection & Security" → "Certificates"
   - "Import Certificate" → client-spec-cert.der auswählen
   - Zertifikat als "Trusted" markieren

4. **OPC UA Server aktivieren:**
   - "OPC UA" → "Server" → "Activate OPC UA Server"
   - Security Policy: "Basic256Sha256" auswählen
   - "User Authentication" konfigurieren

**Wichtig für Siemens:**
- CN (Common Name) muss eindeutig sein
- Application URI muss mit TIA Portal Application URI übereinstimmen
- Zertifikat darf NICHT `CA:TRUE` haben

---

### Für Unified Automation / Prosys OPC UA

**Verwenden Sie:** Variante 2 (Spec-konform)

**Zusätzlich beachten:**
- Key Length: Mindestens 2048 bit (besser 4096 bit)
- Hash Algorithm: SHA-256 oder besser
- Validity: Nicht länger als 1 Jahr (für Production)

**4096-bit Variante:**
```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout client-spec-key.pem \
  -out client-spec-cert.pem \
  -days 365 -nodes \
  -config client-spec-compliant.cnf \
  -extensions v3_req \
  -sha256
```

---

## 🔧 Schritt-für-Schritt: Zertifikat für JEDEN Server

### Methode 1: Beide Varianten erstellen und testen

**Für maximale Kompatibilität: Erstellen Sie BEIDE Varianten!**

```bash
# 1. node-opcua Variante (CA:TRUE)
openssl req -x509 -newkey rsa:2048 \
  -keyout client-nodejs-key.pem \
  -out client-nodejs-cert.pem \
  -days 365 -nodes \
  -subj "/CN=My OPC-UA Client/O=My Company/C=DE" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
  -addext "extendedKeyUsage=clientAuth,serverAuth" \
  -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"

# 2. Spec-konforme Variante (CA:FALSE)
openssl req -x509 -newkey rsa:2048 \
  -keyout client-spec-key.pem \
  -out client-spec-cert.pem \
  -days 365 -nodes \
  -subj "/CN=My OPC-UA Client/O=My Company/C=DE" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
  -addext "extendedKeyUsage=clientAuth" \
  -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"
```

**Dann testen Sie beide mit Ihrem Server:**

```python
# Test mit node-opcua Variante
await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="client-nodejs-cert.pem",
    private_key="client-nodejs-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)

# Falls das nicht funktioniert, testen Sie spec-konforme Variante
await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="client-spec-cert.pem",
    private_key="client-spec-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
```

---

### Methode 2: Mit Python asyncua automatisch generieren lassen

**asyncua kann Zertifikate automatisch erstellen - aber nur spec-konforme (CA:FALSE)!**

```python
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

client = Client("opc.tcp://your-server:4840")
client.application_uri = "urn:mycompany:opcua:client"

# asyncua generiert automatisch ein Zertifikat
# ABER: Es hat CA:FALSE und funktioniert NICHT mit node-opcua!
await client.set_security(
    SecurityPolicyBasic256Sha256,
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
```

**Zertifikat-Speicherort:**
- Linux/Mac: `~/.opcua/`
- Windows: `C:\Users\<Username>\.opcua\`

**Problem:** asyncua generiert spec-konforme Zertifikate (CA:FALSE), die mit unserem node-opcua Gateway **nicht funktionieren**!

**Lösung:** Manuell Zertifikat mit CA:TRUE erstellen (siehe Variante 1)

---

## 🔍 Zertifikat-Fehlerdiagnose

### Fehler: BadCertificateUseNotAllowed

**Server-Logs zeigen:**
```
Sender Certificate Error BadCertificateUseNotAllowed (0x80180000)
```

**Ursache:**
- node-opcua Server benötigt `CA:TRUE`, aber Ihr Zertifikat hat `CA:FALSE` oder gar kein basicConstraints

**Lösung:**
```bash
# Prüfen Sie Ihr Zertifikat
openssl x509 -in your-cert.pem -text -noout | grep -A 2 "Basic Constraints"

# Falls CA:FALSE oder nicht vorhanden:
# Erstellen Sie Zertifikat mit Variante 1 (CA:TRUE)
```

---

### Fehler: BadCertificateInvalid (Siemens/UA SDK)

**Server lehnt Zertifikat ab**

**Ursache:**
- Spec-konformer Server (Siemens, UA SDK) lehnt `CA:TRUE` für Client-Zertifikate ab

**Lösung:**
```bash
# Prüfen Sie Ihr Zertifikat
openssl x509 -in your-cert.pem -text -noout | grep -A 2 "Basic Constraints"

# Falls CA:TRUE:
# Erstellen Sie Zertifikat mit Variante 2 (CA:FALSE)
```

---

### Fehler: BadCertificateUriInvalid

**Ursache:** Fehlende oder falsche Application URI im Zertifikat

**Prüfen:**
```bash
openssl x509 -in your-cert.pem -text -noout | grep "URI:"
```

**Muss zeigen:**
```
URI:urn:mycompany:opcua:client
```

**Lösung:** Zertifikat neu erstellen mit korrekter `subjectAltName`

---

## 📋 Checkliste: Universelles Zertifikat erstellen

### 1. Anforderungen klären

**Fragen Sie sich:**
- [ ] Welchen Server verwende ich? (node-opcua, Siemens, UA SDK, etc.)
- [ ] Benötigt der Server `CA:TRUE` oder `CA:FALSE`?
- [ ] Welche Security Policy wird verwendet? (Basic256Sha256, etc.)
- [ ] Gibt es firmeninterne Vorgaben?

### 2. Zertifikat erstellen

**Für node-opcua (wie opcua.netz-fabrik.net):**
```bash
# Verwenden Sie Variante 1 mit CA:TRUE
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem -out client-cert.pem \
  -days 365 -nodes \
  -subj "/CN=MyClient/O=MyCompany/C=DE" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
  -addext "extendedKeyUsage=clientAuth,serverAuth" \
  -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"
```

**Für alle anderen Server:**
```bash
# Verwenden Sie Variante 2 mit CA:FALSE
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem -out client-cert.pem \
  -days 365 -nodes \
  -subj "/CN=MyClient/O=MyCompany/C=DE" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
  -addext "extendedKeyUsage=clientAuth" \
  -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"
```

### 3. Zertifikat verifizieren

```bash
# Basic Constraints prüfen
openssl x509 -in client-cert.pem -text -noout | grep -A 2 "Basic Constraints"

# Key Usage prüfen
openssl x509 -in client-cert.pem -text -noout | grep -A 3 "Key Usage"

# Subject Alternative Name prüfen
openssl x509 -in client-cert.pem -text -noout | grep -A 3 "Subject Alternative Name"

# Gültigkeitszeitraum prüfen
openssl x509 -in client-cert.pem -text -noout | grep -A 2 "Validity"
```

### 4. Rechte setzen

```bash
chmod 644 client-cert.pem
chmod 600 client-key.pem
```

### 5. Verbindung testen

```python
import asyncio
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua import ua

async def test():
    client = Client("opc.tcp://your-server:4840")
    client.application_uri = "urn:mycompany:opcua:client"  # MUSS mit Zertifikat übereinstimmen!

    client.set_user("username")
    client.set_password("password")

    await client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate="client-cert.pem",
        private_key="client-key.pem",
        mode=ua.MessageSecurityMode.SignAndEncrypt
    )

    try:
        async with client:
            print("✅ Verbindung erfolgreich!")
            namespaces = await client.get_namespace_array()
            print(f"Namespaces: {namespaces}")
    except Exception as e:
        print(f"❌ Fehler: {e}")

asyncio.run(test())
```

---

## 💡 Best Practices

### 1. Application URI konsistent halten

**Falsch:**
```python
# Zertifikat hat: urn:mycompany:opcua:client
client.application_uri = "urn:different:uri"  # ❌ Passt nicht!
```

**Richtig:**
```python
# Zertifikat hat: urn:mycompany:opcua:client
client.application_uri = "urn:mycompany:opcua:client"  # ✅ Identisch!
```

### 2. Separate Zertifikate pro Anwendung

**Verwenden Sie unterschiedliche URIs für verschiedene Clients:**

```bash
# Web-UI
URI:urn:mycompany:opcua:webui

# Data Collector
URI:urn:mycompany:opcua:collector

# Test Client
URI:urn:mycompany:opcua:test
```

### 3. Zertifikate dokumentieren

Erstellen Sie eine Übersicht:

```
client-nodejs-cert.pem     → Für node-opcua Server (CA:TRUE)
client-spec-cert.pem       → Für Siemens/UA SDK (CA:FALSE)
client-webui-cert.pem      → Web-UI (CA:TRUE, für unser Gateway)
client-collector-cert.pem  → Data Collector (CA:TRUE, für unser Gateway)
```

### 4. Gültigkeitsdauer

**Empfehlung:**
- **Development:** 365 Tage OK
- **Production:** Maximal 398 Tage (gemäß Apple/Google/Mozilla Policy)
- **Kritische Infrastruktur:** 90 Tage, automatisch rotieren

### 5. Schlüssellänge

**Empfehlung:**
- **Minimum:** 2048 bit
- **Empfohlen:** 2048 bit (guter Kompromiss Performance/Sicherheit)
- **Hohe Sicherheit:** 4096 bit (langsamer)

```bash
# 4096-bit Zertifikat
openssl req -x509 -newkey rsa:4096 ...
```

---

## 🔄 Migration bestehender Zertifikate

### Von asyncua-generierten Zertifikaten zu CA:TRUE

**Problem:** asyncua generiert Zertifikate mit `CA:FALSE`, die mit node-opcua Servern nicht funktionieren.

**Lösung:**

1. **Altes Zertifikat finden:**
   ```bash
   # Linux/Mac
   ls ~/.opcua/own/certs/

   # Windows
   dir C:\Users\<Username>\.opcua\own\certs\
   ```

2. **Neues Zertifikat erstellen:**
   ```bash
   openssl req -x509 -newkey rsa:2048 \
     -keyout ~/.opcua/own/private/private-key.pem \
     -out ~/.opcua/own/certs/client-certificate.pem \
     -days 365 -nodes \
     -subj "/CN=MyClient/O=MyCompany/C=DE" \
     -addext "basicConstraints=critical,CA:TRUE" \
     -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
     -addext "extendedKeyUsage=clientAuth,serverAuth" \
     -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"
   ```

3. **Rechte setzen:**
   ```bash
   chmod 644 ~/.opcua/own/certs/client-certificate.pem
   chmod 600 ~/.opcua/own/private/private-key.pem
   ```

4. **Python-Code anpassen:**
   ```python
   # ALT (automatisches Zertifikat)
   await client.set_security(
       SecurityPolicyBasic256Sha256,
       mode=ua.MessageSecurityMode.SignAndEncrypt
   )

   # NEU (explizites Zertifikat)
   await client.set_security(
       SecurityPolicyBasic256Sha256,
       certificate=os.path.expanduser("~/.opcua/own/certs/client-certificate.pem"),
       private_key=os.path.expanduser("~/.opcua/own/private/private-key.pem"),
       mode=ua.MessageSecurityMode.SignAndEncrypt
   )
   ```

---

## 📚 Weiterführende Ressourcen

### Offizielle Spezifikationen

- **OPC UA Specification Part 6:** Security
  - https://reference.opcfoundation.org/Core/Part6/
  - Definiert Zertifikat-Anforderungen

- **IEC 62541-6:** OPC Unified Architecture - Part 6: Mappings
  - Internationale Norm für OPC UA Security

### Server-spezifische Dokumentation

**Siemens:**
- TIA Portal Help: "OPC UA Server" → "Certificates"
- https://support.industry.siemens.com/cs/document/109779599

**Unified Automation:**
- UaExpert User Manual: "Certificate Management"
- https://www.unified-automation.com/

**node-opcua:**
- GitHub Issues: https://github.com/node-opcua/node-opcua/issues
- Certificate Manager Documentation

---

## 🎯 Zusammenfassung

### Für opcua.netz-fabrik.net:4840

**Verwenden Sie die vorhandenen Zertifikate:**

```python
# Variante 1: Web-UI
certificate="example-certs/streamlit-cert.pem"
private_key="example-certs/streamlit-key.pem"
application_uri="urn:opcua-monitoring-ui"

# Variante 2: Data Collector
certificate="example-certs/data-collector-cert.pem"
private_key="example-certs/data-collector-key.pem"
application_uri="urn:opcua-data-collector"

# Variante 3: Testing
certificate="example-certs/test-client-cert.pem"
private_key="example-certs/test-client-key.pem"
application_uri="urn:opcua-test-client"
```

**Diese haben alle `CA:TRUE` und funktionieren sofort!**

---

### Für andere OPC-UA Server

**Wenn Sie NICHT wissen, welche Server-Implementierung:**

1. **Erstellen Sie BEIDE Varianten** (CA:TRUE und CA:FALSE)
2. **Testen Sie zuerst Variante 2** (CA:FALSE = spec-konform)
3. **Falls BadCertificateUseNotAllowed**: Verwenden Sie Variante 1 (CA:TRUE)

**Wenn Sie wissen, dass es ein node-opcua Server ist:**
- Verwenden Sie Variante 1 mit `CA:TRUE`

**Wenn Sie wissen, dass es Siemens/UA SDK/Prosys ist:**
- Verwenden Sie Variante 2 mit `CA:FALSE`

---

**Erstellt:** 2025-10-16
**Server:** opcua.netz-fabrik.net:4840 (node-opcua)
**Status:** Produktionsreif
