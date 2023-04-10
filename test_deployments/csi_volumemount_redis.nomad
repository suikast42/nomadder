job "example" {
  datacenters = ["nomadder1"]

  group "cache" {

    count = 3

    volume "volume0" {
      type            = "csi"
      source          = "ebs_prod_db"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer" # alt: "single-node-writer"
      read_only       = false
      per_alloc       = true
    }

    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7"
        ports = ["db"]
      }

      volume_mount {
        volume      = "volume0"
        destination = "${NOMAD_ALLOC_DIR}/volume0"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}