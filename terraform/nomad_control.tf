

provider "tfe" {
  hostname = "${var.tfe_hostname}"
  token    = "${var.tfe_user_token}"
}

provider "nomad" {
  address = "${data.terraform_remote_state.cluster_details.nomad-ui-us-east-1}"
  region  = "us-east-2"
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

data "terraform_remote_state" "cluster_details" {
  backend = "atlas"

  config {
    name = "${var.org}/${var.org}-Nomad-Control"
  }
}
 

