variable "tls_san" {
  type        = string
  description = "The cluster domain"
  default     = "cloud.private"
}


job "tools" {


  group "excalidraw" {
    count = 1

    network {
      mode = "bridge"
      port "web" {
        to = 80
      }
    }

    service {
      name = "excalidraw"
      port = "web"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.excalidraw.rule=Host(`excalidraw.${var.tls_san}`)",
        "traefik.http.routers.excalidraw.tls=true",
      ]

      check {
        name     = "excalidraw portCheck"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit           = 3
          grace           = "30s"
          ignore_warnings = false
        }
      }
    }

    task "excalidraw" {
      driver = "docker"
      #      driver = "containerd-driver"
      config {
        image = "registry.${var.tls_san}/excalidraw/excalidraw:latest"
        ports = ["web"]
      }


      resources {
        cpu    = 100
        memory = 128
      }
    }

  }
}