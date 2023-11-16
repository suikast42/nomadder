### Prepare Gitlab

1. Login to gitlab
2. Create an account jenkinsbot with password jenkins@bot
3. Add this user to the groups you want to build with jenkins with Maintainer access
4. Logout with admin and login with jenkinsbot
5. Create a api access token for jenkinsbot
6. Allow fetch local resources ( For import projects from local git instances ).Admin -> Settings -> Network ->
   Outbound Requests -> Allow requests to the local network from hooks and services

You can define group project or personal access token for acessing gitlab from jenkins
<br>It is more suitable to define a user named `jenkinsbot` and create a presonal access token for that user.
<br> after that you can give access to to this user for group and/or projects on gitlab

## Prepare jenkins

1. Login to jenkins
2. Set the values for `jenkinsbotUsernamePassword` ,`jenkinsbotGitlabApiToken`   and `jenkinsbotUsernameAndApiToken` with the values from gitlab. The casc plugin does not export the security information like pwd an token.
   </br>jenkinsbotUsernameAndApiToken is needed for gitlab http access. The Jenkins projects should refer to this token if the gitlab server uses http access instead of https
## Add git as remote in intelij

1. git config http.sslVerify false
   or for all repos git config --global http.sslVerify false

## Post configuration Gitlab Webhooks

The Webhook plugin needed for triggering multibranch job types in jenkins
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
