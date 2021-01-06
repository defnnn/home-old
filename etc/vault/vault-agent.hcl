pi_file = "/vault/pid"

exit_after_auth = false

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

cache {
  use_auto_auth_token = false
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path = "/vault/jenkins_role_id"
      secret_id_file_path = "/vault/jenkins_secret_id"
      secret_id_response_wrapping_path = "auth/approle/role/jenkins/secret-id"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token"
      mode = 0600
    }
  }
}
