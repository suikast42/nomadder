job "fail-service" {
  datacenters = ["nomadder1"]

  type = "service"

  reschedule {
    delay          = "10s"
    delay_function = "constant"
    unlimited      = true
  }
  #  reschedule {
  #    attempts       = 3
  #    interval       = "10m"
  #    delay          = "5s"
  #    delay_function = "constant"
  #    unlimited      = false
  #  }

  update {
    max_parallel      = 1
    health_check      = "checks"
    healthy_deadline  = "1m" #  Default should be check_restart_grace
    min_healthy_time  = "20s" # Default should be 1 or two health check limits
    progress_deadline = "1h"
  }

  group "fail-service" {
    count = 1
    restart {
      # Restart if 3 of 4 check failed in check_interval
      attempts = 1
      interval = "1h"
      delay = "1s"
      mode = "fail"
    }
    network {
      port "http" {
        to= 8080
      }
    }
    task "fail-service" {
      driver = "docker"
      config {
        image = "thobe/fail_service:v0.1.0"
        ports = ["http"]
      }

      service {
        name = "${TASK}"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.${TASK}.tls=true",
          "traefik.http.routers.${TASK}.rule=Host(`fail.cloud.private`)",
        ]
        check {
          name     = "fail_service health using http endpoint '/health'"
          port     = "http"
          type     = "http"
          path     = "/health"
          method   = "GET"
          interval = "1s"
          timeout  = "1s"
          check_restart {
            limit = 3
            grace = "15s"
            ignore_warnings = false
          }
        }
      }

      env {
        #HEALTHY_FOR   = -1  # stays healthy for ever
        #HEALTHY_FOR   = 0 # unhealthy imediately
        HEALTHY_FOR =  10 #stays healthy for 30s
        UNHEALTHY_FOR = -1 # gets unhealthy afterwards
        # UNHEALTHY_FOR = 60 # gets healthy afterwards
        #UNHEALTHY_FOR = 30 # stays unhealthy for 30s
      }
      resources {
        cpu    = 100 # MHz
        memory = 256 # MB
      }
    }
  }
}