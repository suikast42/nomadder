# Sample nexus as service mesh
# This approach is weak for air gaped approach. If someone delete the nexus image over docker system prune -all
# Then u need access to dockerhub again.
# Nexus is hosted on the builder node as a compose deployment and is backed up as a tar file.

job "registry" {
  datacenters = ["nomadder1"]
  type        = "service"

  group "nexus" {
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "worker-01"
  }
  volume "nexus_workdir" {
    type      = "host"
    source    = "nexus_workdir"
    read_only   = false
  }
    count = 1
    restart {
      attempts = 3
      delay    = "10s"
      interval = "1m"
      mode     = "fail"
    }
    network {
      mode = "bridge"
      port "ui" { to = 8081 }
      # Set by poststart service
      port "pull" { to = 5000 }
      # Set by poststart service
      port "push" { to = 5001 }
    }
    service {
      name = "nexus-ui"
      port = "8081"
      connect {
        sidecar_service {}
      }
      tags = [
        # Nexus UI
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.nexus-ui.tls=true",
        "traefik.http.routers.nexus-ui.rule=Host(`nexus.cloud.private`)",
      ]
      check {
        name     = "health"
        type     = "http"
        port     = "ui"
        path     = "service/rest/v1/status"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit           = 5
          grace           = "60s"
          ignore_warnings = false
        }
      }
    }
    service {
      name = "nexus-pull"
      port = "5000"
      connect {
        sidecar_service {}
      }
      tags = [
        # Nexus pull
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.nexus-pull.tls=true",
        "traefik.http.routers.nexus-pull.rule=Host(`registry.cloud.private`) && Method(`GET`,`HEAD`)"
      ]
  #    check {
  #      name     = "alive"
  #      type     = "script"
  #      task     = "nexus"
  #      command  = "curl -k https://nexus.cloud.private/repository/dockerGroup/"
  #      interval = "10s"
  #      timeout  = "2s"
  #    }
    }
    service {
      name = "nexus-push"
      port = "5001"
      connect {
        sidecar_service {}
      }
      tags = [
        # Nexus pull
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.nexus-push.tls=true",
        "traefik.http.routers.nexus-push.rule=Host(`registry.cloud.private`) && Method(`POST`,`PUT`,`DELETE`,`PATCH`)"
      ]

    }
    task "nexus" {

      driver = "docker"
      env {
        #leave the default password as admin 123
        NEXUS_SECURITY_RANDOMPASSWORD = false
      }
     volume_mount {
        volume      = "nexus_workdir"
        destination = "/opt/sonatype/sonatype-work"
     }
      config {
        image = "sonatype/nexus3:3.41.1"
      #  ports = ["ui", "pull", "push"]
      }

      resources {
        cpu    = 100
        memory = 4096
      }
    }
    task "nexus-initzlr" {
      driver = "docker"

      config {
        image = "suikast42/nexus-initlzr:1.0.0.Alpha4"
      }

      resources {
        cpu    = 200
        memory = 128
      }

      lifecycle {
        hook    = "poststart"
        sidecar = false
      }
    }
  }
}