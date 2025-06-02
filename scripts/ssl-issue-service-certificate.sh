#!/usr/bin/env bash

set -e 

usage() {
  echo ""
  exit 1;
}

CITY=${CITY:-"Vänersborg"}
COUNTRY_CODE=${COUNTRY_CODE:-"SE"}
EMAIL=${EMAIL:-"gustafholm1@gmail.com"}
ORG=${ORG:-"Homelab"}
OUT_DIR=$PWD/certs
ROOT_CA_CRT="${ROOT_CA_CRT:-$PWD/certs/root-ca-homelab.crt}"
ROOT_CA_KEY="${ROOT_CA_KEY:-$PWD/certs/root-ca-homelab.key}"
STATE=${STATE:-"Västra Götaland"}

while [[ "$1" =~ ^- ]]; do
  case $1 in
    --city)             CITY="$2";             shift 2;;
    --country-code)     COUNTRY_CODE="$2";     shift 2;;
    --email)            EMAIL="$2";            shift 2;;
    --organization)     ORG="$2";              shift 2;;
    --out-dir)          OUT_DIR="$PWD/$2";     shift 2;;
    --root-ca-path-crt) ROOT_CA_CRT="$PWD/$2"; shift 2;;
    --root-ca-path-key) ROOT_CA_KEY="$PWD/$2"; shift 2;;
    --state)            STATE="$2";            shift 2;;
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
  -subj "/C=$COUNTRY_CODE/ST=$STATE/L=$CITY/O=$ORG/CN=*.${OUT_NAME}/emailAddress=$EMAIL"


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
