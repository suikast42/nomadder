# See https://github.com/hashicorp/nomad-pack-community-registry/blob/main/packs/jenkins/templates/jenkins.nomad.tpl
job "cicd-job" {
  datacenters = ["nomadder1"]
  type        = "service"

#  Place the whole job on the same node
# This can be moved to group level as well
  constraint {
    attribute    = "${attr.unique.hostname}"
    set_contains = "worker-02"
  }

  reschedule {
    delay          = "10s"
    delay_function = "constant"
    unlimited      = true
  }
  update {
    health_check      = "checks"
    max_parallel      = 1
    # Alloc is marked as unhealthy after this time
    healthy_deadline  = "5m"
    auto_revert  = true
    # Mark the task as healthy after 10s positive check
    min_healthy_time  = "10s"
    # Task is dead after failed checks in 1h
    progress_deadline = "1h"
  }

  group gitlab-group{
    count =1
    # Comment this out in case if define a volume
    ephemeral_disk {
      migrate = true
      size    = 500
      sticky  = true
    }


    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
      port "http2" {
        to = 80
      }
      port "http3" {
        to = 80
      }
      port "ssl" {
        to = 22
      }
    }

    service {
      name = "gitlab-service"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=false",
        "traefik.http.routers.gitlab-service.tls=true",
        "traefik.http.routers.gitlab-service.rule=Host(`gitlab.cloud.private`)",
      ]
      check {
        name     = "readiness"
        type     = "http"
        path     = "/-/readiness"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit = 3
          grace = "300s"
          ignore_warnings = false
        }
      }
    }

    service {
      name = "gitlab-liveness"
      port = "http2"
      check {
        name     = "readiness"
        type     = "http"
        path     = "/-/liveness"
        interval = "10s"
        timeout  = "2s"
      }
    }
    service {
      name = "gitlab-health"
      port = "http3"
      check {
        name     = "readiness"
        type     = "http"
        path     = "/-/health"
        interval = "10s"
        timeout  = "2s"
      }
    }
    task "gitlab-task" {
      driver = "docker"

      config {
        image = "gitlab/gitlab-ce:16.0.1-ce.0"
        ports = ["http","ssl"]
        image_pull_timeout = "10m"
#        volumes = []
      }
      resources {
        cpu    = 1000
        memory = 4096
      }
      env {
        GITLAB_ROOT_EMAIL="root@local"
        GITLAB_ROOT_PASSWORD="lcl@admin"
        GITLAB_OMNIBUS_CONFIG = "external_url 'http://gitlab.cloud.private'; gitlab_rails['monitoring_whitelist'] = ['0.0.0.0/0']"
      }
    }
  }
  group "jenkins-group" {
    count = 1
    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
    }
    volume "cert_nomad" {
      type      = "host"
      source    = "cert_consul"
      read_only = true
    }
    # Comment this out in case if define a volume
    ephemeral_disk {
      migrate = true
      size    = 500
      sticky  = true
    }
#    volume "jenkins_volume" {
#      type      = "host"
#      source    = "cert_consul"
#      read_only = true
#    }

    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
      port "http2" {
        to = 8080
      }
      port "jnlp" {
        to = 50000
      }
    }

    service {
      name = "jenkins-service"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=false",
        "traefik.http.routers.jenkins-service.tls=true",
        "traefik.http.routers.jenkins-service.rule=Host(`jenkins.cloud.private`)",
      ]
      check {
        name     = "alive"
        type     = "http"
        path     = "/login"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit = 3
          grace = "300s"
          ignore_warnings = false
        }
      }

    }
    service {
      name = "jenkins-resources-service"
      port = "http2"
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=false",
        "traefik.http.routers.jenkins-resources-service.tls=true",
        "traefik.http.routers.jenkins-resources-service.rule=Host(`jenkins-resources.cloud.private`)",
      ]
      check {
        name     = "alive"
        type     = "http"
        path     = "/login"
        interval = "10s"
        timeout  = "2s"
        check_restart {
          limit = 3
          grace = "300s"
          ignore_warnings = false
        }
      }
    }
# Enable this if volume is enabled
    task "01-jenknins-chown" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

