resource "keycloak_realm" "realm" {
  realm                    = "boundary"
  enabled                  = true
  reset_password_allowed   = true
  remember_me              = true
  verify_email             = true
  login_with_email_allowed = true
  access_token_lifespan    = "12h"
}

resource "keycloak_realm_events" "events" {
  realm_id                     = keycloak_realm.realm.id
  admin_events_enabled         = true
  admin_events_details_enabled = true
  events_enabled               = true
  events_listeners             = ["jboss-logging"]
}

# SAML client — matches your OpenSearch SP entity_id: "opennsearch"
resource "keycloak_saml_client" "app" {
  realm_id                  = keycloak_realm.realm.id
  client_id                 = "http://opensearch-dashboards:5601"
  name                      = "opensearch-dashboards"
  client_signature_required = false
  sign_assertions           = true
  sign_documents            = true
  name_id_format            = "email"
  include_authn_statement   = true
  force_post_binding        = true
  force_name_id_format      = true
  front_channel_logout      = true
  signature_algorithm       = "RSA_SHA256"
  signature_key_name        = "NONE"
  extra_config = {
    "display.on.consent.screen"         = false
    "saml.artifact.binding"             = false
    "saml.onetimeuse.condition"         = false
    "saml.server.signature.keyinfo.ext" = false
  }
  valid_redirect_uris = [
    "http://opensearch-dashboards:5601/_plugins/_security/saml/acs/",
    "http://opensearch-dashboards:5601/_opendistro/_security/saml/acs",
    "http://opensearch-dashboards:5601/*",
    "https://opensearch-dashboards:5601/*",
    "http://127.0.0.1:8000/api/saml/callback",
  ]
}
resource "keycloak_saml_client_default_scopes" "this" {
  realm_id       = keycloak_realm.realm.id
  client_id      = keycloak_saml_client.app.id
  default_scopes = []
}
# Group membership -> 'groups' attribute (aligns with roles_key: groups)
resource "keycloak_generic_protocol_mapper" "groups" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_saml_client.app.id
  name            = "groups"
  protocol        = "saml"
  protocol_mapper = "saml-group-membership-mapper"
  config = {
    "attribute.name"       = "groups"
    "attribute.nameformat" = "Basic"
    "friendly.name"        = "groups"
    "full.path"            = "false"
    "single"               = "true"
  }
}

resource "keycloak_saml_user_property_protocol_mapper" "email" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.app.id
  name                       = "email"
  friendly_name              = "email"
  user_property              = "email"
  saml_attribute_name        = "email"
  saml_attribute_name_format = "Basic"
}


resource "keycloak_user" "user" {
  realm_id = keycloak_realm.realm.id
  username = "user"
  email_verified = true
  initial_password {
    value     = "user"
    temporary = false
  }
  enabled    = true
  email      = "user@domain.com"
  first_name = "name"
  last_name  = "lname"
}

resource "keycloak_group" "group" {
  realm_id = keycloak_realm.realm.id
  name     = "opens"
}


resource "keycloak_group_memberships" "group_members" {
  realm_id = keycloak_realm.realm.id
  group_id = keycloak_group.group.id

  members = [
    keycloak_user.user.username
  ]
}


data "keycloak_realm_keys" "this" {
  realm_id   = keycloak_realm.realm.id
  algorithms = ["RS256"]
}

output "cert" {
  value = data.keycloak_realm_keys.this.keys[0].certificate
}
