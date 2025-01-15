data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

module "brand" {
  source                   = "l-with/authentik-brand/module"
  version                  = ">= 0.0.3"
  authentik_url            = "https://sso.${var.cluster_domain}"
  authentik_token          = local.authentik_token
  authentik_brand_default  = false
}

resource "authentik_brand" "home" {
  domain           = "${module.brand.authentik_module_brand_dummy}."
  default          = true
  branding_title   = "Home"
  branding_logo    = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon = "/static/dist/assets/icons/icon.png"

  flow_authentication = authentik_flow.authentication.uuid
  flow_invalidation   = authentik_flow.invalidation.uuid
  flow_user_settings  = authentik_flow.user-settings.uuid
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "local"
  local = true
}
