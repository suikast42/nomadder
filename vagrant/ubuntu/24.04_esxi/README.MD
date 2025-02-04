
# Initial privision

Adopt the env vars in [set_env.bat](set_env.bat) and run vagrant up

# Network Settings
For every provisioned vm

1. Delete all networks but  esxi.esxi_virtual_network.
2. Login via esxi to the dest machine and delete all configs but not 01-netcfg and 50-vagrant
3. replace your 50-vagrant.yaml with [50-vagrant.yaml](50-vagrant.yaml) ( Adopt your ip and namservers)
4. run sudo netplan apply





## FIXED with section Network Settings

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


