provider "digitalocean" {
}

data "digitalocean_droplet_snapshot" "defn_home" {
  name_regex  = "^defn-home"
  region      = "nyc1"
  most_recent = true
}

resource "digitalocean_droplet" "defn_nyc_1" {
  image  = data.digitalocean_droplet_snapshot.defn_home.id
  name   = "defn-nyc1"
  region = "nyc1"
  size   = "s-1vcpu-2gb"
  ipv6   = true
}
