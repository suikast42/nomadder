job "certgentest"{
 type= "batch"
  group "certgentest"{
    count = 1
    volume "ca_cert" {
      type      = "host"
      source    = "ca_cert"
      read_only = true
    }
    task "03-jenknins-cert-import" {

      volume_mount {
        volume      = "ca_cert"
        destination = "/certs"
      }

      driver = "docker"

      config {
        image   = "jenkins/jenkins:2.387.3-lts-jdk17"
        command = "/bin/sh"
#        args    = ["-c", "/var/jenkins_home/gen.sh"]
        args    = ["-c", "sleep 3000"]
        volumes = ["local/gen.sh:/var/jenkins_home/gen.sh"]
      }

      template {
        perms = "777"
        data = <<EOF
#!/bin/bash
EXIT_STATUS=0
echo "Starting gen cert"
cp -r ${JAVA_HOME}/lib/security/cacerts /var/jenkins_home/cacerts || EXIT_STATUS=$?
${JAVA_HOME}/bin/keytool -import -trustcacerts -alias rootCa -keystore /var/jenkins_home/cacerts -file /certs/ca.crt -noprompt -storepass changeit || EXIT_STATUS=$?
${JAVA_HOME}/bin/keytool -import -trustcacerts -alias rootCaCrt -keystore /var/jenkins_home/cacerts -file /certs/cluster-ca.crt -noprompt -storepass changeit || EXIT_STATUS=$?
${JAVA_HOME}/bin/keytool -import -trustcacerts -alias clusterca -keystore /var/jenkins_home/cacerts -file /certs/cluster-ca-bundle.pem -noprompt -storepass changeit || EXIT_STATUS=$?
#openssl s_client -showcerts -connect gitlab.cloud.private:443 </dev/null 2> /dev/null | openssl x509 -outform PEM >  /var/jenkins_home/root_ca.pem  || EXIT_STATUS=$?
#${JAVA_HOME}/bin/keytool -import -trustcacerts -alias gitlabca -keystore /var/jenkins_home/cacerts -file /var/jenkins_home/root_ca.pem -noprompt -storepass changeit  || EXIT_STATUS=$?
mkdir -p ${NOMAD_ALLOC_DIR}/data/security
cp  /var/jenkins_home/cacerts ${NOMAD_ALLOC_DIR}/data/security || EXIT_STATUS=$?
echo "Finished gen cert" || EXIT_STATUS=$?
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
  }
}