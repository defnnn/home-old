pi_file = "/vault/pid"

exit_after_auth = false

vault {
  address = "https://vault.global.defn.sh"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path = "/vault/role_id"
      secret_id_file_path = "/vault/secret_id"
      secret_id_response_wrapping_path = "auth/approle/role/defn/secret-id"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token"
    }
  }
}

cache {
  use_auto_auth_token = false
}
