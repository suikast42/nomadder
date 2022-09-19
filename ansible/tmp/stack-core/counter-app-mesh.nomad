job "countdash_app_mesh" {
  datacenters = ["nomadder1"]

  group "api" {
    network {
      mode = "bridge"

    }

    service {
      name = "count-api"
      port = "9001"
      connect {
        sidecar_service {}
      }
    }

    task "count-api" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v3"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {
        #        static= 9002
        to = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "http"
            tags = [
              "traefik.enable=true",
              "traefik.consulcatalog.connect=true",
              "traefik.http.routers.count-dashboard.tls=true",
      #        "traefik.http.routers.count-dashboard.tls.options=mtls",
#              "traefik.http.routers.count-dashboard.entrypoints=https",
#              "traefik.http.services.count-dashboard.loadbalancer.server.scheme=https",
              "traefik.http.routers.count-dashboard.rule=Host(`count.cloud.private`)",
#              "traefik.http.routers.count-dashboard.tls.domains[0].main=cloud.private",
#              "traefik.http.routers.count-dashboard.tls.domains[0].sans=count.cloud.private"
            ]

      connect {


        sidecar_service {
          proxy {
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