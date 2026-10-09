variable tls_san {
  type        = string
  description = "The cluster domain"
  default     = "cloud.private"
}


variable registry_proxy {
  type        = string
  description = "The cluster registry proxy"
  default     = "registry.cloud.private"
}




variable version_rustfs {
  type        = string
  description = "Version of rustfs server"
  default     = "1.0.1"
}


variable environment {
  type        = string
  description = "Environment of the deployment like dev or production"
  default     = "dev"
}

variable organisation {
  type        = string
  description = "Project org  name"
  default     = "amova"
}


job s3_rustfs {
  type     = "service"
  priority = 80
  reschedule {
    delay          = "10s"
    delay_function = "constant"
    unlimited      = true
  }
  update {
    max_parallel      = 1
    health_check = "checks"
    # Alloc is marked as unhealthy after this time
    healthy_deadline  = "5m"
    auto_revert = true
    # Mark the task as healthy after 10s positive check
    min_healthy_time = "10s"
    # Task is dead after failed checks in 1h
    progress_deadline = "1h"
  }


  group "s3_rustfs" {

    restart {
      attempts = 1
      interval = "1h"
      delay    = "5s"
      mode     = "fail"
    }
    update {
      max_parallel = 1
    }


    count = 1
    network {
      mode = "bridge"
      port "s3_api" {
        to = 9000

      }
      port "s3_console" {
        to = 9001
      }

    }
    service {
      port = "s3_console"
      name = "s3-console"
      tags = [
        # Do not enable    "prometheus", here. The metrics collected over  prometheus-exporter
        "prometheus:server_id=s3-console",
        "prometheus:version=${var.version_rustfs}",
        "traefik.enable=true",
        "traefik.http.routers.s3.tls=true",
        "traefik.http.routers.s3.rule=Host(`s3.${var.tls_san}`)",
      ]

      check {
        name     = "health"
        type     = "http"
        port     = "s3_console"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit = 3
          grace = "10s"
          ignore_warnings = false
        }
      }
    }
    service {
      port = "s3_api"
      name = "s3-api"
      tags = [
        # Do not enable    "prometheus", here. The metrics collected over  prometheus-exporter
        "prometheus:server_id=s3-console",
        "prometheus:version=${var.version_rustfs}",
        "traefik.enable=true",
        "traefik.http.routers.s3-api.tls=true",
        "traefik.http.routers.s3-spi.rule=Host(`s3-api.${var.tls_san}`)",
      ]

      check {
        name     = "health"
        type     = "http"
        port     = "s3_api"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit = 3
          grace = "10s"
          ignore_warnings = false
        }
      }
    }

    task "s3_rustfs_task" {

      shutdown_delay ="20s"
      driver = "docker"
      config {
        image = "${var.registry_proxy}/rustfs/rustfs:${var.version_rustfs}"
        labels = {
          "com.github.logunifier.application.name"        = "${NOMAD_ALLOC_NAME}"
          "com.github.logunifier.application.version"     = "${var.version_rustfs}"
          "com.github.logunifier.application.org"         = "${var.organisation}"
          "com.github.logunifier.application.env"         = "${var.environment}"
          # "com.github.logunifier.application.pattern.key" = "ecs"
          #  "com.github.logunifier.application.pattern.key" = "tslevelmsg"
        }

        ports = ["s3_api", "s3_console"]

# volume /mnt/rustfs/data:/data \
      }
      env {
        #TODO: save to nomad vars
        RUSTFS_ACCESS_KEY="rustadmin"
        # $(openssl rand -base64 32)
        #TODO: save to nomad vars
        RUSTFS_SECRET_KEY="rustadmin"
        #TODO: add OIDC https://docs.rustfs.com/de/security-compliance/oidc/keycloak
        RUSTFS_ADDRESS="0.0.0.0:9000"
        RUSTFS_CONSOLE_ADDRESS="0.0.0.0:9001"
        RUSTFS_CONSOLE_ENABLE="true"
        RUSTFS_OBS_LOG_STDOUT_ENABLED="true"
        RUSTFS_OBS_LOGGER_LEVEL="debug"
        RUSTFS_CONSOLE_CORS_ALLOWED_ORIGINS="*"
        RUSTFS_REGION="dc1-local"
        # RUSTFS_OBS_LOG_DIRECTORY="/var/log/rustfs/"

      }
      resources {
        cpu        = 500
        memory     = 512
        memory_max = 32768
      }


    }
  }
}

