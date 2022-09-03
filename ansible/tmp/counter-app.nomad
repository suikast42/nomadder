job "countdash_app" {
  datacenters = ["nomadder_1"]

  group "api" {
    network {
      mode = "host"
      port "http" {
        static = 9001
        to = 9001
      }
    }
    task "web" {
      driver = "docker"
      config {
        image = "hashicorpdev/counter-api:v3"
        ports = ["http"]
      }
    }
  }

  group "dashboard" {

    network {
      mode = "host"
      port "http" {
        static = 9002
        to = 9002
      }
    }

    service {
      name = "dashboard"
    }
    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_IP_http}:9001"
      }

      config {
        image = "hashicorpdev/counter-dashboard:v3"
        ports = ["http"]
      }
    }
  }
}