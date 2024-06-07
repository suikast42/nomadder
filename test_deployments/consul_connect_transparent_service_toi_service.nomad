job "connect_test" {
  group "app1" {
    count = 1

    network {
      mode = "bridge"
      port "api" {
        to = 5000
      }
    }

    service {
      name = "app1"
      port = "5000"
#       port = "api"
      connect {
        sidecar_service {
          proxy {
            transparent_proxy {}
          }
        }
      }
#       check {
#         name     = "readiness"
#         type     = "http"
#         path     = "/"
#         interval = "10s"
#         timeout  = "2s"
#       }
    }

    task "app1" {
      driver = "docker"

      config {
        image = "suikast42/nettools:latest"
        ports = ["api"]
        #         entrypoint         = ["tail", "-f", "/dev/null"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }

  group "app2" {
    count = 1

    network {
      mode = "bridge"
      port "api" {
        to = 5000
      }
    }

    # curl -X GET http://app2.virtual.consul
    service {
      name = "app2"
       port = "5000"
#       port = "api"
#       check {
#         name     = "readiness"
#         type     = "http"
#         path     = "/"
#         interval = "10s"
#         timeout  = "2s"
#       }
      connect {
        sidecar_service {
          proxy {
            transparent_proxy {}
          }
        }
      }
    }

    task "app2" {
      driver = "docker"

      config {
        image = "suikast42/nettools:latest"
        ports = ["api"]
        #   entrypoint         = ["tail", "-f", "/dev/null"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}