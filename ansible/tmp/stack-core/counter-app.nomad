job "countdash_app" {
  datacenters = ["nomadder1"]

  group "api" {
    network {
      mode = "bridge"
      port "http" {
        static = 9001
        to = 9001
      }
    }
    task "api" {
      service {
        name = "api"
        port = "http"
#        tags = [
#          "traefik.enable=true",
#          "traefik.http.routers.api.rule=Path(`/count_api`)",
#          "traefik.http.routers.api.tls=true"
#        ]
        check {
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
      driver = "docker"
      config {
        image = "hashicorpdev/counter-api:v3"
        ports = ["http"]
      }
    }
  }

  group "counter-dashboard" {

      network {
        mode = "bridge"

        port "http" {
          static = 9002
          to = 9002
        }
      }


      task "counter-dashboard" {


        service {
          name = "counter-dashboard"
          port = "http"
          tags = [
            "traefik.enable=true",
            "traefik.http.routers.counter-dashboard.tls=true",
            "traefik.http.routers.counter-dashboard.rule= Host(`count.cloud.private`)",
# TODO: somehow the page cant rendered with PathPrefix
#            "traefik.http.routers.counter-dashboard.rule=PathPrefix(`/cnt`)",
#            "traefik.http.routers.counter-dashboard.middlewares= counter-dashboard",
#            "traefik.http.middlewares.counter-dashboard.stripprefix.prefixes=/cnt",
#            "traefik.http.middlewares.counter-dashboard.stripprefix.forceSlash=true"
          ]

          check {
            type     = "tcp"
            port     = "http"
            interval = "10s"
            timeout  = "2s"
          }
        }
        driver = "docker"
        env {
          COUNTING_SERVICE_URL = "http://api.service.nomadder1.consul:9001"
        }

        config {
          image = "hashicorpdev/counter-dashboard:v3"
          ports = ["http"]
        }
      }
    }
}