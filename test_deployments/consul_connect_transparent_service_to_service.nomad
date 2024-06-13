job "connect_test" {
  # curl -X GET http://app2-api1.virtual.consul
  group "app1" {
    count = 1

    network {
      mode = "bridge"
      port "api1" {
        to = 5000
      }
      port "api2" {
        to = 5001
      }
      port "metrics" {
        to = -1
      }
    }

    service {
      name = "app1-api1"
      port = "5000"
      connect {
        sidecar_service {
          proxy {
             expose {
                path {
                   path            = "/metrics"
                   protocol        = "http"
                   local_path_port = 21000
                   listener_port   = "metrics"
                }
             }
            config{
              tags = [
                "prometheus",
              ]
              envoy_prometheus_bind_addr ="0.0.0.0:21000"
            }
#             transparent_proxy {
#            #   exclude_outbound_ports = [5001]
#            #   exclude_inbound_ports = ["5001"]
#             }
          }
        }
      }
    }
    service {
      name = "app1-api2"
      port = "5001"
      #How to expose this over transparent_proxy ??
    }

    task "app1" {
      driver = "docker"

      config {
        image = "suikast42/nettools:latest"
        ports = ["api1", "api2"]
        #  entrypoint         = ["tail", "-f", "/dev/null"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
  group "app2" {
    count = 1
    # curl -X GET http://app1-api1.virtual.consul
    network {
      mode = "bridge"
      port "api1" {
        to = 5000
      }
      port "api2" {
        to = 5001
      }
    }

    service {
      name = "app2-api1"
      port = "5000"
      connect {
        sidecar_service {
          proxy {
            transparent_proxy {
              #   exclude_outbound_ports = [5001]
              #   exclude_inbound_ports = ["5001"]
            }
          }
        }
      }
    }
    service {
      name = "app2-api2"
      port = "5001"
      #How to expose this over transparent_proxy ??
    }

    task "app2" {
      driver = "docker"

      config {
        image = "suikast42/nettools:latest"
        ports = ["api1", "api2"]
        #  entrypoint         = ["tail", "-f", "/dev/null"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}