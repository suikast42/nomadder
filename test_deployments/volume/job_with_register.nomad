job "http-server-with-volume-register" {

  group "server" {
    count = 1

    volume "server-data" {
      type      = "host"
      source    = "dynamic_register" # Must match a host volume definition
      read_only = false
    }
    network {
      mode = "bridge"
      port "http" {}
    }
    task "http-echo" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        ports = ["http"]
      }

      volume_mount {
        volume      = "server-data"
        destination = "/data" # The path inside the container
        read_only   = false
      }

      service {
        name = "http-echo"
      }
    }
  }
}
