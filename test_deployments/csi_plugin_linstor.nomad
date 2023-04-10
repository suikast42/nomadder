# See https://www.youtube.com/watch?v=7nHE3Rg9hBI&ab_channel=LINBIT
# See https://docs.piraeus.daocloud.io/books/linstor-10-user-guide/page/53-deploying-the-linstor-csi-driver-on-nomad
# See https://linbit.com/blog/open-source-sds-solution-for-hashicorp-nomad/
# https://www.youtube.com/watch?v=7nHE3Rg9hBI&ab_channel=LINBIT
# drbd.io needs credentials. Is that commercial or not ?
job "linstor-controller" {
  datacenters = ["nomadder1"]
  type        = "service"

  group "linstor-controller" {
    network {
      mode = "bridge"
      # port "linstor-api" { (2)
      #   static = 3370
      #   to = 3370
      # }
    }

    service {
      name = "linstor-api"
      port = "3370"

      connect {
        sidecar_service {}
      }

      check {
        expose   = true
        type     = "http"
        name     = "api-health"
        path     = "/health"
        interval = "30s"
        timeout  = "5s"
      }
    }

    task "linstor-controller" {
      driver = "docker"
      config {
        image = "drbd.io/linstor-controller:v1.21.1"

auth {
username = "example"
password = "example"
server_address = "drbd.io"
}

mount {
type = "bind"
source = "local"
target = "/etc/linstor"
}
}

# template { (6)
#  destination = "local/linstor.toml"
#  data = <<EOH
#    [db]
#    user = "example"
#    password = "example"
#    connection_url = "jdbc:postgresql://postgres.internal.example.com/linstor"
#  EOH
# }

resources {
cpu = 500 # 500 MHz
memory = 700 # 700MB
}
}
}
}