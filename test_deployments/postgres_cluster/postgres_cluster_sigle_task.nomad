variable "host_1" {
  type        = string
  description = "host1"
  default     = "192.168.30.124"
}

variable "host_2" {
  type        = string
  description = "host2"
  default     = "192.168.30.125"
}

variable "host_3" {
  type        = string
  description = "host3"
  default     = "192.168.30.126"
}

variable "image" {
  type        = string
  description = "image"
  default     = "timescale/timescaledb-ha:pg18.6-ts2.30.2"
}

job "timescaledb-ha" {
  type        = "service"

  group "pg1" {
    count = 1

    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "worker-01"
    }

    network {
      mode = "host"

      port "pg" { static = 5432 }
      port "patroni"  { static = 8008 }
      port "raft"     { static = 5010 }
    }

    # volume "pgdata" {
    #   type      = "host"
    #   source    = "pgdata"
    #   read_only = false
    # }

    task "postgres" {
      driver = "docker"

      config {
        image = "${var.image}"
        command = "patroni"
        ports = ["pg", "patroni", "raft"]
        args    = ["/home/postgres/postgres.yml"]
        volumes = [
          "local/patroni.yml:/home/postgres/postgres.yml",
        ]
      }

      # volume_mount {
      #   volume      = "pgdata"
      #   destination = "/home/postgres/pgdata"
      # }

      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "postgres"


      }

      template {
        data = <<-EOF
        scope: scada-postgres-cluster
        namespace: /service
        name: patroni-1

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
              password: Replicator123!
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

  group "pg2" {
    count = 1

    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "worker-02"
    }

    network {
      mode = "host"
      port "pg" { static = 5432 }
      port "patroni"  { static = 8008 }
      port "raft"     { static = 5010 }
    }

    # volume "pgdata" {
    #   type      = "host"
    #   source    = "pgdata"
    #   read_only = false
    # }

    task "postgres" {
      driver = "docker"

      config {
        image = "${var.image}"
        command = "patroni"
        args    = ["/home/postgres/postgres.yml"]
        volumes = [
          "local/patroni.yml:/home/postgres/postgres.yml",
        ]
        ports = ["pg", "patroni", "raft"]
      }

      # volume_mount {
      #   volume      = "pgdata"
      #   destination = "/home/postgres/pgdata"
      # }

      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "postgres"


      }
      template {
        data = <<-EOF
        scope: scada-postgres-cluster
        namespace: /service
        name: patroni-2

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
              password: Replicator123!
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

  group "pg3" {
    count = 1

    constraint {
      attribute = "${attr.unique.hostname}"
      value     = "worker-03"
    }

    network {
      mode = "host"
      port "pg" { static = 5432 }
      port "patroni"  { static = 8008 }
      port "raft"     { static = 5010 }
    }

    # volume "pgdata" {
    #   type      = "host"
    #   source    = "pgdata"
    #   read_only = false
    # }

    task "postgres" {
      driver = "docker"

      config {
        image = "${var.image}"
        command = "patroni"
        args    = ["/home/postgres/postgres.yml"]
        volumes = [
          "local/patroni.yml:/home/postgres/postgres.yml",
        ]
        ports = ["pg", "patroni", "raft"]
      }

      # volume_mount {
      #   volume      = "pgdata"
      #   destination = "/home/postgres/pgdata"
      # }

      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "postgres"

      }

      template {
        data = <<-EOF
        scope: scada-postgres-cluster
        namespace: /service
        name: patroni-3

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
              password: Replicator123!
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
