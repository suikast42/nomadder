job "fabio" {
  datacenters = ["nomadder_1"]
  type = "system"

  group "fabio" {
    network {
      mode = "bridge"
      port "http" {
        static = 80
        to=9999
      }
      port "https" {
        static = 443
        to=9999
      }
      port "ui" {
        static = 9998
        to = 9998
      }
    }

    task "fabio" {
      driver = "docker"
      config {
        image = "fabiolb/fabio:1.6.1"
#        network_mode = "host"
        ports = ["http","https","ui"]
         args  = [
            "--registry.consul.token=e95b599e-166e-7d80-08ad-aee76e7ddf19",
           "--registry.consul.addr=10.21.21.41:8500",
           "--log.access.format=combined",
           "--log.routes.format=all",
           "--log.level=DEBUG"
        ]
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
