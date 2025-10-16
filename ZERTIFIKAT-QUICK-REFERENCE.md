# OPC-UA Zertifikate - Quick Reference

Schnelle Übersicht: Welches Zertifikat für welchen Server?

---

## 🎯 Für opcua.netz-fabrik.net:4840

**Server-Typ:** node-opcua basiert
**Benötigt:** `CA:TRUE`

**Fertige Zertifikate verwenden:**

```python
# Web-UI/Streamlit
await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="example-certs/streamlit-cert.pem",
    private_key="example-certs/streamlit-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
client.application_uri = "urn:opcua-monitoring-ui"
```

```python
# Data Collector
await client.set_security(
    SecurityPolicyBasic256Sha256,
    certificate="example-certs/data-collector-cert.pem",
    private_key="example-certs/data-collector-key.pem",
    mode=ua.MessageSecurityMode.SignAndEncrypt
)
client.application_uri = "urn:opcua-data-collector"
```

---

## 📋 Zwei Haupt-Varianten

### Variante A: node-opcua Server (CA:TRUE)

**Für:** opcua.netz-fabrik.net, andere node-opcua basierte Server

**Schnell-Befehl:**
```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem -out client-cert.pem -days 365 -nodes \
  -subj "/CN=MyClient/O=MyCompany/C=DE" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
  -addext "extendedKeyUsage=clientAuth,serverAuth" \
  -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"
```

**Muss haben:**
- ✅ `basicConstraints = critical,CA:TRUE`
- ✅ `nonRepudiation` in keyUsage
- ✅ `extendedKeyUsage = clientAuth, serverAuth`

---

### Variante B: Spec-konforme Server (CA:FALSE)

**Für:** Siemens S7-1500/1200, Unified Automation, Prosys, B&R, die meisten PLCs

**Schnell-Befehl:**
```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout client-key.pem -out client-cert.pem -days 365 -nodes \
  -subj "/CN=MyClient/O=MyCompany/C=DE" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" \
  -addext "extendedKeyUsage=clientAuth" \
  -addext "subjectAltName=URI:urn:mycompany:opcua:client,DNS:localhost"
```

**Muss haben:**
- ✅ `basicConstraints = critical,CA:FALSE`
- ✅ `nonRepudiation` in keyUsage
- ✅ `extendedKeyUsage = clientAuth` (OHNE serverAuth)

---

## 🔍 Fehlerdiagnose

### Fehler: BadCertificateUseNotAllowed

**Bedeutet:** Server ist node-opcua, aber Ihr Zertifikat hat `CA:FALSE`

**Lösung:** Erstellen Sie Zertifikat mit `CA:TRUE` (Variante A)

---

### Fehler: BadCertificateInvalid (bei Siemens/UA SDK)

**Bedeutet:** Server ist spec-konform, aber Ihr Zertifikat hat `CA:TRUE`

**Lösung:** Erstellen Sie Zertifikat mit `CA:FALSE` (Variante B)

---

## ✅ Zertifikat verifizieren

```bash
# Prüfe CA-Flag
openssl x509 -in client-cert.pem -text -noout | grep -A 2 "Basic Constraints"

# Sollte zeigen (für node-opcua):
#   X509v3 Basic Constraints: critical
#       CA:TRUE

# Oder (für Siemens/UA SDK):
#   X509v3 Basic Constraints: critical
#       CA:FALSE
```

---

## 📚 Vollständige Dokumentation

Siehe: [ZERTIFIKATE-UNIVERSAL.md](ZERTIFIKATE-UNIVERSAL.md)

---

**TL;DR:**
- **opcua.netz-fabrik.net** → Verwenden Sie example-certs/ (haben CA:TRUE)
- **Siemens/andere PLCs** → Erstellen Sie neues Zertifikat mit CA:FALSE
- **Unsicher?** → Erstellen Sie beide Varianten und testen Sie
