
job "mysql-server" {
  datacenters = ["nomadder1"]
  type        = "service"

  group "mysql-server" {
    count = 1

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }
    constraint {
      attribute = "${meta.host.index}"
      value     = "${NOMAD_ALLOC_INDEX}"
    }
    volume "mysql" {
      type      = "host"
      read_only = false
      source    = "mysql_data"
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "mysql-server" {
      driver = "docker"

      volume_mount {
        volume      = "mysql"
        destination = "/var/lib/mysql"
        read_only   = false
      }

      env = {
        "MYSQL_ROOT_PASSWORD" = "password"
      }

      config {
        image = "hashicorp/mysql-portworx-demo:latest"

        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "mysql-server-${NOMAD_ALLOC_INDEX}"
        port = "db"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    network {
      port "db" {
        static = 3306
      }
    }
  }
}
