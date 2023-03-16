job "security" {
  type        = "service"
  datacenters = ["nomadder1"]
  group "keycloak-ingress" {
    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
    }
    count = 1
    network {
      mode = "bridge"
      port "auth" {
        to = 4181
      }
    }
    service {
      name = "forwardauth"
      port = "auth"
      #        port = "8080"
      #        connect {
      #          sidecar_service {}
      #        }
      tags = [
        "traefik.enable=true",
        #          "traefik.consulcatalog.connect=true",
        "traefik.http.routers.forwardauth.entrypoints=https",
        "traefik.http.routers.forwardauth.rule= Path(`/_oauth`)",
        "traefik.http.routers.forwardauth.middlewares=traefik-forward-auth",
        "traefik.http.routers.traefik-forward-auth.tls=true",
        "traefik.http.middlewares.traefik-forward-auth.forwardauth.address=http://forwardauth.service.consul:${NOMAD_HOST_PORT_auth}",
        "traefik.http.middlewares.traefik-forward-auth.forwardauth.authResponseHeaders= X-Forwarded-User",
        "traefik.http.middlewares.traefik-forward-auth.forwardauth.authResponseHeadersRegex= ^X-",
        "traefik.http.middlewares.traefik-forward-auth.forwardauth.trustForwardHeader=true",
        "traefik.http.middlewares.test-auth.forwardauth.tls.insecureSkipVerify=true"
      ]


    }
    task "forwardauth" {
      driver = "docker"
      env {
        #        https://brianturchyn.net/traefik-forwardauth-support-with-keycloak/
        #        https://github.com/mesosphere/traefik-forward-auth/issues/36
        #        INSECURE_COOKIE = "1"
        ENCRYPTION_KEY = "45659373957778734945638459467936" #32 character encryption key
        #        COOKIE_DOMAIN = "*cloud.private"
        #        SCOPE = "profile email openid" # scope openid is necessary for keycloak...
        SECRET        = "9e7d7b0776f032e3a1996272c2fe22d2"
        PROVIDER_URI  = "https://security.cloud.private/realms/nomadder"
        #        OIDC_ISSUER   = "https://security.cloud.private/realms/nomadder"
        CLIENT_ID     = "ingress"
        CLIENT_SECRET = "XMgvP4XBduDKQJTNJGyQ6dg1uTXTscmH"
        LOG_LEVEL     = "debug"
        #        AUTH_HOST     = "http://forwardauth.service.consul:${NOMAD_HOST_PORT_auth}"

      }
      volume_mount {
        volume      = "ca_cert"
        destination = "/etc/ssl/certs/"
      }
      config {
        image = "mesosphere/traefik-forward-auth:3.1.0"
        #        image = "thomseddon/traefik-forward-auth:latest"
        ports = ["auth"]
      }
      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
  group "keycloak" {
    count = 1
    network {
      mode = "bridge"
      port "ui" {
        to = 8080
      }
    }

    service {
      name = "keycloak"
      #      port = "ui"
      port = "8080"
      connect {
        sidecar_service {}
      }
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.keycloak.tls=true",
        "traefik.http.routers.keycloak.rule=Host(`security.cloud.private`)",
      ]


      check {
        name     = "health"
        type     = "http"
        port     = "ui"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }
    task "keycloak" {
      driver = "docker"
      env {
        KEYCLOAK_ADMIN           = "admin"
        KEYCLOAK_ADMIN_PASSWORD  = "admin"
        KC_HTTP_ENABLED          = "true"
        KC_HOSTNAME_STRICT_HTTPS = "false"
        KC_HEALTH_ENABLED        = "true"
        KC_HOSTNAME              = "security.cloud.private"
        KC_PROXY                 = "edge"
      }
      config {
        image = "registry.cloud.private/stack/core/keycloak:19.0.2.3"
        ports = ["ui"]
        args  = [
          "start", "--optimized"
        ]
      }
      resources {
        cpu    = 1000
        memory = 2048
      }
    }
  }
}