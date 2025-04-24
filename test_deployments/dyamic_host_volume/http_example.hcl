job "example" {

  group "group" {

    count = 3
    # claim the dynamic host volume for the allocation
    volume "groupvol" {
      type            = "host"
      source          = "example_volume"
      #access_mode     = "single-node-single-writer"
      #attachment_mode = "file-system"
      # sticky    = true
      per_alloc = true
    }

    network {
      port "www" {
        to = 8001
      }
    }


    service {
      name = "example-service"
      port = "www"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.example.rule=Host(`example.cloud.private`)",
        "traefik.http.routers.example.tls=true",
      ]

    }

    task "task" {

      driver = "docker"

      config {
        image   = "busybox:1.37.0"
        command = "httpd"
        args    = [ "-f", "-p", "8001", "-h", "/home"]
        ports   = ["www"]
      }

      # mount the claimed volume to the task
      volume_mount {
        volume      = "groupvol"
        destination = "/home"
      }
    }
  }
}
