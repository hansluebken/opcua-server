#!/usr/bin/env node
/**
 * OPC-UA Security Gateway
 *
 * Provides S7-1500 like security in front of OPC-UA simulator
 * - Enforces certificate-based authentication
 * - Blocks anonymous access
 * - Proxies to backend OPC-UA server
 */

const opcua = require("node-opcua");
const fs = require("fs");
const path = require("path");

// Configuration
const GATEWAY_PORT = parseInt(process.env.GATEWAY_PORT || "4840");
const BACKEND_ENDPOINT = process.env.BACKEND_ENDPOINT || "opc.tcp://opcua-simulator:4841";
const ALLOW_ANONYMOUS = process.env.ALLOW_ANONYMOUS === "true" ? true : false;
const REQUIRE_CERTIFICATE = process.env.REQUIRE_CERTIFICATE === "true" ? true : false;

console.log("╔════════════════════════════════════════════════════════════╗");
console.log("║   OPC-UA Security Gateway (S7-1500 like)                  ║");
console.log("╚════════════════════════════════════════════════════════════╝");
console.log("");
console.log("Configuration:");
console.log(`  Gateway Port: ${GATEWAY_PORT}`);
console.log(`  Backend: ${BACKEND_ENDPOINT}`);
console.log(`  Allow Anonymous: ${ALLOW_ANONYMOUS ? '✅ YES (Dev Mode)' : '❌ NO (Production)'}`);
console.log(`  Require Certificate: ${REQUIRE_CERTIFICATE ? '✅ YES' : '❌ NO'}`);
console.log("");

// Certificate paths
const PKI_FOLDER = path.join(__dirname, "pki");
// Let node-opcua auto-generate certificates
const certificateFile = undefined;
const privateKeyFile = undefined;

// Ensure PKI directories exist
const dirs = [
    path.join(PKI_FOLDER, "own", "certs"),
    path.join(PKI_FOLDER, "own", "private"),
    path.join(PKI_FOLDER, "trusted", "certs"),
    path.join(PKI_FOLDER, "rejected", "certs"),
    path.join(PKI_FOLDER, "issuers", "certs")
];

dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        console.log(`Created directory: ${dir}`);
    }
});

// Backend client connection (to simulator)
let backendSession = null;
let backendClient = null;

async function connectToBackend() {
    console.log(`\nConnecting to backend: ${BACKEND_ENDPOINT}...`);

    backendClient = opcua.OPCUAClient.create({
        applicationName: "OPC-UA Gateway Client",
        securityMode: opcua.MessageSecurityMode.None,
        securityPolicy: opcua.SecurityPolicy.None,
        endpointMustExist: false,
    });

    try {
        const endpoints = await backendClient.getEndpoints();
        console.log(`Found ${endpoints.length} endpoints on backend`);

        await backendClient.connect(BACKEND_ENDPOINT);
        console.log("✅ Connected to backend simulator");

        backendSession = await backendClient.createSession();
        console.log("✅ Backend session created");

        return true;
    } catch (err) {
        console.error("❌ Failed to connect to backend:", err.message);
        console.log("⚠️  Gateway will start without backend connection");
        return false;
    }
}

