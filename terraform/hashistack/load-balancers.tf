#Vault
resource "aws_lb" "vault" {
  name               = "${var.environment_name}-vault"
  load_balancer_type = "application"
  internal           = false
  subnets            = ["${var.public_subnet_ids}"]
  security_groups    = ["${aws_security_group.allow_all_hashistack.id}"]
}

resource "aws_lb_target_group" "vault" {
  port     = 8200
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path = "/v1/sys/health"
  }
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = "${aws_lb.vault.arn}"
  port              = "8200"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.vault.arn}"
    type             = "forward"
  }
}

resource "aws_lb" "nginx" {
  name               = "${var.environment_name}-nginx"
  load_balancer_type = "network"
  internal           = false
  subnets            = ["${var.public_subnet_ids}"]
}

resource "aws_lb_target_group" "nginx-http" {
  port     = 80
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_target_group" "nginx-https" {
  port     = 443
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "nginx-http" {
  load_balancer_arn = "${aws_lb.nginx.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nginx-http.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "nginx-https" {
  load_balancer_arn = "${aws_lb.nginx.arn}"
  port              = "443"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nginx-https.arn}"
    type             = "forward"
  }
}

resource "aws_lb" "nomad" {
  name               = "${var.environment_name}-nomad"
  load_balancer_type = "application"
  internal           = false
  subnets            = ["${var.public_subnet_ids}"]
  security_groups    = ["${aws_security_group.allow_all_hashistack.id}"]
}

resource "aws_lb_target_group" "nomad" {
  port     = 4646
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "nomad" {
  load_balancer_arn = "${aws_lb.nomad.arn}"
  port              = "4646"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nomad.arn}"
    type             = "forward"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_nomad" {
  autoscaling_group_name = "${aws_autoscaling_group.hashistack_server.id}"
  alb_target_group_arn   = "${aws_lb_target_group.nomad.arn}"
}
