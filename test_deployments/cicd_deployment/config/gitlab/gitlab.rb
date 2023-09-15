# gitlab_rails['omniauth_providers'] = [
#   {
#     name: "oauth2_generic",
#     label: "Keycloak Nomadder 1", # optional label for login button, defaults to "Oauth2 Generic"
#     app_id: "gitlab",
#     app_secret: "YLHtzHOjVwFyVxIiSaF1L8udGjVtl2Y7",
#     args: {
#       client_options: {
#         site: "https://security.cloud.private",
#         user_info_url: "/realms/nomadder/protocol/openid-connect/userinfo",
#         authorize_url: "/realms/nomadder/protocol/openid-connect/auth",
#         token_url: "/realms/nomadder/protocol/openid-connect/token"
#       },
#       user_response_structure: {
#         root_path: [],
#         id_path: ["sub"],
#         attributes: {
#           email: "email",
#           name: "name"
#         }
#       },
#       authorize_params: {
#         scope: "openid profile email"
#       },
#       strategy_class: "OmniAuth::Strategies::OAuth2Generic"
#     }
#   }
# ]



gitlab_rails['omniauth_auto_link_user'] = ['openid_connect']
gitlab_rails['gitlab_default_projects_features_wiki'] = false
gitlab_rails['gitlab_default_projects_features_container_registry'] = false
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
