AUTHENTICATION_SOURCES = ["oauth2", "internal"]
OAUTH2_AUTO_CREATE_USER = True
MASTER_PASSWORD_REQUIRED = False
OAUTH2_CONFIG = [{
    "OAUTH2_NAME": "authelia",
    "OAUTH2_DISPLAY_NAME": "Login with Authelia",
    'OAUTH2_CLIENT_ID': '{{ .PGADMIN_OIDC_CLIENT_ID }}',
    'OAUTH2_CLIENT_SECRET': '{{ .PGADMIN_OIDC_CLIENT_SECRET }}',
    "OAUTH2_TOKEN_URL": "https://auth.${SECRET_DOMAIN}/api/oidc/token",
    "OAUTH2_AUTHORIZATION_URL": "https://auth.${SECRET_DOMAIN}/api/oidc/authorization",
    "OAUTH2_API_BASE_URL": "https://auth.${SECRET_DOMAIN}/",
    "OAUTH2_USERINFO_ENDPOINT": "https://auth.${SECRET_DOMAIN}/api/oidc/userinfo",
    "OAUTH2_SERVER_METADATA_URL": "https://auth.${SECRET_DOMAIN}/.well-known/openid-configuration",
    "OAUTH2_SCOPE": "openid email profile",
    "OAUTH2_ICON": "fa-openid",
    "OAUTH2_BUTTON_COLOR": "#2db1fd"
}]
