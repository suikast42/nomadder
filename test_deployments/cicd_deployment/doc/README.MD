# Setup CI/CD Pipeline with nomad
This guide intruduces a CI/CD setuo with gitlab and Jenkins on nomad. Ig you have already a gitlab setup.

1. Execute the jenkins build at first if not already done. !!! If you change the version then change it in the nomad job as well !!!
2. Login to keycloak an import the users in realm nomadder
3. Create the volumes and copy the nomad volume file to worker-02
4. Replace the clientSecret of configuration as code section from the job file with the jenkins secret from keycloak
4. Deploy the nomad job

## Configure Local git cli 
1. If you aim to work with a gitlab instance that works over https then you have to import the root ca certificate from the gitlab instance or you can ignore the ssl verification with:\

```shell
#Local
git config http.sslVerify false
# for all repos 
git config --global http.sslVerify false
```

## Configure Gitlab
1. Sign in to gitlab as a local user (root@local;lcl@admin is the default )
2. Sign in as regular gitlab user and got to https://gitlab.cloud.private/admin/application_settings/general \
   Paste this link https://security.cloud.private/realms/nomadder/protocol/openid-connect/logout?client_id=gitlab&post_logout_redirect_uri=https://gitlab.cloud.private \
   in the field Sign-in restrictions -> Sign-out page URL
3. Logout from gitlab
4. Login to the Vm where the gitlab volume is mounted and add the content of config/gitlab.rb 
5. Login to the chell of gitlab instance and type gitlab-ctl reconfigure
6. Sign in with keycloak account. ( Gitlab will create a local external account )
7. Login with local gitlab account lcl@admin again and make the external keycloak account as administrator if you needed. Set the access project limit fileds as well 
8. If gitlab should be able to import projects and groups from further local gitlab instance:
   1. Goto https://gitlab.cloud.private/admin/application_settings/network and enable Allow requests to the local network from webhooks and integrations and type the ip of your second instance in the field. [See](https://computingforgeeks.com/resolve-url-is-blocked-requests-to-the-local-network-are-not-allowed-gitlab-error/)
   2. Goto https://gitlab.cloud.private/admin/application_settings/general. 'Allow migrating GitLab groups and projects by direct transfer' must be enabled on source and desertion gitlab instance. 
   3. Create a personal full access token on destination  gitlab
   4. Goto New Group and then import group
9. Create a local gitlab account named jenkinsbot as regular user
10. Go to edit user jenkinsbot and set a passowrd jenkins@bot
11. Logout and login with jenkinsbot to gitlab
12. Create an access token for the jenkinsbot user. Delete the Expiration date and set all scopes. Copy this access token. This will not show again.   
13. Logut from gitlab with jenkinsbot and login again with admin account ( keycloak account in this example)
14. Add the jenkinsbot user to the groups you want to build with jenkins with Maintainer access

## Jenkins
1. Login to jenkins with the keycloak account 
2. Goto [jenkins credentials](https://jenkins.cloud.private/manage/credentials/store/system/domain/_/) and set `jenkinsbotUsernamePassword` (jenkinsbot) and `jenkinsbotAccessToken` ( with jenkinsbot gitlab access token ) `
3. Goto [jenkins security configuration](https://jenkins.cloud.private/manage/configureSecurity/) and allow all git hooks
4. Goto [jenkins system configuration](https://jenkins.cloud.private/manage/configure) and set the correct credentials and git server ( you can manage all gitlab connections here) 
   1. You must add a connection for gitlab  in section `Enable authentication for '/project' end-point`
   2. Add a gitlab server in section `GitLab Servers`
5. Create a multibranch pipeline
   1. Owner is the group name 
   2. Projects means the git project itself
   3. Strategy all branches
   4. Check Scan by webhook and define a custom token there. You can trigger a build with that url for example https://jenkins.cloud.private/multibranch-webhook-trigger/invoke?token=11659c4ca9e551b27f86c46e750c5e7440 \
   Jenkins will add a automated webhook in gitlab for the project. If not you can add the link above with your token. Do not forget Mask portions of URL for the token field



### Gitlab help links and pitfalls
1. If gitlab is not connected to internet then gitlab can't save settings
2. [Gitlab offline mode](https://docs.gitlab.com/ee/topics/offline/quick_start_guide.html)
3. [Specified URL cannot be used: "Requests to the local network are not allowed](https://computingforgeeks.com/resolve-url-is-blocked-requests-to-the-local-network-are-not-allowed-gitlab-error/)


### Jenkins Links 
* [Current jenkins settings](https://jenkins.cloud.private/configuration-as-code/)
* [List of jenkins env vars](https://jenkins.cloud.private/env-vars.html/)
* [How To Set Jenkins Pipeline Environment Variables](https://www.lambdatest.com/blog/set-jenkins-pipeline-environment-variables-list/)
* [List plugin names as json](https://jenkins.cloud.private/pluginManager/api/json?tree=plugins[shortName])
* [List plugin names as xml]( https://jenkins.cloud.private/pluginManager/api/xml?tree=plugins[shortName])
* [List all plugins json]( https://jenkins.cloud.private/pluginManager/api/json?depth=1)
* [List all plugins xml]( https://jenkins.cloud.private/pluginManager/api/xml?depth=1)
* [Example jenkins file docker engine](https://github.com/moby/moby/blob/master/Jenkinsfile)
* [Nomad gitlab ci cd example](https://gitlab.com/internetarchive/nomad/-/blob/master/project.nomad#L118)
* [Dynamic job names nomad](https://github.com/hashicorp/nomad/issues/9522)
* [Github Darin Pope](https://github.com/darinpope)