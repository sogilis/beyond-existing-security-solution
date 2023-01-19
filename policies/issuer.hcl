# Work with pki secrets engine
path "pki_int/issue/example-dot-local" {
    policy = "write"
}

path "pki_int/*" {
    capabilities = ["read"]
}

path "pki_int/roles" {
    capabilities = ["read", "list"]
}

# Manage tokens for verification
path "auth/token/create" {
    capabilities = [ "create", "read", "list"]
}
