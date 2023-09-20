# alertmanager['enable'] = false
# gitlab_exporter['enable'] = false
# gitlab_pages['enable'] = false
# gitlab_workhorse['enable'] = false
# grafana['enable'] = false
# logrotate['enable'] = false
# gitlab_rails['incoming_email_enabled'] = false
# nginx['enable'] = false
# node_exporter['enable'] = false
# postgres_exporter['enable'] = false
# postgresql['enable'] = false
# prometheus['enable'] = false
# puma['enable'] = false
# redis['enable'] = false
# redis_exporter['enable'] = false
# registry['enable'] = false
# sidekiq['enable'] = false



gitlab_rails['omniauth_auto_link_user'] = ['openid_connect']
gitlab_rails['gitlab_default_projects_features_wiki'] = false
#gitlab_rails['gitlab_default_projects_features_container_registry'] = false
prometheus['enable'] = false
grafana['enable'] = false
# https://docs.gitlab.com/ee/administration/auth/oidc.html
gitlab_rails['omniauth_sync_email_from_provider'] = 'openid_connect'
gitlab_rails['omniauth_sync_profile_from_provider'] = ['openid_connect']
gitlab_rails['omniauth_sync_profile_attributes'] = ['email']
gitlab_rails['omniauth_allow_single_sign_on'] = ['openid_connect']
#gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'openid_connect'
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_external_providers'] = ['openid_connect']

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
        secret: "YLHtzHOjVwFyVxIiSaF1L8udGjVtl2Y7",
        redirect_uri: "https://gitlab.cloud.private/users/auth/openid_connect/callback",
      }
    }
  }
]
