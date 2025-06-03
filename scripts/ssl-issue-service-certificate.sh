#!/usr/bin/env bash

set -e 

usage() {
cat << EOF
Usage: $(basename "$0") [OPTIONS] DOMAINS

Issue SSL certificates for services signed by a Root Certificate Authority.

ARGUMENTS:
    DOMAINS                 Comma-separated list of domain names for the certificate.
                           Supports wildcards (e.g., "*.example.com").

OPTIONS:
    --organization ORG      Organization name for certificate subject (default: Homelab)
    --out-dir DIR           Output directory for generated files (default: ./certs)
    --root-ca-path-crt FILE Path to Root CA certificate file (default: ./certs/root-ca-homelab.crt)
    --root-ca-path-key FILE Path to Root CA private key file (default: ./certs/root-ca-homelab.key)
    -h, --help              Show this help message and exit

DESCRIPTION:
    This script generates SSL certificates for services that are signed by your
    Root Certificate Authority. The certificates include Subject Alternative Names
    (SAN) for all specified domains and are valid for 10 years.

    The first domain in the list is used to generate the output filenames.
    Domain names are normalized (lowercase, dots/spaces/underscores to hyphens).

OUTPUT FILES:
    service-<domain>.key    Service private key
    service-<domain>.crt    Service certificate (signed by Root CA)
    service-<domain>.csr    Certificate signing request
    service-<domain>.ext    Certificate extensions file

EXAMPLES:
    # Single domain certificate
    $(basename "$0") "api.homelab.local"

    # Multiple domains in one certificate
    $(basename "$0") "web.homelab,api.homelab,admin.homelab"

    # Wildcard certificate
    $(basename "$0") "*.homelab.local"

    # Custom CA location
    $(basename "$0") --root-ca-path-crt ./my-ca.crt --root-ca-path-key ./my-ca.key "service.example.com"

    # Custom output directory
    $(basename "$0") --out-dir ./ssl-certs "prometheus.monitoring,grafana.monitoring"

ENVIRONMENT VARIABLES:
    SERVICE_CERT_ORG, SERVICE_CERT_OUT_DIR, ROOT_CA_CRT, ROOT_CA_KEY
    Can be used instead of command line options.

CERTIFICATE VALIDATION:
    The script automatically verifies that the generated certificate is properly
    signed by the Root CA. If verification fails, generated files are cleaned up.

PREREQUISITES:
    - Root CA certificate and private key must exist and be readable
    - OpenSSL must be installed and available in PATH
    - Write permissions in the output directory

EXIT STATUS:
    0    Success
    1    Error (missing arguments, invalid CA files, verification failed, etc.)

SEE ALSO:
    ssl-create-root-ca.sh(1), openssl(1)

EOF
  exit 1;
}

ORG=${SERVICE_CERT_ORG:-"Homelab"}
OUT_DIR="${SERVICE_CERT_OUT_DIR:-$PWD/certs}"
ROOT_CA_CRT="${ROOT_CA_CRT:-$PWD/certs/root-ca-homelab.crt}"
ROOT_CA_KEY="${ROOT_CA_KEY:-$PWD/certs/root-ca-homelab.key}"

while [[ "$1" =~ ^- ]]; do
  case $1 in
    --organization)     ORG="$2";              shift 2;;
    --out-dir)          OUT_DIR="$PWD/$2";     shift 2;;
    --root-ca-path-crt) ROOT_CA_CRT="$PWD/$2"; shift 2;;
    --root-ca-path-key) ROOT_CA_KEY="$PWD/$2"; shift 2;;
    *)                  usage ;;
  esac
done

DOMAINS_CSV=$1

if [[ -z "$OUT_DIR" ]]; then
  echo "Error: Output directory is required."
  usage
fi

if [[ -z "$DOMAINS_CSV" ]]; then
  echo "Error: Domains list is required."
  usage
fi

IFS=',' read -r -a DOMAINS <<< "$DOMAINS_CSV"

SERVICE_NAME="${DOMAINS[0]}"
SERVICE_NAME=${SERVICE_NAME,,}    # lowercase
SERVICE_NAME=${SERVICE_NAME#\*.}   # remove wildcard prefix
SERVICE_NAME=${SERVICE_NAME//./-} # replace dots
SERVICE_NAME=${SERVICE_NAME// /-} # replace spaces
SERVICE_NAME=${SERVICE_NAME//_/-} # replace underscores

SERVICE_NAME_KEY="service-$SERVICE_NAME.key"
SERVICE_NAME_CSR="service-$SERVICE_NAME.csr"
SERVICE_NAME_EXT="service-$SERVICE_NAME.ext"
SERVICE_NAME_CRT="service-$SERVICE_NAME.crt"


echo "[1/5] Creating certificate private key for *.${OUT_NAME}..."
openssl genrsa -out "$OUT_DIR/$SERVICE_NAME_KEY" 2048

echo "[2/5] Creating certificate signing request (CSR) for *.${OUT_NAME}..."
openssl req -new \
  -key "$OUT_DIR/$SERVICE_NAME_KEY" \
  -out "$OUT_DIR/$SERVICE_NAME_CSR" \
  -subj "/CN=*.${OUT_NAME}"


echo "[3/5] Creating certificate extensions..."
cat > "$OUT_DIR/$SERVICE_NAME_EXT" << EOF
[v3_req]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

# Add all domains
dns_count=1
for domain in "${DOMAINS[@]}"; do
    echo "DNS.$dns_count = $domain" >> "$OUT_DIR/$SERVICE_NAME_EXT"
    ((dns_count++))
done

echo "[4/5] Signing the certificate with Root CA..."
openssl x509 -req \
  -in "$OUT_DIR/$SERVICE_NAME_CSR" \
  -CA "$ROOT_CA_CRT" \
  -CAkey "$ROOT_CA_KEY" \
  -CAcreateserial \
  -out "$OUT_DIR/$SERVICE_NAME_CRT" \
  -days 3650 \
  -extensions v3_req \
  -extfile "$OUT_DIR/$SERVICE_NAME_EXT"

echo "[5/5] Verifying the certificate..."
VERIFIED=$(openssl verify -CAfile "$ROOT_CA_CRT" "$OUT_DIR/$SERVICE_NAME_CRT")
if ! [[ "$( echo $VERIFIED | awk '{print $2}')" == "OK" ]]; then
    echo "Certificate verification failed: $VERIFIED"
    echo "Cleaning up generated files..."
    rm -f "$OUT_DIR/$SERVICE_NAME_KEY" "$OUT_DIR/$SERVICE_NAME_CSR" "$OUT_DIR/$SERVICE_NAME_EXT" "$OUT_DIR/$SERVICE_NAME_CRT"
    echo "Cleanup completed. Please check the CA files and try again."
fi

echo ""
echo "Service certificate created successfully!"
echo "$OUT_DIR/"
echo "├── $SERVICE_NAME_KEY - Service private key"
echo "├── $SERVICE_NAME_CRT - Service certificate"
echo "├── $SERVICE_NAME_CSR - Certificate signing request"
echo "└── $SERVICE_NAME_EXT - Certificate extensions"
