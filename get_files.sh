#!/usr/bin/env bash

set -euxo pipefail

BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.bin"
CONSUL_TEMPLATE_VERSION="0.20.0"
CONSUL_VERSION="1.4.4"
NOMAD_VERSION="0.8.7"
VAULT_VERSION="1.1.1"

consul_file="consul-enterprise_${CONSUL_VERSION}+prem_"
consul_template_file="consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip"
nomad_file="nomad-enterprise_${NOMAD_VERSION}+ent_"
vault_file="vault-enterprise_${VAULT_VERSION}+prem_"

if hash aws 2>/dev/null; then
    echo "Using aws cli version $(aws --version 2>&1)"
else
    echo "Error - Amazon Web Services cli not installed!"
    exit 1
fi

mkdir -p "${BINDIR}"

for arch in darwin_amd64 linux_amd64; do

    if [[ ! -e ${BINDIR}/${consul_file}${arch}.zip ]]; then
        aws s3 cp "s3://hc-enterprise-binaries/consul/prem/${CONSUL_VERSION}/${consul_file}${arch}.zip" "${BINDIR}"
    fi

    if [[ ! -e ${BINDIR}/${nomad_file}${arch}.zip ]]; then
        aws s3 cp "s3://hc-enterprise-binaries/nomad-enterprise/${NOMAD_VERSION}/${nomad_file}${arch}.zip" "${BINDIR}"
    fi

    if [[ ! -e ${BINDIR}/${vault_file}${arch}.zip ]]; then
        aws s3 cp "s3://hc-enterprise-binaries/vault/prem/${VAULT_VERSION}/${vault_file}${arch}.zip" "${BINDIR}"
    fi
done

if [[ ! -e ${BINDIR}/${consul_template_file} ]]; then
    curl -L https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/${consul_template_file} -o "${BINDIR}/${consul_template_file}"
fi
