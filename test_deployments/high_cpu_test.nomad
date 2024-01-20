job "highcpu" {

  group "highcpu" {
    count = 1

    network {
      mode = "bridge"
    }


    task "highcpu" {
      driver = "docker"
      #      driver = "containerd-driver"
      config {
        cpu_hard_limit = "true"
        cpuset_cpus    = "0-3"
        # Build the image ../test_docker_images/cpuload
        image          = "suikast42/cpuload"
        args           = ["stress", "--cpu", "12", "--timeout", "3600s"]
        #        args  = ["stress" ,"--verbose", "--timeout 60s","--cpu 1","--io 1", "--vm 1"]
      }

      resources {
        #        cores  = 1 # --> that works. Load is max on one core
        cpu    = 100 # --> All Cpus are on 100%
        memory = 128
      }
    }
  }
}