#!/usr/bin/env bash
# Setup script for Net-Tech prototype 
# Usage:
#   bash nettech_program/setup_commands.sh <student_id> "<Full Name>" "<Deadline text>"
# Example:
#   bash nettech_program/setup_commands.sh s1234567 "Alex Morgan" "3 Nov 2025"

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <student_id> [\"Full Name\"] [\"Deadline text\"]"
  exit 1
fi

STUDENT_ID="${1:-s1234567}"
FULL_NAME="${2:-Your Name}"
DEADLINE="${3:-<deadline>}"

echo "[1/8] Update and base packages"
sudo apt update
sudo apt -y install nginx php-fpm php-cli php-mysql mariadb-server ufw curl unzip

echo "[2/8] Create web root"
sudo mkdir -p /var/www/nettech
sudo chown -R www-data:www-data /var/www/nettech
sudo chmod -R 0755 /var/www/nettech

echo "[3/8] Configure Nginx (index.html preferred)"
sudo cp -v nettech_program/nettech_site.conf /etc/nginx/sites-available/nettech.conf
sudo ln -sf /etc/nginx/sites-available/nettech.conf /etc/nginx/sites-enabled/nettech.conf
sudo nginx -t
sudo systemctl reload nginx

echo "[4/8] Prepare PHP-FPM environment"
echo "env[NETTECH_STUDENT] = ${STUDENT_ID}" | sudo tee /etc/php/*/fpm/pool.d/env-nettech.conf >/dev/null || true
sudo systemctl reload php*-fpm.service || true

echo "[5/8] Deploy testimonials and index.php"
sudo cp -v nettech_program/testimonials.html /var/www/nettech/testimonials.html
sudo cp -v nettech_program/index.php /var/www/nettech/index.php

echo "[6/8] Render Appendix 1 content into index.html"
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_NAME="${PRETTY_NAME:-Linux}"
else
  OS_NAME="$(lsb_release -ds 2>/dev/null || echo Linux)"
fi
HOSTNAME="$(hostname)"

TMP_FILE="$(mktemp)"
sed -e "s/{{OS_NAME}}/${OS_NAME//\//\\/}/g" \
    -e "s/{{HOSTNAME}}/${HOSTNAME//\//\\/}/g" \
    -e "s/{{FULL_NAME}}/${FULL_NAME//\//\\/}/g" \
    -e "s/{{STUDENT_ID}}/${STUDENT_ID//\//\\/}/g" \
    -e "s/{{DEADLINE}}/${DEADLINE//\//\\/}/g" \
    nettech_program/index_template.html > "${TMP_FILE}"

sudo mv "${TMP_FILE}" /var/www/nettech/index.html
sudo chown www-data:www-data /var/www/nettech/index.html

echo "[7/8] Firewall"
sudo ufw allow OpenSSH
sudo ufw allow "Nginx Full"
sudo ufw --force enable
sudo ufw status verbose

echo "[8/8] Done."
echo "Visit http://<VM-IP>/"
