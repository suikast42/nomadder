https://docs.gitlab.com/ee/administration/auth/oidc.html

1. Create a keycloak client with name gitlab


paste in the last section of gitlab

``` rubby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/etc/gitlab/trusted-certs/cluster-ca.crt"}
gitlab_rails['omniauth_providers'] = [
{
    name: "openid_connect", # do not change this parameter
    label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
    args: {
        name: "openid_connect",
        scope: ["openid", "profile", "email"],
        response_type: "code",
        issuer:  "https://security.cloud.private/realms/nomadder",
        client_auth_method: "query",
        discovery: true,
        uid_field: "preferred_username",
        pkce: true,
        client_options: {
            identifier: "gitlab",
            secret: "yX4MiFyFCGHFPm3VXVs146JFofPuUfUQ",
            authorization_endpoint: "https://security.cloud.private/realms/nomadder/protocol/openid-connect/auth",
            token_endpoint: "https://security.cloud.private/realms/nomadder/protocol/openid-connect/token",
            userinfo_endpoint: "https://security.cloud.private/realms/nomadder/protocol/openid-connect/userinfo",
            redirect_uri: "https://gitlab.cloud.private/users/auth/openid_connect/callback",
        }
    }
}
]

```

https://gitlab.cloud.private/admin/application_settings/general
* Edit  Admin Area -> Setting -> General -> Sign-up restrictions -> Sign-out page URL and enter
https://security.cloud.private/realms/nomadder/protocol/openid-connect/logout?client_id=gitlab&post_logout_redirect_uri=https://gitlab.cloud.private


Login to gitlab conatiner and execute 
``` shell
gitlab-ctl reconfigure
```


## Jenkins rest API 
* List plugin names
https://jenkins.cloud.private/pluginManager/api/json?tree=plugins[shortName]
 https://jenkins.cloud.private/pluginManager/api/xml?tree=plugins[shortName]
* List all plugins
  https://jenkins.cloud.private/pluginManager/api/json?depth=1
* https://jenkins.cloud.private/pluginManager/api/xml?depth=1

##TODOS

1. HOW to manage users over keycloak so that we don't need a user management in gitlab
2. Import cluster certificate to jenkins