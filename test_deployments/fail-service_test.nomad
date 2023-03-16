job "fail-service" {
  datacenters = ["nomadder1"]

  type = "service"

  reschedule {
    delay          = "10s"
    delay_function = "constant"
    unlimited      = true
  }
  update {
    max_parallel      = 1
    health_check      = "checks"
    # Alloc is marked as unhealthy after this time
    healthy_deadline  = "2m"
    min_healthy_time  = "10s"
  }

  group "fail-service" {
    count = 1
    restart {
      attempts = 1
      interval = "1m"
      delay = "5s"
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
          interval = "10s"
          timeout  = "2s"
          check_restart {
            limit = 1
            grace = "10s"
            ignore_warnings = false
          }
        }
      }

      env {
        #HEALTHY_FOR   = -1  # stays healthy for ever
        HEALTHY_FOR   = 0 # unhealthy imediately
        #HEALTHY_FOR =  30 #stays healthy for 30s
        UNHEALTHY_FOR = -1 # gets unhealthy afterwards
        #UNHEALTHY_FOR = 0 # gets healthy afterwards
        #UNHEALTHY_FOR = 30 # stays unhealthy for 30s
      }
      resources {
        cpu    = 100 # MHz
        memory = 256 # MB
      }
    }
  }
}