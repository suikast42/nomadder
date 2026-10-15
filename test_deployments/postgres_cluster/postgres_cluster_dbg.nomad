variable "tls" {
  type        = string
  description = "server tls"
  default     = "tdp.private"
}

job "postgres-ha" {
  datacenters = ["dc_nomad1", "dc_nomad2"]
  type = "service"

  group "database" {
    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
    }
    volume "cert_consul" {
      type      = "host"
      source    = "cert_consul"
      read_only = true
    }
    count = 3

    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    network {
      mode = "host"
      port "pg" {
        to = 5432
      }
      port "patroni" {
        to = 8008
      }
      port "raft" {
        to = 5010
        static = 5010
      }

    }

    task "patroni" {

      driver = "docker"
      # patroni /local/patroni.yml --validate-config
      config {
        image = "amovatdp/timescaledb-ha:pg18.6-ts2.30.2"
        ports = ["pg", "patroni"]
        entrypoint  = ["tail", "-f", "/dev/null"]
        volumes = [
          "local/patroni.yml:/home/postgres/postgres.yml",
        ]
      }
      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "postgres"

        PATRONI_LOG_LEVEL     = "DEBUG"
        PATRONI_CONFIGURATION = "/home/postgres/postgres.yml"

        # PATRONI_CONSUL_HOST = "${attr.unique.network.ip-address}:8501"
        # PATRONI_CONSUL_SCHEME="https"
        # PATRONI_CONSUL_VERIFY="true"
        # PATRONI_CONSUL_CACERT ="/etc/ssl/certs/cluster-ca-bundle.pem"
        # PATRONI_CONSUL_CERT="/etc/opt/certs/consul/consul.pem"
        # PATRONI_CONSUL_KEY ="/etc/opt/certs/consul/consul-key.pem"
        # PATRONI_CONSUL_DC="dc_nomad1"

      }
      // Need for os level action like git
      volume_mount {
        # OS certifate folders
        #  "/etc/ssl/certs/ca-certificates.crt",              // Debian/Ubuntu/Gentoo etc.
        #"/etc/pki/tls/certs/ca-bundle.crt",                  // Fedora/RHEL 6
        #"/etc/ssl/ca-bundle.pem",                            // OpenSUSE
        #"/etc/pki/tls/cacert.pem",                           // OpenELEC
        #"/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem", // CentOS/RHEL 7
        #"/etc/ssl/cert.pem",                                 // Alpine Linux
        volume      = "ca_cert"
        destination = "/etc/ssl/certs/"
      }
      volume_mount {
        volume      = "cert_consul"
        destination = "/etc/opt/certs/consul"
      }

      template {
        data = <<-EOF
        scope: scada-postgres-cluster
        namespace: /service
        name: patroni-{{ env "NOMAD_ALLOC_INDEX" }}

        raft:
          data_dir: /var/lib/postgresql/raft
          self_addr: {{ env "NOMAD_HOST_IP_patroni" }}:5010
          partner_addrs:
          {{- range datacenters -}}
            {{- range nodes (printf "@%s" .) }}
              {{- if and (ne .Address (env "NOMAD_HOST_IP_patroni")) (eq (index .Meta "node_type") "worker") }}
            - {{ .Address }}:5010
              {{- end }}
            {{- end }}
          {{- end }}

        restapi:
          listen: 0.0.0.0:{{ env "NOMAD_PORT_patroni" }}
          connect_address: {{ env "NOMAD_ADDR_patroni" }}

        bootstrap:
          dcs:
            ttl: 30
            loop_wait: 10
            retry_timeout: 10
            maximum_lag_on_failover: 1048576
            postgresql:
              use_pg_rewind: true
              use_slots: true
              parameters:
                wal_level: replica
                hot_standby: "on"
                max_connections: 100
                max_worker_processes: 8
                wal_keep_segments: 8
                max_wal_senders: 10
                max_replication_slots: 10
                max_prepared_transactions: 0
                max_locks_per_transaction: 64
                wal_log_hints: "on"
                track_commit_timestamp: "off"
                archive_mode: "on"
                archive_timeout: 1800s
                archive_command: mkdir -p ../wal_archive && test ! -f ../wal_archive/%f && cp %p ../wal_archive/%f
                shared_preload_libraries: 'timescaledb'
              recovery_conf:
                restore_command: cp ../wal_archive/%f %p

          initdb:
            - encoding: UTF8
            - data-checksums

          pg_hba:
            - host replication replicator 0.0.0.0/0 md5
            - host all all 0.0.0.0/0 md5

        postgresql:
          listen: 0.0.0.0:{{ env "NOMAD_PORT_pg" }}
          connect_address: {{ env "NOMAD_ADDR_pg" }}
          data_dir: /var/lib/postgresql/data/patroni
          bin_dir: /usr/lib/postgresql/18/bin
          authentication:
            replication:
              username: replicator
              password: ChangeMeSecurely123!
            rewind:
              username: rewind_user
              password: RewindPassword123!
            superuser:
              username: {{ env "POSTGRES_USER" }}
              password: {{ env "POSTGRES_PASSWORD" }}

        EOF

        destination = "local/patroni.yml"
      }

      resources {
        cpu    = 2000
        memory = 4096
      }


    }
  }
}
