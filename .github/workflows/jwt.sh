#!/bin/sh

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

secret=${env.GRADE_SECRET}
id=${env.GITHUB_NAME}
sha=${env.GITHUB_SHA}
iat="$(date +%s)"
exp=$(echo "$iat + 300" | bc)

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
signature=$(echo "${header_payload}" | hmacsha256_sign | base64_encode)

echo "${header_base64}.${payload_base64}.${signature}"