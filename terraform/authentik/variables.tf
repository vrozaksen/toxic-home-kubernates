variable "bw_access_token" {
  type        = string
  description = "Bitwarden Secret Manager Access token"
  sensitive   = true
}

variable "cluster_domain" {
  type        = string
  description = "Domain for Authentik"
  default     = "vzkn.eu"
}
