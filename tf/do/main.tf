provider "digitalocean" {
}

data "digitalocean_vpc" "nyc1" {
  name = "default-nyc1"
}

data "digitalocean_vpc" "sfo2" {
  name = "default-sfo2"
}

data "digitalocean_vpc" "sfo3" {
  name = "default-sfo3"
}

data "digitalocean_droplet_snapshot" "defn_home_nyc1" {
  name_regex  = "^defn-home"
  region      = "nyc1"
  most_recent = true
}

data "digitalocean_droplet_snapshot" "defn_home_sfo2" {
  name_regex  = "^defn-home"
  region      = "sfo2"
  most_recent = true
}

data "digitalocean_droplet_snapshot" "defn_home_sfo3" {
  name_regex  = "^defn-home"
  region      = "sfo3"
  most_recent = true
}

resource "digitalocean_project" "defn" {
  name = "defn"
}

resource "digitalocean_project_resources" "defn" {
  project = digitalocean_project.defn.id
  resources = [
    digitalocean_droplet.defn_nyc1.urn,
    digitalocean_droplet.defn_sfo2.urn,
    digitalocean_droplet.defn_sfo3.urn
  ]
}

resource "digitalocean_firewall" "defn" {
  name = "default"

  droplet_ids = [
    digitalocean_droplet.defn_nyc1.id,
    digitalocean_droplet.defn_sfo2.id,
    digitalocean_droplet.defn_sfo3.id
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

resource "digitalocean_volume" "defn_nyc1" {
  region                  = "nyc1"
  name                    = "volume-nyc1-01"
  size                    = 10
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "defn_nyc1" {
  droplet_id = digitalocean_droplet.defn_nyc1.id
  volume_id  = digitalocean_volume.defn_nyc1.id
}

resource "digitalocean_volume" "defn_sfo2" {
  region                  = "sfo2"
  name                    = "volume-sfo2-01"
  size                    = 10
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "defn_sfo2" {
  droplet_id = digitalocean_droplet.defn_sfo2.id
  volume_id  = digitalocean_volume.defn_sfo2.id
}

resource "digitalocean_volume" "defn_sfo3" {
  region                  = "sfo3"
  name                    = "volume-sfo3-01"
  size                    = 10
  initial_filesystem_type = "ext4"
}

resource "digitalocean_volume_attachment" "defn_sfo3" {
  droplet_id = digitalocean_droplet.defn_sfo3.id
  volume_id  = digitalocean_volume.defn_sfo3.id
}

resource "digitalocean_droplet" "defn_nyc1" {
  image  = data.digitalocean_droplet_snapshot.defn_home_nyc1.id
  name   = "defn-nyc1"
  region = "nyc1"
  size   = "s-1vcpu-2gb"
  ipv6   = true
}

resource "digitalocean_droplet" "defn_sfo2" {
  image  = 66179221 # data.digitalocean_droplet_snapshot.defn_home_sfo2.id
  name   = "defn-sfo2"
  region = "sfo2"
  size   = "s-1vcpu-2gb"
  ipv6   = true
}

resource "digitalocean_droplet" "defn_sfo3" {
  image  = 66179221 # data.digitalocean_droplet_snapshot.defn_home_sfo3.id
  name   = "defn-sfo3"
  region = "sfo3"
  size   = "s-1vcpu-2gb"
  ipv6   = true
}