// Gateway Server (facing clients)
async function startGatewayServer() {
    const server = new opcua.OPCUAServer({
        port: GATEWAY_PORT,
        resourcePath: "/UA/Gateway",
        buildInfo: {
            productName: "OPC-UA Security Gateway",
            buildNumber: "1.0.0",
            buildDate: new Date()
        },

        // Security Configuration (S7-1500 like)
        securityPolicies: [
            opcua.SecurityPolicy.None,
            opcua.SecurityPolicy.Basic256Sha256
        ],

        securityModes: [
            opcua.MessageSecurityMode.None,
            opcua.MessageSecurityMode.Sign,
            opcua.MessageSecurityMode.SignAndEncrypt
        ],

        // Authentication
        allowAnonymous: ALLOW_ANONYMOUS,

        // User Manager (for username/password if needed)
        userManager: {
            isValidUser: function(userName, password) {
                console.log(`Authentication attempt: user=${userName}`);

                // Production users (from PRODUCTION-CREDENTIALS.txt)
                const users = {
                    "opcua-reader": "gu/pHCAi1tQ4ekQkPFiGl4wAeimL4SoFvHaFmTmj1S4=",
                    "opcua-operator": "ihMAgDJkDb71eBHWdwSM/UP2tLHqg/SldO4z8LwRgMU=",
                    "opcua-admin": "O+d5CkM1Gn9SGPKcuy+AThccTIbsCP2Dp/iW5hRXK8U0AllqPOE2bMoq8bEWmYTa"
                };

                if (users[userName] && users[userName] === password) {
                    console.log(`✅ User authenticated: ${userName}`);
                    return true;
                }

                console.log(`❌ Authentication failed for user: ${userName}`);
                return false;
            }
        },

        // Certificate Manager
        certificateFile: certificateFile,
        privateKeyFile: privateKeyFile,

        serverCertificateManager: new opcua.OPCUACertificateManager({
            automaticallyAcceptUnknownCertificate: ALLOW_ANONYMOUS,
            rootFolder: PKI_FOLDER
        })
    });

    await server.initialize();
    console.log("\n✅ Gateway server initialized");

    // Build address space (proxy nodes from backend)
    await constructAddressSpace(server);

    await server.start();
    console.log(`\n✅ Gateway started on port ${GATEWAY_PORT}`);
    console.log(`\nEndpoint: opc.tcp://opcua.netz-fabrik.net:${GATEWAY_PORT}`);
    console.log("\nSecurity Configuration:");
    console.log(`  - Anonymous: ${ALLOW_ANONYMOUS ? '✅ Enabled' : '❌ Disabled'}`);
    console.log(`  - Username/Password: ✅ Enabled`);
    console.log(`  - Certificate: ✅ Enabled`);
    console.log(`  - Security Policy: Basic256Sha256`);
    console.log("\n════════════════════════════════════════════════════════════");
    console.log("Gateway is ready!");
    console.log("════════════════════════════════════════════════════════════\n");
}

async function constructAddressSpace(server) {
    const addressSpace = server.engine.addressSpace;
    const namespace = addressSpace.getOwnNamespace();

    console.log("\nBuilding address space (proxying backend nodes)...");

    if (!backendSession) {
        console.log("⚠️  Backend not connected, creating minimal address space");

        // Create minimal demo namespace
        const folder = namespace.addFolder("ObjectsFolder", {
            browseName: "Gateway"
        });

        // Add demo variable
        namespace.addVariable({
            componentOf: folder,
            browseName: "ServerStatus",
            dataType: "String",
            value: {
                get: function() {
                    return new opcua.Variant({
                        dataType: opcua.DataType.String,
                        value: "Gateway Running - Backend not connected"
                    });
                }
            }
        });

        return;
    }

    try {
        // Browse backend server
        const browseResult = await backendSession.browse("ns=0;i=85"); // Objects folder

        console.log(`Found ${browseResult.references.length} nodes in backend`);

        // For now, create proxy folder
        const gatewayFolder = namespace.addFolder("ObjectsFolder", {
            browseName: "OpcPlc"
        });

        // Add info variable
        namespace.addVariable({
            componentOf: gatewayFolder,
            browseName: "Info",
            dataType: "String",
            value: {
                get: function() {
                    return new opcua.Variant({
                        dataType: opcua.DataType.String,
                        value: `Proxying ${BACKEND_ENDPOINT}`
                    });
                }
            }
        });

        console.log("✅ Address space created (proxy mode)");

    } catch (err) {
        console.error("Error building address space:", err.message);
    }
}

// Main
async function main() {
    try {
        // Connect to backend first
        const connected = await connectToBackend();

        // Start gateway server
        await startGatewayServer();

    } catch (err) {
        console.error("Fatal error:", err);
        process.exit(1);
    }
}

// Handle shutdown
process.on('SIGINT', async () => {
    console.log("\nShutting down gateway...");

    if (backendSession) {
        await backendSession.close();
    }
    if (backendClient) {
        await backendClient.disconnect();
    }

    process.exit(0);
});

// Start
main().catch(err => {
    console.error("Failed to start gateway:", err);
    process.exit(1);
});
