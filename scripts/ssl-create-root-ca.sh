#!/usr/bin/env bash

set -e 

usage() {
cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a Root Certificate Authority for signing service certificates.

OPTIONS:
    --organization ORG      Organization name for certificate subject (default: Homelab)
    --out-dir DIR           Output directory for generated files (default: ./certs)
    -h, --help              Show this help message and exit

DESCRIPTION:
    This script generates a self-signed Root Certificate Authority that can be used
    to sign service certificates for your homelab infrastructure. The Root CA
    certificate and private key are created with a 10-year validity period.

    The organization name is used to generate the output filenames in lowercase
    with spaces and underscores replaced by hyphens.

OUTPUT FILES:
    root-ca-<org-name>.key  Root CA private key (keep secure!)
    root-ca-<org-name>.crt  Root CA certificate (distribute to clients)

EXAMPLES:
    # Create CA with default settings
    $(basename "$0")

    # Create CA for custom organization
    $(basename "$0") --organization "My Company"

    # Create CA in specific directory
    $(basename "$0") --out-dir /etc/ssl/ca --organization "Production Lab"

ENVIRONMENT VARIABLES:
    ROOT_CA_ORG ROOT_CA_OUT_DIR
    Can be used instead of command line options.

SECURITY NOTES:
    - Keep the private key (.key file) secure and backed up
    - The certificate (.crt file) should be installed on client systems
    - Default key size is 4096 bits RSA

EXIT STATUS:
    0    Success
    1    Error (invalid arguments, file creation failed, etc.)

SEE ALSO:
    ssl-issue-service-certificate.sh(1), openssl(1)
EOF
  exit 1;
}

ORG="${ROOT_CA_ORG:-"Homelab"}"
OUT_DIR="${ROOT_CA_OUT_DIR:-$PWD/certs}"

while [[ "$1" =~ ^- ]]; do
  case $1 in
    --organization) ORG="$2";          shift 2;;
    --out-dir)      OUT_DIR="$PWD/$2"; shift 2;;
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
  -subj "/CN=$ORG Root CA"

echo ""
echo "Root Certificate Authority created successfully!"
echo "$OUT_DIR/"
echo "├── $ROOT_CA_KEY - CA private key (KEEP SECRET!)"
echo "└── $ROOT_CA_CRT - CA certificate"
