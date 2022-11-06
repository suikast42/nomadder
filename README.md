# Test Nomad installation

# Core Systemd services
1. Install Vault
2. Install Consul
3. Cert configexport NOMAD_ADDR=https://localhost:4646
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

4. DnsMasq?

# Nomad installation
1. Server
2. Client
3. Docker daemon 

# Cluster level services
1. Ingress ( Traefik )
2. Registry ( Nexus )