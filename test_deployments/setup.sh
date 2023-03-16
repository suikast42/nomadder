dnf update -y
dnf install -y curl jq unzip

export CLUSTER_DC=fra1
export CLUSTER_PRIMARY_DC=fra1
export CLUSTER_PRIVATE_IPS=1.1.2.2,2.2.3.3,3.3.4.4
export CLUSTER_PUBLIC_IPS=1.1.1.1,2.2.2.2,3.3.3.3
export CLUSTER_SIZE=$(echo $CLUSTER_PUBLIC_IPS | jq -Rc 'split(",") | length')

export DOCKER_USERNAME=""
export DOCKER_PASSWORD=""

export HOST_NAME=$(hostname)
export HOST_PUBLIC_IP=$(hostname -I | cut -d " " -f 1)
export HOST_PRIVATE_IP=$(hostname -I | cut -d " " -f 3)


##
# NODES
##

# DOCKER

# Install Docker
dnf config-manager \
  --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

dnf config-manager \
  --set-enabled docker-ce-edge

dnf config-manager \
  --set-enabled docker-ce-test

dnf install -y docker-ce

# Start Docker
systemctl enable docker
systemctl start docker

# Generate default credentials
echo "$DOCKER_PASSWORD" | docker login \
  --username "$DOCKER_USERNAME" \
  --password-stdin

mv $HOME/.docker/config.json /etc/nomad.d/docker-config.json
chown nomad:nomad /etc/nomad.d/docker-config.json


# DNSMASQ

# Install DNSMasq
dnf install -y dnsmasq

cat << EOF > /etc/dnsmasq.d/10-consul.conf
no-poll
no-resolv
rev-server=0.0.0.0/8,127.0.0.1#8600
rev-server=10.0.0.0/8,127.0.0.1#8600
rev-server=127.0.0.1/8,127.0.0.1#8600
rev-server=169.254.0.0/16,127.0.0.1#8600
rev-server=192.168.0.0/16,127.0.0.1#8600
server=/consul/127.0.0.1#8600
server=67.207.67.2
server=67.207.67.3
server=8.8.8.8
server=8.8.4.4
EOF

cat << EOF > /etc/resolv.conf
nameserver 127.0.0.1
search localdomain
EOF

systemctl enable dnsmasq
systemctl start dnsmasq


# CONSUL
# https://www.consul.io/docs
# https://learn.hashicorp.com/consul/advanced/day-1-operations/deployment-guide
export CONSUL_BOOTSTRAP_TOKEN=
export CONSUL_ENCRYPTION_KEY=

# Create user and group
groupadd -r consul
useradd -Mr -g consul -s /usr/sbin/nologin consul

# Intall Consul
curl -LSs https://releases.hashicorp.com/consul/1.4.3/consul_1.4.3_linux_amd64.zip -o /tmp/consul.zip
unzip -oq -d /usr/local/bin /tmp/consul.zip
rm -f /tmp/consul.zip
chmod 755 /usr/local/bin/consul
chown root:root /usr/local/bin/consul
mkdir -p /etc/consul.d
mkdir -p /var/tmp/consul
chown consul:consul /var/tmp/consul

# Install autocomplete
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

# Create configuration
export CONSUL_ENCRYPTION_KEY=$(consul keygen)

cat << EOF > /etc/consul.d/config.json
{
  "advertise_addr": "${HOST_PRIVATE_IP}",
  "advertise_addr_wan": "${HOST_PUBLIC_IP}",
  "bootstrap_expect": ${CLUSTER_SIZE},
  "datacenter": "${CLUSTER_DC}",
  "primary_datacenter": "${CLUSTER_PRIMARY_DC}",
  "data_dir": "/var/tmp/consul",
  "encrypt": "${CONSUL_ENCRYPTION_KEY}",
  "server": true,
  "ui": true,
  "acl": {
    "enabled": true,
    "default_policy": "allow"
  },
  "performance": {
    "raft_multiplier": 1
  },
  "retry_join": $(echo $CLUSTER_PRIVATE_IPS | jq -Rc 'split(",")')
}
EOF

# Create service
cat << EOF > /lib/systemd/system/consul.service
[Unit]
Description=Consul
Requires=network-online.target
After=network-online.target
ConditionDirectoryNotEmpty=/etc/consul.d
[Service]
User=consul
Group=consul
RuntimeDirectory=consul
PIDFile=/var/run/consul.pid
PermissionsStartOnly=true
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d -pid-file /var/run/consul/consul.pid
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=15s
[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl enable consul
systemctl start consul

# Create ACL bootstrap token.
# Run once all Consul agents are running and a leader is elected
# https://learn.hashicorp.com/consul/advanced/day-1-operations/acl-guide#step-2-create-the-bootstrap-token
# https://learn.hashicorp.com/consul/advanced/day-1-operations/acl-guide#step-3-create-an-agent-token-policy
consul acl bootstrap \
  -datacenter ${CLUSTER_PRIMARY_DC}

export CONSUL_BOOTSTRAP_TOKEN="<consul_bootstrap_token>"

consul acl set-agent-token master ${CONSUL_BOOTSTRAP_TOKEN}


# VAULT
# https://www.vaultproject.io/docs
# https://learn.hashicorp.com/vault/day-one/ops-vault-ha-consul
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=""

# Create user and group
groupadd -r vault
useradd -Mr -g vault -s /usr/sbin/nologin vault

# Install Vault
curl -LSs https://releases.hashicorp.com/vault/1.0.3/vault_1.0.3_linux_amd64.zip -o /tmp/vault.zip
unzip -oq -d /usr/local/bin /tmp/vault.zip
rm -f /tmp/vault.zip
chmod 755 /usr/local/bin/vault
chown root:root /usr/local/bin/vault
mkdir -p /etc/vault.d

# Create configuration
cat << EOF > /etc/vault.d/config.json
{
  "api_addr": "http://${HOST_PRIVATE_IP}:8200",
  "cluster_addr": "http://${HOST_PRIVATE_IP}:8201",
  "pid_file": "",
  "ui": true,
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "tls_disable": true
    }
  },
  "storage": {
    "consul": {
      "address": "127.0.0.1:8500",
      "path": "vault/"
    }
  }
}
EOF

