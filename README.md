# Setup


## Prepare 
### From master node

1. After checkut the project you have to create in `/ansible/setup/vars` with `ansible-vault create local_secret.yml` and the content `ansible_become_pass: <PASSWORD>`. 
2.Create in /envrionment/local/ssh/<host> your ssh keys and import in all nodes
## TODO 
 add env vars zo .zshenv
 export  WILDFLY_HOME=~/wildfly

export TLS_SAN=cloud.private
export ENVIRONMENT=dev
export NOMAD_ADDR=https://localhost:4646
export NOMAD_CACERT=/usr/local/share/ca-certificates/cloudlocal/cluster-ca-bundle.pem
export NOMAD_CLIENT_CERT=/etc/opt/certs/nomad/nomad-cli.pem
export NOMAD_CLIENT_KEY=/etc/opt/certs/nomad/nomad-cli-key.pem

export CONSUL_HTTP_SSL=true
export CONSUL_HTTP_SSL_VERIFY=true
export CONSUL_HTTP_ADDR=127.0.0.1:8501
export CONSUL_HTTP_TOKEN=e95b599e-166e-7d80-08ad-aee76e7ddf19
export CONSUL_CACERT=/usr/local/share/ca-certificates/cloudlocal/cluster-ca-bundle.pem
export CONSUL_CLIENT_KEY=/etc/opt/certs/consul/consul-key.pem
export CONSUL_CLIENT_CERT=/etc/opt/certs/consul/consul.pem
$ nomad -autocomplete-install
$ consul -autocomplete-install

### WSL2 or from provisioning node
1. You need at least 2 Ubuntu Vms ( 24.04 ) zu can use vagrant up from vagrant folder for this
2. Adopt your machines under the path ENVIRONMENT un .evrc file

## Install

1. ansible-playbook 00_basic_setup_playbook.yml  --ask-vault-pass  ( install all os deps )
2. ansible-playbook 01_platform_playbook.yml  --ask-vault-pass. This playbook wilkl fail because of     because of [issue](https://github.com/suikast42/nomadder/issues/165) 
3. ansible-playbook 01_platform_playbook.yml  --ask-vault-pass --extra-vars="uninstall_all=true, update_certificates=true"
    because of [issue](https://github.com/suikast42/nomadder/issues/165)
