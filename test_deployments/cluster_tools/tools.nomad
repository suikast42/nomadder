variable "tls_san" {
  type        = string
  description = "The cluster domain"
  default     = "cloud.private"
}


job "tools" {

  reschedule {
    delay          = "10s"
    delay_function = "constant"
    unlimited      = true
  }
  update {
    health_check      = "checks"
    max_parallel      = 1
    # Alloc is marked as unhealthy after this time
    healthy_deadline  = "5m"
    auto_revert  = true
    # Mark the task as healthy after 10s positive check
    min_healthy_time  = "10s"
    # Task is dead after failed checks in 1h
    progress_deadline = "1h"
  }

  group "excalidraw" {
    count = 1

    restart {
      attempts = 1
      interval = "1h"
      delay = "5s"
      mode = "fail"
    }
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