variable "bw_access_token" {
  type        = string
  description = "Bitwarden Secret Manager Access token"
  sensitive   = true
}

variable "minio_url" {
  type        = string
  description = "Minio Server URL"
  default     = "10.0.20.10:9000"
}
