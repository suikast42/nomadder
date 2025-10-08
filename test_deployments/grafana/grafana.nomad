variable "org" {
  type = string
  description = "Default organisation"
  default = "cloud.private"
}

variable "env" {
  type = string
  description = "environment like prod dev testing"
  default = "dev"
}

variable "version_grafana_nomadder" {
  type = string
  description = "Version grafana exporter"
  default = "12.2.0.7"
}



job "grafana_test" {
  # Enable this for redeploy all the job file even if nothing changed
  #  meta {
  #    run_uuid = "${uuidv4()}"
  #  }
  #

  type = "service"
  datacenters = ["nomadder1"]
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
  group "grafana-test" {
    restart {
      attempts = 1
      interval = "1h"
      delay = "5s"
      mode = "fail"
    }

    volume "grafana_test" {
      type      = "host"
      source    = "grafana_test"
      read_only = false
    }

    count = 1
    network {
      mode = "bridge"
      port "ui" {
        to = 3000
      }
    }
    service {
      name = "grafana-test"
      port = "ui"
      #port = "3000"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.grafana2.tls=true",
        "traefik.http.routers.grafana2.rule=Host(`grafana2.cloud.private`)",
      ]

      check {
        name     = "health"
        type     = "http"
        port     = "ui"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit = 3
          grace = "60s"
          ignore_warnings = false
        }
      }
    }
    task "grafana" {
      volume_mount {
        volume      = "grafana_test"
        destination = "/var/lib/grafana"
      }

      driver = "docker"
      env {
        GF_FEATURE_TOGGLES_ENABLE="dashboardScene accessControlOnCall lokiLogsDataplane exploreLogsShardSplitting"
        GF_SERVER_DOMAIN = "grafana2.cloud.private"
        # GF_PATHS_CONFIG  = "/etc/grafana/grafana.ini"
        GF_PATHS_PLUGINS  = "/var/lib/grafana2/plugins"
        GF_SERVER_ROOT_URL = "https://grafana2.cloud.private"
      }
      config {
        image = "registry.cloud.private/stack/observability/grafana:${var.version_grafana_nomadder}"
        labels = {
          "com.github.logunifier.application.name" = "grafana2"
          "com.github.logunifier.application.version" = "${var.version_grafana_nomadder}"
          "com.github.logunifier.application.org" = "${var.org}"
          "com.github.logunifier.application.env" = "${var.env}"
          "com.github.logunifier.application.pattern.key" = "logfmt"
        }
        ports = ["ui"]
      }
      resources {
        cpu    = 500
        memory = 1024
        memory_max = 4096
      }

    }
  }

}
