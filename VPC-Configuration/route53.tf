# --------------------------------------------------------------------------------------
# ROUTE 53 DNS RESOURCES
# --------------------------------------------------------------------------------------

# Import the hosted zone for the current environment (dev or demo)
data "aws_route53_zone" "domain_zone" {
  name = "${var.environment}.${var.domain_name}"
}

# A record pointing to the load balancer
resource "aws_route53_record" "app_domain" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = "${var.environment}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}