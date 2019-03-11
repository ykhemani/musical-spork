

provider "tfe" {
  hostname = "${var.tfe_hostname}"
  token    = "${var.tfe_user_token}"
}

resource "tfe_workspace" "nomad_control" {
  count = ${var.tfe_user_token == "Set Me" ? 0 : 1} 
  name         = "${var.org}-Nomad-Control"
  organization = "${var.org}"
  auto_apply   = false

  vcs_repo = {
    identifier     = "${var.vcs_identifier}"
    oauth_token_id = "${var.oauth_token}"
  }
}


