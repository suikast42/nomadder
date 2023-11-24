
variable "tls_san" {
  type = string
  description = "The cluster domain"
  default = "amovacloud.private"
}


variable "docker_host" {
  type = string
  description = "The docker build host"
  default = "10.128.82.220"
}

variable "master_01" {
  type = string
  description = "The master 01 ip"
  default = "10.128.82.220"
}

variable "hostname" {
  type = string
  description = "Deploy this job on this host"
  default = "worker-01"
}


variable "image_jenkins" {
  type = string
  description = "The used jenkins image"
  default = "jenkins/jenkins:2.432-jdk17_1"
}

variable "image_gitlab" {
  type = string
  description = "The used jenkins image"
  default = "gitlab/gitlab-ce:16.3.6-ce.0"
}

# See https://github.com/hashicorp/nomad-pack-community-registry/blob/main/packs/jenkins/templates/jenkins.nomad.tpl
job "cicd-job" {
  datacenters = ["nomadder1"]
  type        = "service"

#  Place the whole job on the same node
# This can be moved to group level as well
  constraint {
    attribute    = "${attr.unique.hostname}"
    value = "${var.hostname}"
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
    restart {
      attempts = 1
      interval = "1h"
      delay = "5s"
      mode = "fail"
    }
    volume "nomad_volume_stack_cicd_gitlab_etc" {
      type      = "host"
      source    = "nomad_volume_stack_cicd_gitlab_etc"
      read_only = false
    }
    volume "nomad_volume_stack_cicd_gitlab_opt" {
      type      = "host"
      source    = "nomad_volume_stack_cicd_gitlab_opt"
      read_only = false
    }

    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
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
        "traefik.http.routers.gitlab-service.rule=Host(`gitlab.${var.tls_san}`)",
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

    task "01-gitlab-cert-import" {

      volume_mount {
        volume      = "ca_cert"
        destination = "/certs"
      }



      driver = "docker"

      config {
        image   = "registry.${var.tls_san}/${var.image_jenkins}"
        command = "/bin/sh"
        args    = ["-c", "/tmp/copy.sh"]
        #        args    = ["-c", "sleep 300"]
        volumes = ["local/gen.sh:/tmp/copy.sh"]
      }
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
      template {
        perms = "777"
        data = <<EOF
#!/bin/bash
EXIT_STATUS=0
echo "Starting cert copy"
mkdir -p ${NOMAD_ALLOC_DIR}/data/security
cp -r /certs/*  ${NOMAD_ALLOC_DIR}/data/security || EXIT_STATUS=$?
exit $EXIT_STATUS
EOF
        destination   = "local/gen.sh"
        change_mode   = "noop"
      }
      resources {
        cpu    = 200
        memory = 128
      }
    }

    task "gitlab-task" {
      volume_mount {
        volume      = "nomad_volume_stack_cicd_gitlab_etc"
        destination = "/etc/gitlab"
      }
      volume_mount {
        volume      = "nomad_volume_stack_cicd_gitlab_opt"
        destination = "/var/opt/gitlab"
      }

      driver = "docker"

      config {
        image = "registry.${var.tls_san}/${var.image_gitlab}"
        ports = ["http","ssl"]
        image_pull_timeout = "10m"
        volumes = ["../${NOMAD_ALLOC_DIR}/data/security/:/etc/gitlab/trusted-certs",]
      }
      resources {
        cpu    = 2000
        memory = 4096
        memory_max= 32192
      }
      env {
        GITLAB_ROOT_EMAIL="root@local"
        GITLAB_ROOT_PASSWORD="lcl@admin"
        #GITLAB_OMNIBUS_CONFIG = "external_url 'https://gitlab.${var.tls_san}'; gitlab_rails['monitoring_whitelist'] = ['0.0.0.0/0']"
        GITLAB_OMNIBUS_CONFIG = "external_url 'https://gitlab.${var.tls_san}'; nginx['listen_https'] = false; nginx['listen_port'] = 80; gitlab_rails['monitoring_whitelist'] = ['0.0.0.0/0']"
      }
    }
  }

  group "jenkins-group" {
    restart {
      attempts = 1
      interval = "1h"
      delay = "5s"
      mode = "fail"
    }
    volume "nomad_volume_stack_cicd_jenkins" {
      type      = "host"
      source    = "nomad_volume_stack_cicd_jenkins"
      read_only = false
    }
    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
    }
    volume "cert_docker" {
      type      = "host"
      source    = "cert_docker"
      read_only = true
    }

    volume "cert_nomad" {
      type      = "host"
      source    = "cert_nomad"
      read_only = true
    }

    volume "cert_consul" {
      type      = "host"
      source    = "cert_consul"
      read_only = true
    }

    count = 1

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
        "traefik.http.routers.jenkins-service.rule=Host(`jenkins.${var.tls_san}`)",
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
        "traefik.http.routers.jenkins-resources-service.rule=Host(`jenkins-resources.${var.tls_san}`)",
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

      volume_mount {
        volume      = "nomad_volume_stack_cicd_jenkins"
        destination = "/var/jenkins_home"
      }

      driver = "docker"

      config {
        image   = "registry.${var.tls_san}/busybox:stable"
        command = "sh"
        args    = ["-c", "chown -R 1000:1000 /var/jenkins_home"]
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }

    task "02-jenknins-plugins" {
      driver = "docker"
      volume_mount {
        volume      = "nomad_volume_stack_cicd_jenkins"
        destination = "/var/jenkins_home"
      }
      config {
        image   = "registry.${var.tls_san}/${var.image_jenkins}"
        command = "jenkins-plugin-cli"
        args    = ["--verbose","-f", "/var/jenkins_home/plugins.txt", "--plugin-download-directory", "/var/jenkins_home/plugins/"]
        volumes = ["local/plugins.txt:/var/jenkins_home/plugins.txt"]
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
# List of Plugins https://updates.jenkins.io/download/plugins/
# For config the plugin cli see https://github.com/jenkinsci/plugin-installation-manager-tool

# OIDC Login with keycloak and jenkins https://github.com/jenkinsci/keycloak-plugin
      template {
        data = <<EOF
role-strategy:689.v731678c3e0eb_
keycloak:2.3.2
oic-auth:2.6
matrix-auth:3.2.1
strict-crumb-issuer:2.1.1
git:5.2.1
github:1.37.3.1
job-dsl:1.87
nomad:0.10.0
consul:2.1
hashicorp-vault-plugin:362.v8dfe4061f29e
configuration-as-code:1737.v652ee9b_a_e0d9
github-api:1.316-451.v15738eef3414
github-branch-source:1750.v6b_fb_8df8f985
gitlab-api:5.3.0-91.v1f9a_fda_d654f
gitlab-branch-source:684.vea_fa_7c1e2fe3
gitlab-logo:1.1.2
gitlab-oauth:1.18
gitlab-plugin:1.7.16
multibranch-scan-webhook-trigger:1.0.9
pipeline-stage-tags-metadata:2.2151.ve32c9d209a_3f
pipeline-github-lib:42.v0739460cda_c4
pipeline-model-extensions:2.2151.ve32c9d209a_3f
pipeline-build-step:516.v8ee60a_81c5b_9
pipeline-rest-api:2.34
plain-credentials:143.v1b_df8b_d3b_e48
pipeline-model-definition:2.2151.ve32c9d209a_3f
pipeline-stage-step:305.ve96d0205c1c6
pipeline-stage-view:2.34
pipeline-milestone-step:111.v449306f708b_7
pipeline-maven:1362.vee39a_d4b_02b_1
pipeline-model-api:2.2151.ve32c9d209a_3f
build-timeout:1.31
gradle:2.9
ant:497.v94e7d9fffa_b_9
authentication-tokens:1.53.v1c90fd9191a_b_
docker-workflow:572.v950f58993843
maven-plugin:3.23
custom-tools-plugin:0.8
pipeline-utility-steps:2.16.0
email-ext:2.102
EOF
        destination   = "local/plugins.txt"
        change_mode   = "noop"
      }
      resources {
        cpu    = 500
        memory = 4096
      }
    }

    task "03-jenknins-cert-import" {

      volume_mount {
        volume      = "ca_cert"
        destination = "/certs"
      }

      volume_mount {
        volume      = "cert_docker"
        destination = "/certsdocker"
      }


      driver = "docker"

      config {
        image   = "registry.${var.tls_san}/${var.image_jenkins}"
        command = "/bin/sh"
        args    = ["-c", "/var/jenkins_home/gen.sh"]
        #        args    = ["-c", "sleep 300"]
        volumes = ["local/gen.sh:/var/jenkins_home/gen.sh"]
      }
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
      template {
        perms = "777"
        data = <<EOF
#!/bin/bash
EXIT_STATUS=0
# ca ca.crt and cluster-ca.crt to java trust store
# Java trust store does not works with the bundle cluster-ca-bundle.pem
echo "Starting gen cert"
cp -r ${JAVA_HOME}/lib/security/cacerts /var/jenkins_home/cacerts || EXIT_STATUS=$?
${JAVA_HOME}/bin/keytool -import -trustcacerts -alias rootCa -keystore /var/jenkins_home/cacerts -file /certs/ca.crt -noprompt -storepass changeit || EXIT_STATUS=$?
${JAVA_HOME}/bin/keytool -import -trustcacerts -alias rootCaCrt -keystore /var/jenkins_home/cacerts -file /certs/cluster-ca.crt -noprompt -storepass changeit || EXIT_STATUS=$?
#${JAVA_HOME}/bin/keytool -import -trustcacerts -alias clusterca -keystore /var/jenkins_home/cacerts -file /certs/cluster-ca-bundle.pem -noprompt -storepass changeit || EXIT_STATUS=$?
#openssl s_client -showcerts -connect gitlab.${var.tls_san}:443 </dev/null 2> /dev/null | openssl x509 -outform PEM >  /var/jenkins_home/root_ca.pem  || EXIT_STATUS=$?
#${JAVA_HOME}/bin/keytool -import -trustcacerts -alias gitlabca -keystore /var/jenkins_home/cacerts -file /var/jenkins_home/root_ca.pem -noprompt -storepass changeit  || EXIT_STATUS=$?
mkdir -p ${NOMAD_ALLOC_DIR}/data/security
cp  /var/jenkins_home/cacerts ${NOMAD_ALLOC_DIR}/data/security || EXIT_STATUS=$?
echo "Finished gen cert" || EXIT_STATUS=$?
mkdir -p ${NOMAD_ALLOC_DIR}/data/docker_certs
cp /certs/cluster-ca-bundle.pem ${NOMAD_ALLOC_DIR}/data/docker_certs/ca.pem || EXIT_STATUS=$?
cp /certsdocker/docker-client.pem ${NOMAD_ALLOC_DIR}/data/docker_certs/cert.pem || EXIT_STATUS=$?
cp /certsdocker/docker-client-key.pem ${NOMAD_ALLOC_DIR}/data/docker_certs/key.pem || EXIT_STATUS=$?
exit $EXIT_STATUS
EOF
        destination   = "local/gen.sh"
        change_mode   = "noop"
      }
      resources {
        cpu    = 200
        memory = 128
      }
    }

    task "jenkins-task" {
      driver = "docker"
      volume_mount {
        volume      = "nomad_volume_stack_cicd_jenkins"
        destination = "/var/jenkins_home"
      }

      // Need for os level action like git
      volume_mount {
        # OS certifate folders
        #  "/etc/ssl/certs/ca-certificates.crt",              // Debian/Ubuntu/Gentoo etc.
        #"/etc/pki/tls/certs/ca-bundle.crt",                  // Fedora/RHEL 6
        #"/etc/ssl/ca-bundle.pem",                            // OpenSUSE
        #"/etc/pki/tls/cacert.pem",                           // OpenELEC
        #"/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem", // CentOS/RHEL 7
        #"/etc/ssl/cert.pem",                                 // Alpine Linux
        volume      = "ca_cert"
        destination = "/etc/ssl/certs/"
      }

      volume_mount {
        volume      = "cert_consul"
        destination = "/etc/opt/certs/consul"
      }

      volume_mount {
        volume      = "cert_nomad"
        destination = "/etc/opt/certs/nomad"
      }

      config {
        image = "registry.${var.tls_san}/${var.image_jenkins}"
        ports = ["http","jnlp"]
        volumes = [
          "local/jasc.yaml:/var/jenkins_home/jenkins.yaml",
#        "../${NOMAD_ALLOC_DIR}/data/security:/etc/ssl/certs/java/cacerts",
        "../${NOMAD_ALLOC_DIR}/data/security/cacerts:/opt/java/openjdk/lib/security/cacerts",
        "../${NOMAD_ALLOC_DIR}/data/docker_certs/:/var/jenkins_home/.docker",
        "local/settings.xml:/var/jenkins_home/.m2/settings.xml",
        ]
      }
      env{
        JAVA_OPTS ="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Dhudson.model.DownloadService.noSignatureCheck=true"
        DOCKER_HOST = "${var.docker_host}"
        DOCKER_TLS_VERIFY = 1
        DOCKER_BUILDKIT = 1
        //Nomad address with port
        NOMAD_ADDR="https://${attr.nomad.advertise.address}"
        NOMAD_CACERT="/etc/ssl/certs/cluster-ca-bundle.pem"
        NOMAD_CLIENT_CERT="/etc/opt/certs/nomad/nomad-cli.pem"
        NOMAD_CLIENT_KEY="/etc/opt/certs/nomad/nomad-cli-key.pem"
        CONSUL_CACERT="/etc/ssl/certs/cluster-ca-bundle.pem"
        CONSUL_HTTP_SSL=true
        CONSUL_HTTP_SSL_VERIFY=true
        CONSUL_HTTP_ADDR="${attr.unique.network.ip-address}:8501"
        CONSUL_CLIENT_KEY="/etc/opt/certs/consul/consul-key.pem"
        CONSUL_CLIENT_CERT="/etc/opt/certs/consul/consul.pem"
      }
      template {
        right_delimiter = "++"
        left_delimiter  = "++"
        change_mode   = "noop"
        destination   = "local/settings.xml"
        data            = <<EOF
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                      http://maven.apache.org/xsd/settings-1.0.0.xsd">

<!--
  <mirrors>
	 <mirror>
      <mirrorOf>external:http:*</mirrorOf>
      <name>Pseudo repository to mirror external repositories initially using HTTP.</name>
	  <url>http://${var.docker_host}:5002/repository/maven-public/</url>
      <blocked>false</blocked>
      <id>maven-default-http-blocker</id>
    </mirror>
  </mirrors>
-->
    <servers>
        <server>
            <id>releases</id>
            <username>development</username>
            <password>development123</password>
        </server>
        <server>
            <id>snapshots</id>
            <username>development</username>
            <password>development123</password>
        </server>
    </servers>
    <profiles>

        <profile>
            <id>nexus</id>
            <!--Enable snapshots for the built in central repo to direct -->
            <!--all requests to nexus via the mirror -->
            <repositories>
                <repository>
                    <id>nexusLocal</id>
			 <!--		<url>http://10.83.201.64:8081/repository/maven-public/</url>-->
                        <url>https://nexus.${var.tls_san}/repository/maven-public/</url>
                    <releases>
                        <enabled>true</enabled>
                        <updatePolicy>never</updatePolicy>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                        <updatePolicy>always</updatePolicy>
                    </snapshots>
                </repository>
            </repositories>
            <pluginRepositories>
                <pluginRepository>
                    <id>nexusLocalPlugins</id>
               	 <!--     <url>http://10.83.201.64:8081/repository/maven-public/</url>-->
				      <url>https://nexus.${var.tls_san}/repository/maven-public/</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                        <updatePolicy>always</updatePolicy>
                    </snapshots>
                </pluginRepository>
            </pluginRepositories>
        </profile>

    </profiles>

    <activeProfiles>
        <activeProfile>nexus</activeProfile>
    </activeProfiles>
    <proxies>

    </proxies>

</settings>

EOF
      }
# configuration-as-code plugin is required for that
# https://plugins.jenkins.io/configuration-as-code/
# Export current settings with https://jenkins.${var.tls_san}/configuration-as-code/

      template {
        right_delimiter = "++"
        left_delimiter = "++"
        data = <<EOF
credentials:
  system:
    domainCredentials:
    - credentials:
      - usernamePassword:
          description: "username and password for gitlab at 10.83.201.64"
          id: "jenkinsbotUsernamePassword"
          password: "{AQAAABAAAAAQyhOLbLiZRMfjr03vbNKwpd7lgfRrvnZZPx1xp11W0Ys=}"
          scope: GLOBAL
          username: "jenkinsbot"
      - string:
          description: "API Access Token for gitlab at 10.83.201.64"
          id: "jenkinsbotGitlabApiToken"
          scope: GLOBAL
          secret: "{AQAAABAAAAAgeUcaRybDSebDtxE1yamCbwxR2zJxEFpBCBVR0M05MXKrkvDgzW1/Sb0O/ScUKBaB}"
      - usernamePassword:
          description: "Jenkins bot username with api token as passowrd for gitlab\
            \ at 10.83.201.64 ( Http Access )"
          id: "jenkinsbotUsernameAndApiToken"
          password: "{AQAAABAAAAAg8I+Myq8CejFef2cBwramMMibBOPc25iRk9d2KhMUu9iGSf1rgV8muvLQpMPhcmCI}"
          scope: GLOBAL
          username: "jenkinsbot"
      - usernamePassword:
          description: "Service Account for sending emails over sms email server"
          id: "emailsender"
          password: "{AQAAABAAAAAg+2KJZla4tJGM8+g+33C59nBjrA77PwyduXrQVj4NDn6v5qkTme2J9PgPOiLG6t4a}"
          scope: GLOBAL
          username: "WMS-SLN"
jenkins:
  agentProtocols:
  - "Ping"
  authorizationStrategy: "loggedInUsersCanDoAnything"
  clouds:
  - nomad:
      clientCertificate: "/etc/opt/certs/nomad/nomad-cli.pem"
      clientPassword: "{AQAAABAAAADQQGh3P2JEQruNTBR/WMWcBWckccOgFQWOIgfRKlmLUZjkwp7kAfVJQ50cHNWAokIsVxS+TGbdxHOoQd3k9ebEGd1c51fNU76DY64KAd7dsDDMVKgeOOEBBy5w7isVbGyniR1PY11lm5fZPZ1sodaCJzUUFfYVHSWezax6pDUPe+3ZPGNGeV1syqlFxWRbqd4h/wYyXFOQXfHVaKyoP7V/QoXDCBf0R4Gg5naGoZfaNxMkwUvFXq3vuGU7bUerXA1C41tOEqIX3z44Gifqm4GLZGDK9/3xPUdB+WBrwyBpeSA=}"
      name: "CloudPrivate"
      nomadUrl: "https://10.128.82.220:4646"
      prune: true
      serverCertificate: "/etc/ssl/certs/cluster-ca-bundle.pem"
      serverPassword: "{AQAAABAAAADQXDZ10z3vmre8MTq031u1YumnDbm/XVGuc+0l2lGT0vxWdha7milwBQfSudvTywYQzRTBFhYDlfBpJNyhqgbVzLiaYGCWswytexqsB+FXlboOh50pS60l9eTLSTqk5+s5bXoXelwhFvwqDkQBbQBqJsz0JmIGPSesg04cGqgghzjB4CYhjEJjRrhpWLOfUIDMnH1GIdWUjJp8IxfjTub0KLeHBFeaaa+7GmiNI8RxWaMrYVtxB8KiROHt5pJWS49KFmkmvxrfIXqbIa89GDUTTx+MsRuP0J31JkOjwuttIbY=}"
      tlsEnabled: true
      workerTimeout: 1
  crumbIssuer:
    standard:
      excludeClientIPFromCrumb: true
  disableRememberMe: false
  disabledAdministrativeMonitors:
  - "hudson.util.DoubleLaunchChecker"
  labelAtoms:
  - name: "built-in"
  markupFormatter: "plainText"
  mode: NORMAL
  myViewsTabBar: "standard"
  numExecutors: 2
  primaryView:
    all:
      name: "all"
  projectNamingStrategy: "standard"
  quietPeriod: 5
  remotingSecurity:
    enabled: true
  scmCheckoutRetryCount: 0
  securityRealm:
    oic:
      authorizationServerUrl: "https://security.amovacloud.private/realms/nomadder/protocol/openid-connect/auth"
      automanualconfigure: "manual"
      clientId: "jenkins"
      clientSecret: "{AQAAABAAAAAwD4+TD/nb+1lczDLZKqmLnJ/V8bUNUROnyg381zsjSuE65skA5KEyYlKXYGt/N/uwzRm+M4X2AyCMw31lkxh4EQ==}"
      disableSslVerification: true
      endSessionEndpoint: "https://security.amovacloud.private/realms/nomadder/protocol/openid-connect/logout?client_id=jenkins&post_logout_redirect_uri=https://jenkins.amovacloud.private"
      fullNameFieldName: "preferred_username"
      groupsFieldName: "group-membership"
      overrideScopes: "web-origins address phone openid profile offle_access roles\
        \ microprofile-jwt email"
      overrideScopesDefined: true
      rootURLFromRequest: true
      scopes: "openid email profile"
      sendScopesInTokenRequest: true
      tokenAuthMethod: "client_secret_post"
      tokenServerUrl: "https://security.amovacloud.private/realms/nomadder/protocol/openid-connect/token"
      userInfoServerUrl: "https://security.amovacloud.private/realms/nomadder/protocol/openid-connect/userinfo"
      userNameField: "preferred_username"
  slaveAgentPort: 50000
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code\
    \ plugin\r\n\r\n"
  updateCenter:
    sites:
    - id: "default"
      url: "https://updates.jenkins.io/update-center.json"
  views:
  - all:
      name: "all"
  viewsTabBar: "standard"
globalCredentialsConfiguration:
  configuration:
    providerFilter: "none"
    typeFilter: "none"
security:
  apiToken:
    creationOfLegacyTokenEnabled: false
    tokenGenerationOnCreationEnabled: false
    usageStatisticsEnabled: true
  gitHooks:
    allowedOnAgents: false
    allowedOnController: false
  gitHostKeyVerificationConfiguration:
    sshHostKeyVerificationStrategy: "noHostKeyVerificationStrategy"
  globalJobDslSecurityConfiguration:
    useScriptSecurity: true
  sSHD:
    port: -1
  scriptApproval:
    approvedSignatures:
    - "method groovy.lang.GroovyObject invokeMethod java.lang.String java.lang.Object"
unclassified:
  buildDiscarders:
    configuredBuildDiscarders:
    - "jobBuildDiscarder"
  buildStepOperation:
    enabled: false
  defaultDisplayUrlProvider:
    providerId: "org.jenkinsci.plugins.displayurlapi.ClassicDisplayURLProvider"
  email-ext:
    adminRequiredForTemplateTesting: false
    allowUnregisteredEnabled: false
    charset: "UTF-8"
    debugMode: true
    defaultBody: |-
      $PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:

      Check console output at $BUILD_URL to view the results.
    defaultContentType: "text/html"
    defaultSubject: "$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!"
    defaultTriggerIds:
    - "hudson.plugins.emailext.plugins.trigger.FailureTrigger"
    mailAccount:
      credentialsId: "emailsender"
      smtpHost: "smssysmail.sms-group.com"
    maxAttachmentSize: -1
    maxAttachmentSizeMb: -1
    precedenceBulk: false
    watchingEnabled: false
  enrichedSummaryConfig:
    enrichedSummaryEnabled: false
    httpClientDelayBetweenRetriesInSeconds: 1
    httpClientMaxRetries: 3
    httpClientTimeoutInSeconds: 1
  fingerprints:
    fingerprintCleanupDisabled: false
    storage: "file"
  gitHubConfiguration:
    apiRateLimitChecker: ThrottleForNormalize
  gitHubPluginConfig:
    hookUrl: "https://jenkins.amovacloud.private/github-webhook/"
  gitLabConnectionConfig:
    connections:
    - apiTokenId: "jenkinsbotGitlabApiToken"
      clientBuilderId: "autodetect"
      connectionTimeout: 10
      ignoreCertificateErrors: true
      name: "GitlabLocalconnection"
      readTimeout: 10
      url: "http://10.83.201.64"
    useAuthenticatedEndpoint: true
  gitLabServers:
    servers:
    - credentialsId: "jenkinsbotGitlabApiToken"
      manageSystemHooks: true
      manageWebHooks: true
      name: "GitlabLocalServer"
      serverUrl: "http://10.83.201.64"
      webhookSecretCredentialsId: "jenkinsbotGitlabApiToken"
  globalLibraries:
    libraries:
    - defaultVersion: "main"
      name: "jenkins-amova-lib"
      retriever:
        modernSCM:
          libraryPath: "."
          scm:
            git:
              credentialsId: "jenkinsbotUsernameAndApiToken"
              id: "9859cc51-efb4-4f99-82bc-691109eed7ee"
              remote: "http://10.83.201.64/jenkins/jenkins-amova-lib.git"
              traits:
              - "gitBranchDiscovery"
  globalTimeOutConfiguration:
    operations:
    - "abortOperation"
    overwriteable: false
  hashicorpVault:
    configuration:
      engineVersion: 2
      timeout: 60
  injectionConfig:
    allowUntrusted: false
    checkForBuildAgentErrors: false
    enabled: false
    enforceUrl: false
    injectCcudExtension: false
    injectMavenExtension: false
  junitTestResultStorage:
    storage: "file"
  location:
    adminAddress: "jenkins@amovacloud.private"
    url: "https://jenkins.amovacloud.private/"
  mailer:
    charset: "UTF-8"
    useSsl: false
    useTls: false
  mavenModuleSet:
    localRepository: "default"
  pollSCM:
    pollingThreadCount: 10
  prismConfiguration:
    theme: PRISM
  resourceRoot:
    url: "https://jenkins-resources.amovacloud.private/"
  scmGit:
    addGitTagAction: false
    allowSecondFetch: false
    createAccountBasedOnEmail: false
    disableGitToolChooser: false
    hideCredentials: false
    showEntireCommitSummaryInChanges: false
    useExistingAccountWithSameEmail: false
tool:
  customTool:
    installations:
    - name: "Nomad"
      properties:
      - installSource:
          installers:
          - zip:
              url: "https://releases.hashicorp.com/nomad/1.6.3/nomad_1.6.3_linux_amd64.zip"
    - name: "Consul"
      properties:
      - installSource:
          installers:
          - zip:
              url: "https://releases.hashicorp.com/consul/1.17.0/consul_1.17.0_linux_amd64.zip"
  dockerTool:
    installations:
    - name: "Docker"
      properties:
      - installSource:
          installers:
          - fromDocker:
              version: "24.0.2"
  git:
    installations:
    - home: "git"
      name: "Default"
  jdk:
    installations:
    - name: "JDK_1_8"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "openlogic-openjdk-8u392-b08-linux-x64"
              url: "https://builds.openlogic.com/downloadJDK/openlogic-openjdk/8u392-b08/openlogic-openjdk-8u392-b08-linux-x64.tar.gz"
    - name: "JDK_16"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "jdk-16.0.2"
              url: "https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-x64_bin.tar.gz"
    - name: "JDK_17"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "jdk-17.0.2"
              url: "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz"
    - name: "JDK_18"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "jdk18.0.2"
              url: "https://download.java.net/java/GA/jdk18.0.2/f6ad4b4450fd4d298113270ec84f30ee/9/GPL/openjdk-18.0.2_linux-x64_bin.tar.gz"
    - name: "JDK_19"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "jdk-19.0.1"
              url: "https://download.java.net/java/GA/jdk19.0.1/afdd2e245b014143b62ccb916125e3ce/10/GPL/openjdk-19.0.1_linux-x64_bin.tar.gz"
    - name: "JDK_20"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "jdk-20"
              url: "https://download.java.net/java/GA/jdk20/bdc68b4b9cbc4ebcb30745c85038d91d/36/GPL/openjdk-20_linux-x64_bin.tar.gz"
    - name: "JDK_21"
      properties:
      - installSource:
          installers:
          - zip:
              subdir: "jdk-21"
              url: "https://download.java.net/java/GA/jdk21/fd2272bbf8e04c3dbaee13770090416c/35/GPL/openjdk-21_linux-x64_bin.tar.gz"
  maven:
    installations:
    - name: "Maven"
      properties:
      - installSource:
          installers:
          - maven:
              id: "3.9.5"
  mavenGlobalConfig:
    globalSettingsProvider: "standard"
    settingsProvider: "standard"
  pipelineMaven:
    globalTraceability: false
    triggerDownstreamUponResultAborted: false
    triggerDownstreamUponResultFailure: false
    triggerDownstreamUponResultNotBuilt: false
    triggerDownstreamUponResultSuccess: true
    triggerDownstreamUponResultUnstable: false
              EOF
        change_mode   = "noop"
        destination   = "local/jasc.yaml"
      }
      resources {
        cpu    = 1000
        memory = 2048
        memory_max= 32192
      }
    }
  }
}
