provider "digitalocean" {
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
