job "kafka-zk-XXX1-telemetry" {

  type = "service"

  group "kafka-zk-XXX1" {

    count = 3

    meta {
      cert_ttl            = "168h"
      cluster_dc          = "XXX1"
      mtls_path           = "/path/to/kafka/mtls"
      int_ca_path         = "/path/to/intca/ca"
      root_ca_path        = "/path/to/rootca/ca"
    }

    # Run tasks in serial or parallel (1 for serial)
    update {
      max_parallel = 1
      min_healthy_time = "1m"
    }

    restart {
      attempts = 3
      interval = "10m"
      delay    = "30s"
      mode     = "fail"
    }

    migrate {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    ephemeral_disk {
      migrate = false
      size    = "500"
      sticky  = false
    }

    task "kafka-zk-XXX1" {
      driver = "docker"
      config {
        image = "kafka-zookeeper-3.5.5"
        entrypoint = ["/conf/entrypoint.sh"]
        command = "zkServer.sh start-foreground"
        labels {
          group = "zk-docker"
        }
        network_mode = "host"
        port_map {
          client = 2181
          peer1 = 2888
          peer2 = 3888
          jmx = 9999
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }

      env {
        ZOO_CONF_DIR="/conf"
        ZOO_DATA_DIR="/data"
        ZOO_LOG4J_PROP="INFO,CONSOLE"
        ZK_WAIT_FOR_CONSUL_SVC="30"
        ZK_CLIENT_SVC_NAME="kafka-zk-XXX1-client"
        ZK_PEER1_SVC_NAME="kafka-zk-XXX1-peer1"
        ZK_PEER2_SVC_NAME="kafka-zk-XXX1-peer2"
      }

      kill_timeout = "15s"

      resources {
        cpu = 1000
        memory = 1024
        network {
          mbits = 100
          port "client" {}
          port "secure_client" {
            static = 2281
          }
          port "peer1" {}
          port "peer2" {}
          port "jmx" {}
          port "jolokia" {}
        }
      }
      service {
        port = "client"
        name = "kafka-zk-XXX1-telemetry-client"
        tags = [
          "kafka-zk-XXX1-telmetry-client",
          "peer1_port=$${NOMAD_HOST_PORT_peer1}",
          "peer2_port=$${NOMAD_HOST_PORT_peer2}",
          "alloc_index=$${NOMAD_ALLOC_INDEX}"
        ]
      }
      service {
        port = "secure_client"
        name = "kafka-zk-XXX1-telemetry-secure-client"
        tags = [
          "kafka-zk-XXX1-telmetry-secure-client"
        ]
        check {
          name     = "secure-client-check"
          port     = "secure_client"
          type     = "tcp"
          interval = "30s"
          timeout  = "2s"
          initial_status = "passing"
        }
      }
      service {
        port = "peer1"
        name = "kafka-zk-XXX1-telmetry-peer1"
        tags = [
          "kafka-zk-XXX1-telemetry-peer1"
        ]
      }
      service {
        port = "peer2"
        name = "kafka-zk-XXX1-telemetry-peer2"
        tags = [
          "kafka-zk-XXX1-telmetry-peer2"
        ]
      }

      vault {
        policies = ["allow_vault"]
        change_mode = "noop"
      }

      # consul template used to create the zoo.cfg.dyamic file within the entrypoint script.
      template {
        destination = "local/conf/zoo.cfg.dynamic.ctpl"
        change_mode = "noop"
        data = <<EOF
{{ range $_, $instance := service (printf "%s|passing" (env "ZK_CLIENT_SVC_NAME")) -}}
{{ range $_, $alloc_index_tag := $instance.Tags }}{{ if $alloc_index_tag | regexMatch "alloc_index=(d+)" -}}
{{ range $_, $peer1_port_tag := $instance.Tags }}{{ if $peer1_port_tag | regexMatch "peer1_port=(d+)" -}}
{{ range $_, $peer2_port_tag := $instance.Tags }}{{ if $peer2_port_tag | regexMatch "peer2_port=(d+)" -}}
server.{{ $alloc_index_tag | replaceAll "alloc_index=" "" | parseInt | add 1 }}={{ $instance.Address }}:{{ $peer1_port_tag | replaceAll "peer1_port=" "" }}:{{ $peer2_port_tag | replaceAll "peer2_port=" "" }};{{ $instance.Port }}
{{ end }}{{ end }}{{ end }}{{ end }}{{ end }}{{ end }}{{ end }}
EOF
      }
      # Generate a myid file, which is copied to /data/myid by the entrypoint script.
      template {
        destination = "local/conf/myid"
        change_mode = "noop"
        data = <<EOF
{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}
EOF
      }
      # as zookeeper dynamically updates zoo.cfg we template to zoo.cfg.tmpl and in the docker-entrypoint.sh of the image copy to zoo.cfg.
      # this prevents the allocation from throwing an error when zookeeper updates zoo.cfg
      template {
        destination = "local/conf/zoo.cfg.tmpl"
        change_mode = "noop"
        data = <<EOF
{{ $mtls_path := env "NOMAD_META_mtls_path" -}}
admin.enableServer=false
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=false
reconfigEnabled=true
skipACL=yes
4lw.commands.whitelist=*
secureClientPort={{ env "NOMAD_PORT_secure_client" }}
serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
sslQuorum=true
ssl.quorum.hostnameVerification=false
ssl.quorum.keyStore.location=/conf/ssl/keystore.jks
ssl.quorum.keyStore.password={{ with secret (printf "%s" $mtls_path) }}{{ .Data.keystore_password }}{{ end }}
ssl.quorum.trustStore.location=/conf/ssl/truststore.jks
ssl.quorum.trustStore.password={{ with secret (printf "%s" $mtls_path) }}{{ .Data.truststore_password }}{{ end }}
authProvider.1=org.apache.zookeeper.server.auth.X509AuthenticationProvider
ssl.hostnameVerification=false
ssl.keyStore.location=/conf/ssl/keystore.jks
ssl.keyStore.password={{ with secret (printf "%s" $mtls_path) }}{{ .Data.keystore_password }}{{ end }}
ssl.trustStore.location=/conf/ssl/truststore.jks
ssl.trustStore.password={{ with secret (printf "%s" $mtls_path) }}{{ .Data.truststore_password }}{{ end }}
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      template {
        destination = "local/conf/jvm_flags.sh"
        change_mode = "noop"
        data = <<EOF
#!/usr/bin/env bash
export
SERVER_JVMFLAGS="-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory -Dcom.sun.management.jmxremote.host={{ env "NOMAD_IP_jmx" }} -javaagent:/apache-zookeeper/lib/jolokia-jvm-agent.jar=port={{ env "NOMAD_PORT_jolokia" }},host={{ env "NOMAD_IP_jolokia" }}"
export JMXPORT="{{ env "NOMAD_PORT_jmx" }}"
EOF
      }
      template {
        destination = "local/conf/entrypoint.sh"
        change_mode = "noop"
        data = <<EOF
#!/usr/bin/env bash
set -e

# sleep to allow nomad services to be registered in consul and for zookeeper-watcher to run after service changes
if [[ -z "${ZK_WAIT_FOR_CONSUL_SVC}" ]]; then
    sleep 30 # reasonable default
else
    sleep $ZK_WAIT_FOR_CONSUL_SVC
fi

# if zoo.cfg.tmpl exists copy to zoo.cfg
if [[ -f "$ZOO_CONF_DIR/zoo.cfg.tmpl" ]]; then
    cp $ZOO_CONF_DIR/zoo.cfg.tmpl $ZOO_CONF_DIR/zoo.cfg
fi

# create the zookeeper dynamic cfg from consul template
if [[ -z "${CONSUL_HTTP_ADDR}" ]]; then
    consul-template -once -template /consul-templates/zoo.cfg.dynamic.ctpl:$ZOO_CONF_DIR/zoo.cfg.dynamic
else
    consul-template -once -consul-addr=${CONSUL_HTTP_ADDR} -template /consul-templates/zookeeper-services.ctpl:$ZOO_CONF_DIR/zoo.cfg.dynamic
fi

# create truststore and keystore from pem files if they exist
if [[ -f "$ZOO_CONF_DIR/ssl/root-int-ca.pem" && -f "$ZOO_CONF_DIR/ssl/node.pem" ]]; then

    if [[ -f "$ZOO_CONF_DIR/ssl/truststore.jks" ]]; then
        rm "$ZOO_CONF_DIR/ssl/truststore.jks"
    fi
    if [[ -f "$ZOO_CONF_DIR/ssl/keystore.jks" ]]; then
        rm "$ZOO_CONF_DIR/ssl/keystore.jks"
    fi

    # create truststore jks
    echo "create truststore.jks"

    # pull truststore from zoo.cfg
    truststore_password="$(grep ssl.trustStore.password= $ZOO_CONF_DIR/zoo.cfg | egrep -o '[^=]+$')"
    keytool -import -alias root-int-ca -trustcacerts -file $ZOO_CONF_DIR/ssl/root-int-ca.pem -noprompt
      -keystore $ZOO_CONF_DIR/ssl/truststore.jks -storepass $truststore_password

    # create keystore jks
    echo "create keystore.jks"

    # pull keystore password from zoo.cfg
    keystore_password="$(grep ssl.keyStore.password= $ZOO_CONF_DIR/zoo.cfg | egrep -o '[^=]+$')"
    openssl pkcs12 -export -in $ZOO_CONF_DIR/ssl/node.pem -out $ZOO_CONF_DIR/ssl/node.p12 -passout pass:$keystore_password
    keytool -importkeystore -srckeystore $ZOO_CONF_DIR/ssl/node.p12 -srcstoretype PKCS12
      -destkeystore $ZOO_CONF_DIR/ssl/keystore.jks -srcstorepass $keystore_password -deststorepass $keystore_password
fi

# myid is generated by Nomad job (myid = allocation index + 1)
cp $ZOO_CONF_DIR/myid $ZOO_DATA_DIR/myid

# source in SERVER_JVMFLAGS and CLIENT_JVMFLAGS
. $ZOO_CONF_DIR/jvm_flags.sh

# Allow the container to be started with `--user`
if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR"
    echo "gosu zookeeper $@"
    exec gosu zookeeper "$@"
else
    exec "$@"
fi
EOF
      }
      template {
        destination = "path/to/root-int-ca.pem"
        change_mode = "restart"
        data = <<EOH
{{ $root_ca_path := env "NOMAD_META_root_ca_path" -}}
{{ $int_ca_path := env "NOMAD_META_int_ca_path" -}}
{{ with secret (printf "%s" $int_ca_path) }}
{{ .Data.certificate -}}
{{ end -}}
{{ with secret (printf "%s" $root_ca_path) }}
{{ .Data.certificate -}}
{{ end }}
EOH
      }
      template {
        destination = "path/to/ssl/sl/node.pem"
        change_mode = "restart"
        data = <<EOH
{{ $ip_address := env "NOMAD_IP_client" -}}
{{ $vault_cert_path := env "NOMAD_META_vault_cert_path" -}}
{{ $cluster_dc := env "NOMAD_META_cluster_dc" -}}
{{ $cert_ttl := env "NOMAD_META_cert_ttl" -}}
{{ with secret (printf "%s" $vault_cert_path) (printf "common_name=zk-%s.service.%s.consul" $cluster_dc $cluster_dc) (printf "alt_names=zk-%s.service.%s.consul" $cluster_dc $cluster_dc) (printf "ip_sans=%s" $ip_address) (printf "ttl=%s" $cert_ttl) (printf "format=pem_bundle") }}
{{ .Data.certificate -}}
{{ end }}
EOH
      }
    }
  }
}