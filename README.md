# Setup

## Prepare 
1. You need at least 2 Ubuntu Vms ( 24.04 ) zu can use vagrant up from vagrant folder for this
2. Adopt your machines under the path ENVIRONMENT un .evrc file

## Install

1. ansible-playbook 00_basic_setup_playbook.yml  --ask-vault-pass  ( install all os deps )
2. ansible-playbook 01_platform_playbook.yml  --ask-vault-pass. This playbook wilkl fail because of     because of [issue](https://github.com/suikast42/nomadder/issues/165) 
3. ansible-playbook 01_platform_playbook.yml  --ask-vault-pass --extra-vars="uninstall_all=true, update_certificates=true"
    because of [issue](https://github.com/suikast42/nomadder/issues/165)
