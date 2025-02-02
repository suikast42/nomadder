Adopt the env vars in [set_env.bat](set_env.bat) and run vagrant up

# BUG:
Somehow ansible does not connect over ssh to the vms on esxi.

Tested all this steps inside WSL but all oif them fails 

``` shell
ansible all -m ping  -vvv 
```

``` shell
ansible all -m ping -e 'ansible_ssh_common_args="-o Ciphers=aes128-ctr  -i /mnt/c/IDE/Projects_Git/playground/nomadder/ansible/environment/local_devops/inventory/../ssh/id_rsa"' -vvv
```

```shell
ssh -i /mnt/c/IDE/Projects_Git/playground/nomadder/ansible/environment/local_devops/inventory/../ssh/id_rsa cloudmaster@192.168.30.121
```

That works 

```shell
 ssh -o Ciphers=aes256-ctr -i /mnt/c/IDE/Projects_Git/playground/nomadder/ansible/environment/local_devops/inventory/../ssh/id_rsa cloudmaster@192.168.30.121
```
