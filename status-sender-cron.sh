#!/usr/bin/env bash
cd /etc/letsencrypt-ssl
export HOVER_TOOL_CONFIG=$PWD/hover.config

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
NORM="$(tput sgr0)"

source <(fgrep CONTACT_EMAIL config)

if [ "$CONTACT_EMAIL" == "" ] || [[ "$CONTACT_EMAIL" == *"XXX"* ]] ; then
  echo "${RED}CONTACT_EMAIL in the config file is not set!${NORM}"
  exit 1
fi

{

  echo "Subject: [ScaryServer Maint] Let's Encrypt Health Check"
  echo "From: Scary Server <mike+ScaryServer@scalora.org>"
  echo "To: mscalora@gmail.com"
  echo "Message-Id: $(date +%s%N)"
  echo ""

  date

  echo ""
  echo "=== Hover Output ==="
  echo ""

  find certs -name cert.pem -print -exec openssl x509 -enddate -noout -in {} \;

  echo ""
  echo ""
  echo "=== Hover Output ==="
  echo ""

  /etc/letsencrypt-ssl/bin/hover.py --dns | egrep 'dyn|gogs|DNS ID'

} >/var/log/le-status.txt

cat /var/log/le-status.txt | /usr/sbin/sendmail -t
