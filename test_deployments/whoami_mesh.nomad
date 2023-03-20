job "whoami" {
  datacenters = ["nomadder1"]

  group "whoami" {
    count = 2

    network {
      mode = "bridge"

      port "web" {}
    }

    service {
      name = "whoami"
      port = "web"

      connect {
        sidecar_service {}
        sidecar_task{
          config{
            labels = {
              "com.github.logunifier.application.name" = "envoy"
            }
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.whoami.tls=true",
        "traefik.http.routers.whoami.rule=Host(`whoami.cloud.private`)",
      ]

      check {
        type     = "http"
        path     = "/health"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "whoami" {
      driver = "docker"
      config {
        image = "traefik/whoami"
        ports = ["web"]
        args  = ["--port", "${NOMAD_PORT_web}"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}