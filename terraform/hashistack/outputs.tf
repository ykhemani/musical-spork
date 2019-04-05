output "vault-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_lb.vault.dns_name}:8200/ui/" : "http://${element(concat(aws_route53_record.vault.*.name, list("")), 0)}:8200/ui/"}"
}

output "nomad-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_lb.nomad.dns_name}:4646/ui" : "http://${element(concat(aws_route53_record.nomad.*.name, list("")), 0)}:4646/ui"}"
}

output "nginx_hostname" {
  value = "${var.vanity_domain == "none" ? "https://${aws_lb.nginx.dns_name}" : "https://${element(concat(aws_route53_record.nginx.*.name, list("")), 0)}"}"
}
