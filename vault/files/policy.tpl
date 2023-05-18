%{ for name, shard in databases ~}
path "${path}/creds/${name}-${permissions}" {
    capabilities = ["read"]
}
%{ endfor ~}
path "${path}/roles" {
    capabilities = ["list"]
}

path "ssh/roles/*" {
    capabilities = ["list"]
}
%{ if permissions == "ro" ~}
path "ssh/creds/ssh-developer" {
    capabilities = ["update"]
}
%{ endif ~}
%{ if permissions == "rw" ~}
path "ssh/creds/ssh-admin" {
    capabilities = ["update"]
}
%{ endif ~}
