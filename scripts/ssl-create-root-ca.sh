#!/usr/bin/env bash

set -e 

usage() {
  echo "Usage: $0 [options]"
  exit 1;
}

CITY=${CITY:-"Vänersborg"}
COUNTRY_CODE=${COUNTRY_CODE:-"SE"}
EMAIL=${EMAIL:-"gustafholm1@gmail.com"}
ORG=${ORG:-"Homelab"}
OUT_DIR=$PWD/certs
STATE=${STATE:-"Västra Götaland"}

while [[ "$1" =~ ^- ]]; do
  case $1 in
    --city)         CITY="$2";         shift 2;;
    --country-code) COUNTRY_CODE="$2"; shift 2;;
    --email)        EMAIL="$2";        shift 2;;
    --organization) ORG="$2";          shift 2;;
    --out-dir)      OUT_DIR="$PWD/$2"; shift 2;;
    --state)        STATE="$2";        shift 2;;
    *)              usage ;;
  esac
done

OUT_NAME="${ORG,,}"       # lowercase
OUT_NAME=${OUT_NAME// /-} # replace spaces
OUT_NAME=${OUT_NAME//_/-} # replace underscores

if [[ -z "$OUT_DIR" ]]; then
  echo "Error: Output directory is required."
  usage
fi

ROOT_CA_KEY="root-ca-$OUT_NAME.key"
ROOT_CA_CRT="root-ca-$OUT_NAME.crt"

echo "[1/2] Creating Root CA private key..."
openssl genrsa -out "$OUT_DIR/$ROOT_CA_KEY" 4096

echo "[2/2] Creating Root CA certificate..."
openssl req -new -x509 -days 3650 \
  -key "$OUT_DIR/$ROOT_CA_KEY" \
  -out "$OUT_DIR/$ROOT_CA_CRT" \
  -subj "/C=$COUNTRY_CODE/ST=$STATE/L=$CITY/O=$ORG/CN=$ORG Root CA/emailAddress=$EMAIL"

echo ""
echo "Root Certificate Authority created successfully!"
echo "$OUT_DIR/"
echo "├── $ROOT_CA_KEY - CA private key (KEEP SECRET!)"
echo "└── $ROOT_CA_CRT - CA certificate"