#      volume_mount {
#        volume      = "jenkins_volume"
#        destination = "/var/jenkins_home"
#        read_only   = false
#      }

      driver = "docker"

      config {
        image   = "busybox:stable"
        command = "sh"
        args    = ["-c", "chown -R 1000:1000 /var/jenkins_home"]
        volumes = [
          "../${NOMAD_ALLOC_DIR}/data:/var/jenkins_home",
        ]
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }

    task "02-jenknins-plugins" {
      driver = "docker"
#      volume_mount {
#        volume      = "[[ .jenkins.volume_name ]]"
#        destination = "/var/jenkins_home"
#        read_only   = false
#      }
      config {
        image   = "jenkins/jenkins:2.387.3-lts-jdk17"
        command = "jenkins-plugin-cli"
        args    = ["--verbose","-f", "/var/jenkins_home/plugins.txt", "--plugin-download-directory", "/var/jenkins_home/plugins/"]
        volumes = [
          "../${NOMAD_ALLOC_DIR}/data:/var/jenkins_home",
          "local/plugins.txt:/var/jenkins_home/plugins.txt",
        ]
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
# List of Plugins https://updates.jenkins.io/download/plugins/
# For config the plugin cli see https://github.com/jenkinsci/plugin-installation-manager-tool
      template {
        data = <<EOF
git:latest
github:latest
job-dsl:latest
nomad:latest
hashicorp-vault-plugin:latest
configuration-as-code:latest
github-api:latest
git:latest
github:latest
github-branch-source:latest
gitlab-api:latest
gitlab-branch-source:latest
gitlab-logo:latest
gitlab-merge-request-jenkins:latest
gitlab-oauth:latest
gitlab-plugin:latest
EOF
        destination   = "local/plugins.txt"
        change_mode   = "noop"
      }
      resources {
        cpu    = 500
        memory = 4096
      }
    }

    task "jenkins-task" {


      driver = "docker"
      volume_mount {
        volume      = "ca_cert"
        destination = "/etc/opt/certs/ca"
      }
      volume_mount {
        volume      = "cert_nomad"
        destination = "/etc/opt/certs/client"
      }
#      volume_mount {
#        volume      = "jenkins_volume"
#        destination = "/var/jenkins_home"
#        read_only   = false
#      }
      config {
        image = "jenkins/jenkins:2.387.3-lts-jdk17"
        ports = ["http","jnlp"]
        volumes = [
          "../${NOMAD_ALLOC_DIR}/data:/var/jenkins_home",
          "local/jasc.yaml:/var/jenkins_home/jenkins.yaml",
        ]
      }
      env{
        JAVA_OPTS ="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Dhudson.model.DownloadService.noSignatureCheck=true"
      }
# configuration-as-code plugin is required for that
# https://plugins.jenkins.io/configuration-as-code/
# Export current settings with https://jenkins.cloud.private/configuration-as-code/
      template {
        right_delimiter = "++"
        left_delimiter = "++"
        data = <<EOF
jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin\n\n"
  globalNodeProperties:

  slaveAgentPort: 50000
  agentProtocols:
    - "jnlp2"

unclassified:
  location:
    adminAddress: "wmsadmin@amova.eu"
    url: "https://jenkins.cloud.private/"
  resourceRoot:
    url: "https://jenkins-resources.cloud.private"

tool:
  git:
    installations:
      - name: git
        home: /usr/local/bin/git

  jdk:
    installations:
    - name: "JDK_16"
      properties:
      - installSource:
          installers:
          - zip:
              label: "jdk16"
              subdir: "jdk-16.0.2"
              url: "https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-x64_bin.tar.gz"

    - name: "JDK_17"
      properties:
      - installSource:
          installers:
          - zip:
              label: "jdk16"
              subdir: "jdk-17.0.2"
              url: "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz"

    - name: "JDK_18"
      properties:
      - installSource:
          installers:
          - zip:
              label: "jdk16"
              subdir: "jdk-18.0.2"
              url: "https://download.java.net/java/GA/jdk18.0.2/f6ad4b4450fd4d298113270ec84f30ee/9/GPL/openjdk-18.0.2_linux-x64_bin.tar.gz"

    - name: "JDK_19"
      properties:
      - installSource:
          installers:
          - zip:
              label: "jdk16"
              subdir: "jdk-18.0.1"
              url: "https://download.java.net/java/GA/jdk19.0.1/afdd2e245b014143b62ccb916125e3ce/10/GPL/openjdk-19.0.1_linux-x64_bin.tar.gz"

    - name: "JDK_20"
      properties:
      - installSource:
          installers:
          - zip:
              label: "jdk16"
              subdir: "jdk-20"
              url: "https://download.java.net/java/GA/jdk20/bdc68b4b9cbc4ebcb30745c85038d91d/36/GPL/openjdk-20_linux-x64_bin.tar.gz"

              EOF
        change_mode   = "noop"
        destination   = "local/jasc.yaml"
      }
      resources {
        cpu    = 1000
        memory = 2048
      }
    }
  }
}
