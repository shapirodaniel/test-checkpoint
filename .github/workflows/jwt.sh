#!/bin/sh

# -------------------------------------------------------------------------- #
# this script generates a HS265-signed JWT with a payload containing
# the github user's name and the commit sha that triggered the workflow
# and expiry (exp) set 5 minutes after time issued at (iat)
# 
# the secret used to sign this token is an environment variable passed to
# the github actions step through github secrets, and should be set as a 
# global secret on the user account, so all checkpoint workflows can be 
# verified to have been generated by the user themself
# -------------------------------------------------------------------------- #

base64_encode()
{
    declare input=${1:-$(</dev/stdin)}
    printf '%s' "${input}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

json() {
    declare input=${1:-$(</dev/stdin)}
    printf '%s' "${input}" | jq -c .
}

hmacsha256_sign()
{
    declare input=${1:-$(</dev/stdin)}
    printf '%s' "${input}" | openssl dgst -binary -sha256 -hmac "${secret}"
}

secret=${GRADE_SECRET}
id=${GITHUB_NAME}
sha=${GITHUB_SHA}
iat="$(date +%s)"
exp=$(echo "$iat + 300" | bc)

echo "$secret, $id, $sha"

header=$( jq --null-input \
    --arg typ "JWT" \
    --arg alg "HS256" \
    --arg iat "${iat}" \
    --arg exp "${exp}" \
    '{"typ":$typ,"alg":$alg,"iat":$iat,"exp":$exp}')

payload=$(jq --null-input \
    --arg id "${id}" \
    --arg sha "${sha}" \
    '{"id": $id, "sha": $sha}')

header_base64=$(echo "${header}" | json | base64_encode)
payload_base64=$(echo "${payload}" | json | base64_encode)
signature=$(echo "${header}.${payload}" | hmacsha256_sign | base64_encode)

echo "${header_base64}.${payload_base64}.${signature}"