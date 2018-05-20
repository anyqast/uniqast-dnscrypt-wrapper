#!/usr/bin/env sh

host="${1}"
port="${2}"

rollkeys() {
	keyid="${DNSCRYPT_CERT_FILE_HISTORY_SIZE}"
	while test "${keyid}" -gt "0"; do
		nextkeyid="${keyid}"
		keyid="$((${keyid}-1))"
		test -f "${host}-${port}-${keyid}.key" && test -f "${host}-${port}-${keyid}.crt" && cp "${host}-${port}-${keyid}.key" "${host}-${port}-${nextkeyid}.key" && cp "${host}-${port}-${keyid}.crt" "${host}-${port}-${nextkeyid}.crt"
	done
}

genkey() {
	dnscrypt-wrapper \
		--gen-crypt-keypair \
		--crypt-secretkey-file="${host}-${port}-0.key" &> /dev/null
	dnscrypt-wrapper \
		--gen-cert-file \
		--crypt-secretkey-file="${host}-${port}-0.key" \
		--provider-cert-file="${host}-${port}-0.crt" \
		--provider-publickey-file=public.key \
		--provider-secretkey-file=secret.key \
		--cert-file-expire-days="${DNSCRYPT_CERT_FILE_EXPIRE_DAYS}" &> /dev/null
}

if test -r "${host}-${port}-${DNSCRYPT_CERT_FILE_HISTORY_SIZE}.key"; then
	echo "Rolling key cert pair for ${host}:${port} ..."
	rollkeys
else
	echo "Rolling multiple key cert pairs for ${host}:${port} ..."
	while ! test -r "${host}-${port}-${DNSCRYPT_CERT_FILE_HISTORY_SIZE}.key"; do
		rollkeys
		genkey
	done
fi

certs=$(seq "${DNSCRYPT_CERT_FILE_HISTORY_SIZE}" | sed -r "s/^(.*)$/${host}-${port}-\1.crt/" | tr '\n' ',' | head -c-1)
keys=$( seq "${DNSCRYPT_CERT_FILE_HISTORY_SIZE}" | sed -r "s/^(.*)$/${host}-${port}-\1.key/" | tr '\n' ',' | head -c-1)

echo "${host}" | fgrep -q : && host="[${host}]"

timeout -t "$((${DNSCRYPT_CERT_FILE_ROTATION_INTERVAL}+${DNSCRYPT_CERT_FILE_ROTATION_TIMEOUT}))" -s SIGKILL \
timeout -t "${DNSCRYPT_CERT_FILE_ROTATION_INTERVAL}" -s SIGTERM \
	dnscrypt-wrapper \
		--resolver-address="${DNSCRYPT_RESOLVER_ADDRESS}" \
		--listen-address="${host}:${port}" \
		--provider-name="${DNSCRYPT_PROVIDER_NAME}" \
		--crypt-secretkey-file="${keys}" \
		--provider-cert-file="${certs}" \
		--unauthenticated \
		--user=nobody
