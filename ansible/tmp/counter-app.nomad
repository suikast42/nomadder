job "countdash_app" {
  datacenters = ["nomadder1"]

  group "api" {

    network {
      mode = "host"
      port "http" {
        static = 9001
        to = 9001
      }
    }
    task "api" {
      service {
        name = "api"
        port = "http"
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

  group "dashboard" {
    service {
      name = "dashboard"
    }
    network {
      mode = "host"
#      dns {
#        servers = ["10.21.21.42"]
#      }
      port "http" {
        static = 9002
        to = 9002
      }
    }


    task "dashboard" {
      service {
        name = "dashboard"
        check {
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
      driver = "docker"
      #      NOMAD_IP_foo - The IP to bind on for the given port label.
      #NOMAD_PORT_foo - The port value for the given port label.
      #NOMAD_ADDR_foo - A combined ip:port that can be used for convenience.
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