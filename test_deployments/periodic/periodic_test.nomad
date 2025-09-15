job "perodic_test" {
  type = "batch"
  periodic {
    cron             = "* * * * *"
    prohibit_overlap = true
  }

  task "task" {

    driver = "docker"

    config {
      image   = "busybox:1.37.0"
      command = "httpd"
      # args = ["-f", "-p", "8001", "-h", "/home"]
      # ports = ["www"]
    }

  }
}
