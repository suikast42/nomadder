## OIDC

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

* Edit Admin Area -> Setting -> General -> Sign-up restrictions -> Sign-out page URL and enter
  https://security.cloud.private/realms/nomadder/protocol/openid-connect/logout?client_id=gitlab&post_logout_redirect_uri=https://gitlab.cloud.private

Login to gitlab conatiner and execute

``` shell
gitlab-ctl reconfigure
```

## Jenkins Help links

* Current jenkins settings
  https://jenkins.cloud.private/configuration-as-code/
* List jenkins env vars
  https://jenkins.cloud.private/env-vars.html/
  https://www.lambdatest.com/blog/set-jenkins-pipeline-environment-variables-list/
* List plugin names
  https://jenkins.cloud.private/pluginManager/api/json?tree=plugins[shortName]
 https://jenkins.cloud.private/pluginManager/api/xml?tree=plugins[shortName]
* List all plugins
  https://jenkins.cloud.private/pluginManager/api/json?depth=1
* https://jenkins.cloud.private/pluginManager/api/xml?depth=1
* Example jenkins file docker engine
  https://github.com/moby/moby/blob/master/Jenkinsfile
* Nomad gitlab ci cd example
https://gitlab.com/internetarchive/nomad/-/blob/master/project.nomad#L118
* Dynamic job names nomad
  https://github.com/hashicorp/nomad/issues/9522
* Github Darin Pope
  https://github.com/darinpope
## Jenkins Gitlab integration

### Prepare Gitlab

1. Login to gitlab
2. Create an account jenkinsbot
3. Add this user to the groups you want tp build with jenkins with Maintainer access
4. Logout with admin and login with jenkinsbot
5. Create a api access token for jenkinsbot
6. Create a ssh key with ssh-keygen -t rsa -b 4096 -f id_rsa_gitlab -C "jenkinsbot@jenkins.cloud.private"
7. Import this ssh pub key for jenkinsbot user

You can define group project or personal access token for acessing gitlab from jenkins
<br>It is more suitable to define a user named `jenkinsbot` and create a presonal access token for that user.
<br> after that you can give access to to this user for group and/or projects on gitlab

## Prepare jenkins

1. Login to jenkins
2. Create credentials got gitlab server:
    1. Gitlab Personal Access Token named `jenkinsbotAccessToken` Token ( with jenkinsbot gitlab access token )
    2. Gitlab Api Token named `jenkinsbotApiToken` Token ( with jenkinsbot gitlab access token )
    3. Secret text named `jenkinsbotWebhookToken` ( with jenkinsbot gitlab access token )
    4. Secret ssh key named `jenkinsbotSshKey` ( with jenkinsbots' private key )
    4. Or Secret username password named `jenkinsbotUserNamePassword` ( with jenkinsbots' private key )

3. Configure gitlab server with the
   credentials `jenkinsbotAccessToken` , `jenkinsbotWebhookToken , jenkinsbotSshKey | jenkinsbotUserNamePassword`

4. allow fetch local resources ( For import projects from local git instances ). I found Admin -> Settings -> Network -> Outbound Requests -> Allow requests to the local network from hooks and services
## Add git as remote in intelij

1. git config http.sslVerify false
   or for all repos git config --global http.sslVerify false

## Post configuration Gitlab Webhooks

The Webhook plugin nedded for trieggering multibranc job types in jenkins
The jenkins integration in gitlab works only with normal pipeline jobs

1. In projects settings goto webhook and type the uri for webhook.
   http(s)://<jenkins url>/multibranch-webhook-trigger/invoke?token=<token>
   e.g.  https://jenkins.cloud.private/multibranch-webhook-trigger/invoke?token=11659c4ca9e551b27f86c46e750c5e7440
3. Do not forget to santinize the token un the url
3. Enable auto merge
   in [gitlab](https://docs.gitlab.com/ee/user/project/merge_requests/merge_when_pipeline_succeeds.html)

Gitlab jenkins Token: glpat-TWYXxAsrQCPk4MqNiJGy
Jenkins api token: 1167f9e99cd8d64fa9ae532a46ce1e5d0f

 <br>
 [How to gen SSH Key](https://geoweb.princeton.edu/research/jenkins-doc/tutorial_gitlab.html)
 <br>
 [Jenkins webook multibranch](https://santoshk.dev/posts/2022/how-to-setup-a-github-to-jenkins-pipeline-with-webhook/) 
## TODOS

1. HOW to manage users over keycloak so that we don't need a user management in gitlab
2. Import cluster certificate to jenkins