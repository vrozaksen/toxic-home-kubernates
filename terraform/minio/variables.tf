variable "bw_access_token" {
  type        = string
  description = "Bitwarden Secret Manager Access token"
  sensitive   = true
}

variable "service_account_json" {
  type        = string
  description = "The path to the service account JSON for Bitwarden."
  sensitive   = true
  default     = null
}

variable "minio_url" {
  type        = string
  description = "Minio Server URL"
  default     = "https://minio.vrozaksen.eu"
}
