provider "digitalocean" {}

provider "cloudflare" {}

provider "consul" {
  address    = "consul.kitt.run:443"
  scheme     = "https"
  datacenter = "dc1"
}

terraform {
  backend "consul" {
    address = "consul.kitt.run"
    scheme  = "https"
    path    = "defn/home/terraform-remote-state"
  }
}

locals {
  workspace       = jsondecode(data.consul_keys.workspace.var.workspace)
  name            = local.workspace.name
  domain_name     = local.workspace.domain_name
  cf_account_id   = local.workspace.cf_account_id
  spiral_networks = local.workspace.spiral_networks
  droplet         = local.workspace.droplet
  volume          = local.workspace.volume
  kubernetes      = local.workspace.kubernetes
}

data "consul_keys" "workspace" {
  datacenter = "dc1"

  key {
    path = "defn/home/workspace/${terraform.workspace}"
    name = "workspace"
  }
}

data "digitalocean_vpc" "defn" {
  for_each = local.droplet

  name = "default-${each.key}"
}

data "digitalocean_droplet_snapshot" "defn_home" {
  for_each = local.droplet

  name_regex  = "^defn-home"
  region      = each.key
  most_recent = true
}

resource "digitalocean_project" "defn" {
  name = local.domain_name
}

resource "digitalocean_project_resources" "defn" {
  project = digitalocean_project.defn.id
  resources = concat(
    [
      for e in digitalocean_droplet.defn : e.urn
    ],
    [
      for e in digitalocean_volume.defn : e.urn
    ],
    [
      digitalocean_domain.defn.urn
    ]
  )
}

resource "digitalocean_firewall" "defn" {
  name = local.domain_name

  droplet_ids = [
    for e in digitalocean_droplet.defn : e.id
  ]

  inbound_rule {
    port_range = "22"
    protocol   = "tcp"
    source_addresses = [
      "96.78.173.0/24",
    ]
  }

  inbound_rule {
    port_range = "9993"
    protocol   = "udp"
    source_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
  }

  inbound_rule {
    source_addresses = [
      for e in digitalocean_droplet.defn : e.ipv4_address
    ]
    protocol = "icmp"
  }

  inbound_rule {
    source_addresses = [
      for e in digitalocean_droplet.defn : e.ipv4_address
    ]
    port_range = "all"
    protocol   = "tcp"
  }

  inbound_rule {
    source_addresses = [
      for e in digitalocean_droplet.defn : e.ipv4_address
    ]
    port_range = "all"
    protocol   = "udp"
  }

  outbound_rule {
    destination_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
    protocol = "icmp"
  }

  outbound_rule {
    destination_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
    port_range = "all"
    protocol   = "tcp"
  }

  outbound_rule {
    destination_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
    port_range = "all"
    protocol   = "udp"
  }
}

