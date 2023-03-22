locals {
  namespace = "${var.organization}-${var.project}-${var.environment}-${var.location}${var.postfix}"
}
