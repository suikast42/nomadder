variable "org" {
  type = string
  description = "Default organisation"
  default = "tdp.private"
}

job "ai-stack" {

  type        = "service"

  group "ollama-group" {
    count = 1
    restart {
      attempts = 1
      interval = "1h"
      delay = "5s"
      mode = "fail"
    }
    network {
      mode = "bridge"
      port "ollama_api" {
        to = 11434
      }
      port "webui" {
        to = 8080
      }
    }

    # Task 1: The Ollama Backend
    task "ollama" {
      driver = "docker"

      config {
        image = "ollama/ollama:latest"
        ports = ["ollama_api"]
        # Standard Ollama container automatically uses CPU if no GPU is detected
        volumes = [
          "local/ollama:/root/.ollama"
        ]
      }

      resources {
        # Coding models are heavy; allocate at least 4 cores and 8GB RAM
        cpu    = 4000
        memory = 65536
      }

      service {
        name = "ollama"
        port = "ollama_api"
        check {
          type     = "http"
          path     = "/api/tags"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }


    # Task 2: The Claude-style Web Interface
    task "open-webui" {
      driver = "docker"

      env {
        # Point to the sidecar task
        OLLAMA_BASE_URL = "http://${NOMAD_ADDR_ollama_api}"
        # Disable GPU checks in the UI
         ENABLE_IMAGE_GENERATION = "false"
         WEBUI_AUTH = false
      }

      config {
        image = "ghcr.io/open-webui/open-webui:main"
        ports = ["webui"]
        volumes = [
          "local/webui:/app/backend/data"
        ]
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      service {
        name = "open-webui"
        port = "webui"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.ai.tls=true",
          "traefik.http.routers.ai.rule=Host(`ai.${var.org}`)",
        ]
        check {
          type     = "http"
          path     = "/"
          interval = "15s"
          timeout  = "5s"
          check_restart {
            limit = 3
            grace = "60s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
