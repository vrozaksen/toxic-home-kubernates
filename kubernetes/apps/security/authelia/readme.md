# authelia

## Secrets

1. SECRET_AUTHELIA_JWT_SECRET : XXX #random 64+ alphanumeric string
    ```shell
    openssl rand -hex 64
    ```

2. SECRET_AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET : XXX #random 64+ alphanumeric string
    ```shell
    openssl rand -hex 64
    ```

3. SECRET_AUTHELIA_SESSION_SECRET : XXX #random 64+ alphanumeric string
    ```shell
    openssl rand -hex 64
    ```

4. SECRET_AUTHELIA_STORAGE_ENCRYPTION_KEY : XXX #random 64+ alphanumeric string
    ```shell
    openssl rand -hex 64
    ```

5. SECRET_AUTHELIA_STORAGE_ENCRYPTION_KEY : XXX #random 64+ alphanumeric string
    ```shell
    openssl rand -hex 64
    ```

6. SECRET_AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY : XXX #RSA private key
    ```shell
    sudo docker run -u "$(id -u):$(id -g)" -v "$(pwd)":/keys authelia/authelia:latest authelia crypto pair rsa generate --bits 4096 --directory /keys
    ```

7. CLIENT_ID : XXX #random 72+ userid
    ```shell
    k -n security exec authelia-69bc444d56-pcnb7 -- authelia crypto rand --length 72 --charset rfc3986
    ```

8. CLIENT_SECRET : XXX #random 72+ pass
    ```shell
    k -n security exec authelia-69bc444d56-pcnb7 -- authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986
    ```
