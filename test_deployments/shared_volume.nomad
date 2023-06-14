job "sharedVolume" {

  group "grp" {
    #    ephemeral_disk {
    #      migrate = true
    #      size    = 500
    #      sticky  = true
    #    }
    task "a" {
      driver = "docker"

      config {
        image   = "busybox:1.36.1"
        command = "/bin/sh"
        args    = ["-c", "sleep 300"]
        #        volumes = ["../${NOMAD_ALLOC_DIR}/data:/shared/srv"]
        mount {
          type     = "bind"
          source   = "../${NOMAD_ALLOC_DIR}/data"
          target   = "/shared/srv"
          readonly = false
        }
      }

    }

    task "b" {
      driver = "docker"

      config {
        image   = "busybox:1.36.1"
        command = "/bin/sh"
        args    = ["-c", "sleep 300"]
        #        volumes = ["../${NOMAD_ALLOC_DIR}/data:/shared/srv"]
        mount {
          type     = "bind"
          source   = "../${NOMAD_ALLOC_DIR}/data"
          target   = "/shared/srv"
          readonly = false
        }
      }
    }
  }
}