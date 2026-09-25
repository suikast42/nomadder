job "fail-service" {
    datacenters = ["nomadder1"]

    type = "service"

    # reschedule failed task behaviour
    # Configured for infinite restart every 10s of failed tasks
    reschedule {
      delay          = "10s" # give a restart delay
      delay_function = "constant" # the delay time is constant ( possible exponential  and fibonaci if set set max_delay as well )
      unlimited      =  true # true progress_deadline will effectively be  bypassed.
    }
    update {
      health_check = "checks"
      # Alloc is marked as unhealthy after this time
      healthy_deadline  = "3m"
      auto_revert = true
      # Mark the task as healthy after 1s positive check
      min_healthy_time = "1s"
      # Task is dead after failed checks in 1h
      progress_deadline = "1h"
    }

    group "fail-service" {
      count = 1

      # For x restart attempts triggered check_restart  in timewindows of interval x
      # mark the task as failed. And trigger the rescheduler
      restart {
        attempts =  5
        interval = "1h"
        delay    = "1s"
        mode     = "fail"
      }

      network {
        port "http" {
          to = 8080
        }
      }
      task "fail-service" {
        driver         = "docker"
        shutdown_delay = "10s"
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
              limit           = 3
              grace           = "10s"
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
          cpu = 100 # MHz
          memory = 256 # MB
        }
      }
    }
  }
