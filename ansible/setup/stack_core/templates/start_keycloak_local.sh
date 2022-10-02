docker run --rm \
-e  KEYCLOAK_ADMIN="admin" \
-e  KEYCLOAK_ADMIN_PASSWORD="admin" \
-e  KC_HOSTNAME="test.keycloak.local" \
-e  KC_PROXY_ADDRESS_FORWARDING="true" \
-e  KC_HOSTNAME_STRICT="false" \
-e  KC_HOSTNAME_STRICT_HTTPS="false" \
-e  KC_HTTP_ENABLED="true" \
-p 8085:8080 \
--name keycloak test/keycloak start --optimized