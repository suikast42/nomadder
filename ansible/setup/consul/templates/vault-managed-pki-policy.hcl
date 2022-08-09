# Existing PKI Mounts
# See https://www.consul.io/docs/connect/ca/vault
path "/sys/mounts" {
  capabilities = [ "read" ]
}

path "/sys/mounts/pki" {
  capabilities = [ "read" ]
}

path "/sys/mounts/pki_int" {
  capabilities = [ "read" ]
}

path "/pki/" {
  capabilities = [ "read" ]
}

path "/pki/root/sign-intermediate" {
  capabilities = [ "update" ]
}

path "/pki_int/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "auth/token/renew-self" {
  capabilities = [ "update" ]
}

path "auth/token/lookup-self" {
  capabilities = [ "read" ]
}
