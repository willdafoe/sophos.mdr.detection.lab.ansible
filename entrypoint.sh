#!/bin/bash
set -eo pipefail

ansible-galaxy install -r requirements.yml

if [ ! -z "$ANSIBLE_VAULT_PASSWORD" ]
then
     echo $ANSIBLE_VAULT_PASSWORD >> .vault;
     ansible-playbook $1 --vault-password-file .vault \
        --extra-vars $2
else
    ansible-playbook $1 --extra-vars $2
fi