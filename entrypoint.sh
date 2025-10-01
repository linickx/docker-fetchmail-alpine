#!/bin/bash

# Who are we forwarding mail to?
if [ -z "$RELAY_TO_EMAIL" ]; then
  echo "ERROR -- RELAY_TO_EMAIL is not set. Exiting."
  exit 1
fi

#
# POP3 or IMAP Polling Server Options
#

if [ -z "$POLL_SERVER" ]; then
  echo "ERROR -- POLL_SERVER is not set. Exiting."
  exit 1
fi
if [ -z "$POLL_USER" ] || [ -z "$POLL_PASSWORD" ]; then
  echo "ERROR -- POLL_USER or POLL_PASSWORD is not set. Exiting."
  exit 1
fi

# Polling server defaults
if [ -z "$POLL_SERVER_TYPE" ]; then
  POLL_SERVER_TYPE="IMAP"
fi
if [ -z "$POLL_SERVER_PORT" ]; then
  POLL_SERVER_PORT="993"
fi
if [ -z "$POLL_SERVER_KEEP" ]; then
  POLL_SERVER_KEEP=TRUE
fi

# Poll interval default (in seconds) -- 15mins
if [ -z "$POLL_INTERVAL" ]; then
  POLL_INTERVAL="900"
fi

#
# SMTP Relay Server Options
#
if [ -z "$SMTP_SERVER" ]; then
  echo "ERROR -- SMTP_SERVER is not set. Exiting."
  exit 1
fi

if [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASSWORD" ]; then
  echo "ERROR -- SMTP_USER or SMTP_USER is not set. Exiting."
  exit 1
fi

if [ -z "$SMTP_EMAIL" ]; then
  SMTP_EMAIL="$SMTP_USER"
fi
if [ -z "$SMTP_PORT" ]; then
  SMTP_PORT="25"
fi

echo
echo "___________     __         .__                   .__.__   "
echo "\_   _____/____/  |_  ____ |  |__   _____ _____  |__|  |  "
echo " |    __)/ __ \   __\/ ___\|  |  \ /     \\__  \ |  |  |  "
echo " |     \\  ___/|  | \  \___|   Y  \  Y Y  \/ __ \|  |  |__"
echo " \___  / \___  >__|  \___  >___|  /__|_|  (____  /__|____/"
echo "     \/      \/          \/     \/      \/     \/         "
echo

#   Writing fetchmailrc
#
cat >/etc/fetchmail/fetchmailrc <<EOL
poll ${POLL_SERVER} port ${POLL_SERVER_PORT} auth password with protocol ${POLL_SERVER_TYPE}
     user '${POLL_USER}'
     password '${POLL_PASSWORD}'
     ssl
     mda "/usr/bin/msmtp --file /etc/fetchmail/msmtprc -- ${RELAY_TO_EMAIL}"
     ${POLL_SERVER_KEEP:+keep}    
EOL
echo "----------[/etc/fetchmail/fetchmailrc]--------------------"
grep -vE '[ ]{2,}password' /etc/fetchmail/fetchmailrc # Show config without password
echo

#
#   Writing msmtprc
#
cat >/etc/fetchmail/msmtprc <<EOL
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account default
host ${SMTP_SERVER}
port ${SMTP_PORT}
tls_starttls on
from ${SMTP_EMAIL}
user ${SMTP_USER}
password ${SMTP_PASSWORD}
EOL
echo "-----------[/etc/fetchmail/msmtprc]-----------------------"
grep -v password /etc/fetchmail/msmtprc
echo

echo "----------------------------------------------------------"
chmod -v 600 /etc/fetchmail/fetchmailrc
chmod -v 600 /etc/fetchmail/msmtprc
echo "----------------------------------------------------------"
#
# GO! Start fetchmail in daemon mode
#
echo
echo "Starting fetchmail as daemon, polling every ${POLL_INTERVAL} seconds..."
echo
fetchmail --nodetach --fetchmailrc /etc/fetchmail/fetchmailrc --daemon "${POLL_INTERVAL}"