data "digitalocean_ssh_key" "codeServerKey" {
  name = "codeServerKey"

}


data "digitalocean_image" "mynginx" {
  name = "mynginx"
}

resource "digitalocean_droplet" "mynginx" {
  name   = "mynginx"
  image  = data.digitalocean_image.mynginx.id
  size   = var.do_size
  region = var.do_region

  ssh_keys = [data.digitalocean_ssh_key.codeServerKey.id]
}


output "mynginx_ip" {
  value = digitalocean_droplet.mynginx.ipv4_address
}

