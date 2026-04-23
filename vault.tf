resource "hcp_hvn" "learn_hcp_vault_hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "hcp_vault_cluster" "learn_hcp_vault" {
  hvn_id     = hcp_hvn.learn_hcp_vault_hvn.hvn_id
  cluster_id = var.cluster_id
  tier       = var.tier
  # public_endpoint = true
}

data "tfe_outputs" "ec2" {
  organization = "Nicole-Repo"
  workspace    = "terraform-vault-ansible-deployment"
}

# ── PKI secrets engine ────────────────────────────────────────────────────────

resource "vault_mount" "pki" {
  path                  = "pki"
  type                  = "pki"
  max_lease_ttl_seconds = 315360000
}

resource "vault_pki_secret_backend_root_cert" "root" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "App Demo Root CA"
  ttl         = "87600h"
}

resource "vault_pki_secret_backend_config_urls" "pki" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["${var.vault_addr}/v1/${vault_mount.pki.path}/ca"]
  crl_distribution_points = ["${var.vault_addr}/v1/${vault_mount.pki.path}/crl"]
}

resource "vault_pki_secret_backend_role" "app_server" {
  backend            = vault_mount.pki.path
  name               = "app-server"
  allowed_domains    = [data.tfe_outputs.ec2.values.vault_public_ip] # TODO: replace instance_hostname with the actual output name from the ec2 workspace
  allow_bare_domains = true
  allow_subdomains   = true
  max_ttl            = "720h"
  generate_lease     = true
  key_usage          = ["DigitalSignature", "KeyEncipherment"]
  ext_key_usage      = ["ServerAuth"]
}

# ── AppRole auth ──────────────────────────────────────────────────────────────

resource "vault_auth_backend" "approle" {
  type = "approle"
}

# ── Policy scoped to cert issuance only ──────────────────────────────────────

resource "vault_policy" "cert_rotation" {
  name   = "cert-rotation"
  policy = <<-EOT
    path "${vault_mount.pki.path}/issue/${vault_pki_secret_backend_role.app_server.name}" {
      capabilities = ["create", "update"]
    }
  EOT
}

# ── AppRole role + secret ID ──────────────────────────────────────────────────

resource "vault_approle_auth_backend_role" "app_server" {
  backend        = vault_auth_backend.approle.path
  role_name      = "app-server"
  token_policies = [vault_policy.cert_rotation.name]
  token_ttl      = 3600
  token_max_ttl  = 14400
}

resource "vault_approle_auth_backend_role_secret_id" "app_server" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.app_server.role_name
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "approle_role_id" {
  value = vault_approle_auth_backend_role.app_server.role_id
}

output "approle_secret_id" {
  value     = vault_approle_auth_backend_role_secret_id.app_server.secret_id
  sensitive = true
}
