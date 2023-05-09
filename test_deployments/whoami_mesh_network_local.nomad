job "whoami" {
  datacenters = ["nomadder1"]

  group "whoami" {
    count = 3
    network {
      mode = "bridge"
      port "web" {
        to = 8080
        # The address_mode = "alloc" is used but nomad
        # exposes the bin address to its api
        # for this reason we bind the ip to localhost
        # Then nomad exposes 127.0.0.1 zto its api and the
        # protected service is not accessible from outside of the host
        # See https://github.com/hashicorp/nomad/issues/12256
        host_network = "local"
      }
      port "health" {
        to = -1
      }
    }

    service {
      name = "whoami"
      port = "8080"
      # Register the service with the container address
      # This is only accessible from inside the host
      address_mode = "alloc"
      connect {
        sidecar_service {
          proxy {
            # The health is exposed over the host ip
            expose {
              path {
                path            = "/health"
                protocol        = "http"
                local_path_port = 8080
                listener_port   = "health"
              }
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
        name     = "whoami_health"
        type     = "http"
        path     = "/health"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
        address_mode = "alloc"
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