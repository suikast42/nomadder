job "wave" {
  datacenters = ["nomadder1"]

  group "wave" {
    restart {
      attempts = -1
      interval = "5s"
      delay    = "5s"
      mode     = "delay"
    }

    task "wave" {
      driver = "docker"

      config {
        force_pull = true
        image      = "voiselle/wave:v5"
        args       = ["300", "200", "15", "64", "4"]
      }

      resources {
        cpu        = 500
        memory     = 128
        memory_max = 1024
      }
    }
  }
}