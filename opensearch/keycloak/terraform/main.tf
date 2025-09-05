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
  realm_id = keycloak_realm.realm.id
  admin_events_enabled          = true
  admin_events_details_enabled  = true
  events_enabled                = true
  events_listeners              = ["jboss-logging"]
}

# SAML client — matches your OpenSearch SP entity_id: "opennsearch"
resource "keycloak_saml_client" "app" {
  realm_id                  = keycloak_realm.realm.id
  client_id                 = "opennsearch"
  name                      = "opennsearch"
  client_signature_required = false
  sign_assertions           = false
  sign_documents            = true
  name_id_format            = "email"
  include_authn_statement   = false
  force_post_binding        = true
  force_name_id_format      = true
  signature_algorithm       = "RSA_SHA256"
  signature_key_name        = "NONE"

  valid_redirect_uris = [
    "http://localhost:5601/_plugins/_security/saml/acs/",
    "http://localhost:5601/_opendistro/_security/saml/acs/",
    "http://127.0.0.1:8000/api/saml/callback",
    "https://127.0.0.1:8443/api/saml/callback",
    "http://127.0.0.1:5601/_opendistro/_security/saml/acs",
    "http://localhost:5601/_opendistro/_security/saml/acs",
    "http://127.0.0.1:5601/*",
    "http://localhost:5601/*"
  ]
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
  initial_password {
    value     = "user"
    temporary = true
  }
  enabled  = true
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

  members  = [
    keycloak_user.user.username
  ]
}
