provider "digitalocean" {
}

locals {
  work = {
    default : {
      sfo2 : {
        droplet_size : "s-1vcpu-2gb",
        volume_size : "10"
      },
      sfo3 : {
        droplet_size : "s-1vcpu-2gb",
        volume_size : "10"
      },
      nyc1 : {
        droplet_size : "s-1vcpu-1gb",
        volume_size : "10"
      },
      nyc3 : {
        droplet_size : "s-1vcpu-1gb",
        volume_size : "10"
      },
      lon1 : {
        droplet_size : "s-1vcpu-1gb",
        volume_size : "10"
      },
      tor1 : {
        droplet_size : "s-1vcpu-1gb",
        volume_size : "10"
      }
    }
  }
}

data "digitalocean_vpc" "defn" {
  for_each = local.work[terraform.workspace]

  name = "default-${each.key}"
}

data "digitalocean_droplet_snapshot" "defn_home" {
  for_each = local.work[terraform.workspace]

  name_regex  = "^defn-home"
  region      = each.key
  most_recent = true
}

resource "digitalocean_project" "defn" {
  name = "defn"
}

resource "digitalocean_project_resources" "defn" {
  project = digitalocean_project.defn.id
  resources = [
    for e in digitalocean_droplet.defn : e.urn
  ]
}

resource "digitalocean_firewall" "defn" {
  name = "default"

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
  for_each = local.work[terraform.workspace]

  region                  = each.key
  name                    = "volume-${each.key}-01"
  size                    = each.value.volume_size
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "defn" {
  for_each = local.work[terraform.workspace]

  droplet_id = digitalocean_droplet.defn[each.key].id
  volume_id  = digitalocean_volume.defn[each.key].id
}

resource "digitalocean_droplet" "defn" {
  for_each = local.work[terraform.workspace]

  image  = data.digitalocean_droplet_snapshot.defn_home[each.key].id
  name   = "defn-${each.key}"
  region = each.key
  size   = each.value.droplet_size
  ipv6   = true

  lifecycle {
    ignore_changes = [image]
  }
}
