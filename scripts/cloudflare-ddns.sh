#/usr/bin/env sh

####### IMPORTANT LICENSE NOTICE! #################################
# *  Code taken from https://www.rohanjain.in/cloudflare-ddns/  * #
###################################################################

# Get the Zone ID from: https://www.cloudflare.com/a/overview/<your-domain>
DNS_ZONE=<your-dns-zone>

# Get the existing identifier for DNS entry:
# https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records
IDENTIFIER=<your-domain-dns-entry-identifier>

# Get these from: https://www.cloudflare.com/a/account/my-account
AUTH_EMAIL=<cloudflare-auth-email>
AUTH_KEY=<cloudflare-auth-key>

# Desired domain name
DOMAIN_NAME="<subdomain>.<your-domain>"

# Get previous IP address
_PREV_IP_FILE="/tmp/public-ip.txt"
_PREV_IP=$(cat $_PREV_IP_FILE &> /dev/null)

# Install `dig` via `dnsutils` for faster IP lookup.
command -v dig &> /dev/null && {
    _IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
} || {
    _IP=$(curl --silent https://api.ipify.org)
} || {
    exit 1
}

# If new/previous IPs match, no need for an update.
if [ "$_IP" = "$_PREV_IP" ]; then
    exit 0
fi

_UPDATE=$(cat <<EOF
{ "type": "A",
  "name": "$DOMAIN_NAME",
  "content": "$_IP",
  "ttl": 120,
  "proxied": false }
EOF
)

curl "https://api.cloudflare.com/client/v4/zones/$DNS_ZONE/dns_records/$IDENTIFIER" \
     --silent \
     -X PUT \
     -H "Content-Type: application/json" \
     -H "X-Auth-Email: $AUTH_EMAIL" \
     -H "X-Auth-Key: $AUTH_KEY" \
     -d "$_UPDATE" > /tmp/cloudflare-ddns-update.json && \
     echo $_IP > $_PREV_IP_FILE
