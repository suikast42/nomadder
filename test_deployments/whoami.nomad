job "whoami" {
  datacenters = ["nomadder1"]

  group "whoami" {
    count = 1

    network {
      mode = "bridge"
      port "web" {
      }
    }

    service {
      name = "whoami"
      port = "web"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.whoami.rule=Host(`whoami.cloud.private`)",
        "traefik.http.routers.whoami.tls=true",
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
#      driver = "containerd-driver"
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