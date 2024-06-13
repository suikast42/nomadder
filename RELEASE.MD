## Update docker and docker compose
ansible-playbook 01_platform_playbook.yml --ask-vault-pass --extra-vars="uninstall_docker=true uninstall_compose=true update_nexus=true"


#Update 21:
ansible-playbook 01_platform_playbook.yml --ask-vault-pass --extra-vars="update_consul_template=true update_grafana_agent=true"
ansible-playbook 02_deploy_stacks_playbook.yml --ask-vault-pass --extra-vars="update_consul_template=true update_grafana_agent=true"

ansible-playbook 01_platform_playbook.yml --ask-vault-pass --extra-vars="update_consul=true"