# Create service
cat << EOF > /lib/systemd/system/vault.service
[Unit]
Description=Vault
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/config.json
[Service]
User=vault
Group=vault
RuntimeDirectory=vault
PIDFile=/var/run/vault/vault.pid
PermissionsStartOnly=true
ExecStart=/usr/local/bin/vault server -config /etc/vault.d/config.json
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=15s
LimitNOFILE=65536
LimitMEMLOCK=infinity
[Install]
WantedBy=multi-user.target
EOF

# Grant access to memory lock on host
setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

# Start service
systemctl enable vault
systemctl start vault

# Initialise and unseal.
# Run once all Vault agents are running
vault operator init

export VAULT_TOKEN="<vault_root_token>"

vault operator unseal

# Upgrade default key/value engine to v2
vault kv enable-versioning secret/

# Enable Consul engine
vault secrets enable consul

# Enable Nomad engine.
# Only once Nomad cluster is ready
vault secrets enable nomad


# NOMAD
# https://www.nomadproject.io/docs

# Create user and group
groupadd -r nomad
useradd -Mr -G docker -g nomad -s /usr/sbin/nologin nomad

# Install Nomad
curl -LSs https://releases.hashicorp.com/nomad/0.8.7/nomad_0.8.7_linux_amd64.zip -o /tmp/nomad.zip
unzip -oq -d /usr/local/bin /tmp/nomad.zip
rm -f /tmp/nomad.zip
chown root:root /usr/local/bin/nomad
chmod 755 /usr/local/bin/nomad
mkdir -p /etc/nomad.d
mkdir -p /var/tmp/nomad
chown nomad:nomad /var/tmp/nomad

# Install autocomplete
nomad -autocomplete-install
complete -C /usr/local/bin/nomad nomad

# Create configuration
cat << EOF > /etc/nomad.d/config.json
{
  "datacenter": "${CLUSTER_DC}",
  "data_dir": "/var/tmp/nomad",
  "advertise": {
    "http": "${HOST_PRIVATE_IP}",
    "rpc": "${HOST_PRIVATE_IP}",
    "serf": "${HOST_PRIVATE_IP}"
  },
  "client": {
    "enabled": true,
    "node_class": "standard",
    "options": {
      "docker.auth.config": "/etc/nomad.d/docker-config.json"
    }
  },
  "server": {
    "bootstrap_expect": ${CLUSTER_SIZE},
    "enabled": true
  },
  "consul": {
    "address": "127.0.0.1:8500",
    "auto_advertise": true,
    "client_auto_join": true
  },
  "vault": {
    "address": "http://vault.service.consul:8200",
    "enabled": true,
    "token": "${VAULT_TOKEN}"
  }
}
EOF

# Create service
cat << EOF > /lib/systemd/system/nomad.service
[Unit]
Description=Nomad
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/nomad.d/config.json
[Service]
User=nomad
Group=nomad
RuntimeDirectory=nomad
PIDFile=/var/run/nomad/nomad.pid
PermissionsStartOnly=true
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d/config.json
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=15s
[Install]
WantedBy=multi-user.target
EOF

# Start service
systemctl enable nomad
systemctl start nomad


##
# LOAD BALANCER
##

# CONSUL (CLIENT)

# Create configuration
cat << EOF > /etc/consul.d/config.json
{
  "advertise_addr": "${HOST_PRIVATE_IP}",
  "advertise_addr_wan": "${HOST_PUBLIC_IP}",
  "client_addr": "127.0.0.1 ${HOST_PUBLIC_IP}",
  "datacenter": "${CLUSTER_DC}",
  "primary_datacenter": "${CLUSTER_PRIMARY_DC}",
  "encrypt": "${CONSUL_ENCRYPTION_KEY}",
  "server": false,
  "ui": true,
  "acl": {
    "enabled": true,
    "default_policy": "allow"
  },
  "retry_join": $(echo $CLUSTER_PRIVATE_IPS | jq -Rc 'split(",")')
}
EOF

# Create service
# ...

# Start service
# ...

# Create ACL bootstrap token
# ...


# NOMAD (CLIENT)

# Create configuration
cat << EOF > /etc/nomad.d/config.json
{
  "datacenter": "${CLUSTER_DC}",
  "data_dir": "/var/tmp/nomad",
  "advertise": {
    "http": "${HOST_PRIVATE_IP}",
    "rpc": "${HOST_PRIVATE_IP}",
    "serf": "${HOST_PRIVATE_IP}"
  },
  "client": {
    "enabled": true,
    "network_adapter": "",
    "node_class": "load-balancer"
  },
  "server": {
    "enabled": false
  },
  "consul": {
    "address": "127.0.0.1:8500",
    "auto_advertise": true,
    "client_auto_join": true
  },
  "vault": {
    "address": "http://vault.service.consul:8200",
    "enabled": true,
    "token": "${VAULT_TOKEN}"
  }
}
EOF