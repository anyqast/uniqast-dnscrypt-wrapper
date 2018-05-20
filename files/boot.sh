#!/usr/bin/env sh

cd /tmp

initkeys() {
	echo '$PUBLIC_KEY or $SECRET_KEY missing, proceeding with new key pairs:'
	echo ''
	dnscrypt-wrapper --gen-provider-keypair --provider-name=2.dnscrypt-cert.anyqa.st --ext-address=255.255.255.255 --nolog --nofilter &> /dev/null
	PUBLIC_KEY=$(cat "./public.key" | base64 | tr -d '\n')
	SECRET_KEY=$(cat "./secret.key" | base64 | tr -d '\n')
	echo "PUBLIC_KEY='${PUBLIC_KEY}'"
	echo "SECRET_KEY='${SECRET_KEY}'"
	echo ''
	dnscrypt-wrapper --show-provider-publickey --provider-publickey-file "./public.key"
	echo ''
	echo 'The keys displayed above are used to encrypt and verify messages between a DNSCrypt server and a DNSCrypt client.'
	echo 'Losing the PUBLIC_KEY or SECRET_KEY displayed above means you have to generate new ones.'
	echo 'Leaking the SECRET_KEY to someone else means that this someone can now do nasty stuff with it, including MITM attacks.'
	echo 'Write down the keys above and store them at a secure place.'
	echo 'Resuming dnscrypt-wrapper start-up process with the above generated keys in 60 seconds...'
	sleep 60
}

test "${DNSCRYPT_PROVIDER_NAME:0:16}" != "2.dnscrypt-cert." && export DNSCRYPT_PROVIDER_NAME="2.dnscrypt-cert.${DNSCRYPT_PROVIDER_NAME}"

test -z "${PUBLIC_KEY}" && initkeys
test -z "${SECRET_KEY}" && initkeys

echo "${PUBLIC_KEY}" | base64 -d > "./public.key"
echo "${SECRET_KEY}" | base64 -d > "./secret.key"

for host in ${DNSCRYPT_HOSTS}; do
	for port in ${DNSCRYPT_PORTS}; do
		DNSCRYPT_HOST_PORTS="${DNSCRYPT_HOST_PORTS}
${host} ${port}"
	done
done

mkdir /tmp/supervisor.d/

id=0
echo "${DNSCRYPT_HOST_PORTS}" | grep -vE '^$' | while read host port; do
	id="$((${id}+1))"
	(
		echo "[program:dnscrypt-wrapper-${id}]"
		echo "command=/dnscrypt-wrapper.sh ${host} ${port}"
		echo "stdout_logfile=/dev/fd/1"
		echo "stdout_logfile_maxbytes=0"
		echo "redirect_stderr=true"
	) > "/tmp/supervisor.d/dnscrypt-wrapper-${id}.ini"
done

exec "/usr/bin/supervisord" "-kc/etc/supervisord.conf"
