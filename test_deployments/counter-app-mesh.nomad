job "countdash_app_mesh" {
  datacenters = ["nomadder1"]
  group "api" {
    count = 1
#    constraint {
#      distinct_hosts = true
#    }
#         constraint {
#           attribute    = "${attr.unique.hostname}"
#           set_contains = "worker-02"
#         }
    network {
      mode = "bridge"
      port "api" {
        to = 9001
#        host_network = "public"
      }
    }

    service {
      name = "count-api"
      port = "api"
      address_mode = "alloc"
      connect {
        sidecar_service {}
      }

      check {
        name     = "api_health"
        type     = "http"
        path     = "/health"
        port     = "api"
        interval = "10s"
        timeout  = "2s"
        address_mode = "alloc"
      }

    }

    task "count-api" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v3"
        ports = ["api"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }

  group "dashboard" {
    count = 1
        # constraint {
        #   attribute    = "${attr.unique.hostname}"
        #   set_contains = "worker-01"
        # }
    network {
      mode = "bridge"

      port "http" {
        to = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "9002"
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.count-dashboard.tls=true",
        "traefik.http.routers.count-dashboard.rule=Host(`count.cloud.private`)"
      ]

      connect {
        sidecar_service {
          proxy {
            #            config {
            #              protocol = "http"
            #            }
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        CONSUL_TLS_SERVER_NAME = "localhost"
        COUNTING_SERVICE_URL   = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }

      config {
        image = "hashicorpnomad/counter-dashboard:v3"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
