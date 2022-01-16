#!/bin/sh

secret=${env.JWT_SECRET}
id=${env.GITHUB_NAME}
sha=${env.GITHUB_SHA}

header=$( jq --null-input \
    --arg typ "JWT" \
    --arg alg "HS256" \
    '{"typ":$typ,"alg":$alg}')

header=$(
    echo "${header}" | jq --arg time_str "$(date +%s)" \
    '
    ($time_str | tonumber) as $time_num
    | .iat=$time_num
    | .exp=($time_num + 300)
    '
)

payload=$(jq --null-input \
    --arg id "${id}" \
    --arg sha "${sha}" \
    '{"id": $id, "sha": $sha}')

base64_encode()
{
    declare input=${1:-$(</dev/stdin)}
    # Use `tr` to URL encode the output from base64.
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

header_base64=$(echo "${header}" | json | base64_encode)
payload_base64=$(echo "${payload}" | json | base64_encode)

header_payload=$(echo "${header_base64}.${payload_base64}")
signature=$(echo "${header_payload}" | hmacsha256_sign | base64_encode)

echo "${header_payload}.${signature}"