resource "digitalocean_volume" "defn" {
  for_each = local.volume

  region                  = each.key
  name                    = "${local.name}-${each.key}-01"
  size                    = each.value.volume_size
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "defn" {
  for_each = local.droplet

  droplet_id = digitalocean_droplet.defn[each.key].id
  volume_id  = digitalocean_volume.defn[each.key].id
}

resource "digitalocean_droplet" "defn" {
  for_each = local.droplet

  image  = data.digitalocean_droplet_snapshot.defn_home[each.key].id
  name   = "${each.key}.${local.domain_name}"
  region = each.key
  size   = each.value.droplet_size
  ipv6   = true

  lifecycle {
    ignore_changes = [image]
  }
}

resource "digitalocean_kubernetes_cluster" "defn" {
  for_each = local.kubernetes

  name    = replace("${each.key}.${local.domain_name}", ".", "-")
  region  = each.key
  version = each.value.cluster_version

  node_pool {
    name       = "default"
    size       = each.value.droplet_size
    node_count = each.value.droplet_count
  }
}

data "cloudflare_zones" "defn" {
  filter {
    name   = local.domain_name
    status = "active"
  }
}

resource "digitalocean_domain" "defn" {
  name = local.domain_name
}

resource "cloudflare_record" "defn" {
  for_each = local.droplet

  zone_id = data.cloudflare_zones.defn.zones[0].id
  name    = "${each.key}.${data.cloudflare_zones.defn.zones[0].name}"
  value   = digitalocean_droplet.defn[each.key].ipv4_address
  type    = "A"
  ttl     = 60
}

resource "digitalocean_record" "defn" {
  for_each = local.droplet

  domain = digitalocean_domain.defn.name
  type   = "A"
  name   = each.key
  value  = digitalocean_droplet.defn[each.key].ipv4_address
}

resource "cloudflare_access_group" "admins" {
  account_id = local.cf_account_id
  name       = "Admins (${local.domain_name})"

  include {
    email_domain = ["defn.sh"]

    github {
      name = "defn"
    }
  }
}

resource "cloudflare_access_group" "spiral" {
  account_id = local.cf_account_id
  name       = "Spiral (${local.domain_name})"

  include {
    ip = local.spiral_networks
  }
}

resource "cloudflare_access_application" "default_wildcard" {
  name             = "Default (Wildcard)"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "*.${local.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_application" "default_apex" {
  name             = "Default (Apex)"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = local.domain_name
  session_duration = "24h"
}

resource "cloudflare_access_application" "consul" {
  name             = "Consul"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "consul.${local.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_application" "vault" {
  name             = "Vault"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "vault.${local.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_application" "press" {
  name             = "Press"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "press.${local.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_application" "press_admin" {
  name             = "Press"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "press.${local.domain_name}/wp-admin"
  session_duration = "24h"
}

resource "cloudflare_access_application" "press_login" {
  name             = "Press"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "press.${local.domain_name}/wp-login.php"
  session_duration = "24h"
}

resource "cloudflare_access_application" "drone" {
  name             = "Drone"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "drone.${local.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_application" "drone_webhook" {
  name             = "Drone Webhook"
  zone_id          = data.cloudflare_zones.defn.zones[0].id
  domain           = "drone.${local.domain_name}/hook"
  session_duration = "24h"
}

resource "cloudflare_access_policy" "default_wildcard_allow" {
  application_id = cloudflare_access_application.default_wildcard.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Allow"
  precedence     = "1"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.spiral.id]
  }
}

resource "cloudflare_access_policy" "default_wildcard_deny" {
  application_id = cloudflare_access_application.default_wildcard.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "2"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "default_apex_deny" {
  application_id = cloudflare_access_application.default_apex.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "1"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "consul_bypass" {
  application_id = cloudflare_access_application.consul.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Bypass"
  precedence     = "1"
  decision       = "bypass"

  include {
    group = [cloudflare_access_group.spiral.id]
  }
}

resource "cloudflare_access_policy" "consul_deny" {
  application_id = cloudflare_access_application.consul.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "3"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "vault_bypass" {
  application_id = cloudflare_access_application.vault.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Bypass"
  precedence     = "1"
  decision       = "bypass"

  include {
    group = [cloudflare_access_group.spiral.id]
  }
}

resource "cloudflare_access_policy" "vault_deny" {
  application_id = cloudflare_access_application.vault.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "3"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "press_bypass" {
  application_id = cloudflare_access_application.press.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Bypass"
  precedence     = "1"
  decision       = "bypass"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "press_admin_bypass" {
  application_id = cloudflare_access_application.press_admin.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Bypass"
  precedence     = "1"
  decision       = "bypass"

  include {
    group = [cloudflare_access_group.spiral.id]
  }
}

resource "cloudflare_access_policy" "press_admin_deny" {
  application_id = cloudflare_access_application.press_admin.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "2"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "press_login_bypass" {
  application_id = cloudflare_access_application.press_login.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Bypass"
  precedence     = "1"
  decision       = "bypass"

  include {
    group = [cloudflare_access_group.spiral.id]
  }
}

resource "cloudflare_access_policy" "press_login_deny" {
  application_id = cloudflare_access_application.press_login.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "2"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "drone_allow" {
  application_id = cloudflare_access_application.drone.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Allow"
  precedence     = "1"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.admins.id]
  }
}

resource "cloudflare_access_policy" "drone_deny" {
  application_id = cloudflare_access_application.drone.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Deny"
  precedence     = "2"
  decision       = "deny"

  include {
    everyone = true
  }
}

resource "cloudflare_access_policy" "drone_webhook_bypass" {
  application_id = cloudflare_access_application.drone_webhook.id
  zone_id        = data.cloudflare_zones.defn.zones[0].id
  name           = "Bypass"
  precedence     = "1"
  decision       = "bypass"

  include {
    everyone = true
  }
}
