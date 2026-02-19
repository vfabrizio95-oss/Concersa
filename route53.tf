resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Zona para ${local.prefix}"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name = aws_cloudfront_distribution.frontend.domain_name
    zone_id = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "frontend" {
  fqdn              = aws_cloudfront_distribution.frontend.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}
