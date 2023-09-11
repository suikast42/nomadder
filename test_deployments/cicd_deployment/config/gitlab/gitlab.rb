gitlab_rails['omniauth_providers'] = [
  {
    name: "oauth2_generic",
    label: "Keycloak Nomadder 1", # optional label for login button, defaults to "Oauth2 Generic"
    app_id: "gitlab",
    app_secret: "YLHtzHOjVwFyVxIiSaF1L8udGjVtl2Y7",
    args: {
      client_options: {
        site: "https://security.cloud.private",
        user_info_url: "/realms/nomadder/protocol/openid-connect/userinfo",
        authorize_url: "/realms/nomadder/protocol/openid-connect/auth",
        token_url: "realms/nomadder/protocol/openid-connect/token"
      },
      user_response_structure: {
        root_path: [],
        id_path: ["sub"],
        attributes: {
          email: "email",
          name: "name"
        }
      },
      authorize_params: {
        scope: "openid profile email"
      },
      strategy_class: "OmniAuth::Strategies::OAuth2Generic"
    }
  }
]