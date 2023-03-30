terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    digitalocean = {
            source = "digitalocean/digitalocean"
            version = "2.26.0"
        }
        local = {
            source = "hashicorp/local"
            version = "2.4.0"
        }
  }
}

provider "docker" {
  host = "tcp:/138.68.74.87/:2376"
  cert_path = var.docker_cert_path
}

provider digitalocean {
    token = var.do_token

}

provider local { }

resource "docker_network" "bgg-net" {
  name = "bgg-net"
}

#volume
resource "docker_volume" "data-vol" {
    name = "bgg_volume"
}



# pull the image
# docker pull <image>
resource "docker_image" "bgg-database" {
    name = var.image_name_db
}

resource "docker_image" "bgg-backend" {
    name = var.image_name_app
}

# run the container
# docker run -d -p 3000:3000 
resource "docker_container" "bgg-database" {
    #count = var.app_instance_count
    name = "bgg-database"
    image = docker_image.bgg-database.image_id
    
    networks_advanced    {
        name=docker_network.bgg-net.id
    }
    
    volumes {
      volume_name = docker_volume.data-vol.name
      container_path = "/var/lib/mysql"
    }

    ports {
        internal = 3306
        external = 3306 
    }
    
}

resource "docker_container" "bgg-backend" {

    count = var.app_instance_count

    name = "bgg-backend-${count.index}"
    image = docker_image.bgg-backend.image_id

    networks_advanced {
      name = docker_network.bgg-net.id
    }

    env = [
        "BGG_DB_USER=root",
        "BGG_DB_PASSWORD=changeit",
        "BGG_DB_HOST=${docker_container.bgg-database.name}",
    ]

    ports {
        internal = 3000
    }
}



variable do_token {
    type = string
    sensitive = true
}

variable image_name_db {
    type = string 
    default = "chukmunnlee/bgg-database:v3.1"
}

variable image_name_app {
    type = string 
    default = "chukmunnlee/bgg-backend:v3"
}


variable docker_cert_path {
    type = string
    sensitive = true
}

variable app_namespace {
    type = string 
    default = "my"
}

variable database_version {
    type = string
    default = "v3.1"
}

variable backend_version {
    type = string
    default = "v3"
}

variable app_instance_count{
    type = number
    default = 3
}

variable do_region {
    type = string
    default = "sgp1"
}
resource "docker_network" "bgg_net" {
  name = "bgg_net"
}

resource "docker_volume" "shared_volume" {
  name = "shared_volume"
}


resource "docker_image" "bgg_database" {
  name = "chukmunnlee/bgg-database:v3.1"
}

resource "docker_image" "bgg_backend" {
  name = "chukmunnlee/bgg-backend:v3"
}


resource "docker_container" "bgg_database" {
  name = "bgg_database"
  # image = "chukmunnlee/bgg-database:v3.1"
  image = docker_image.bgg_database.name

  volumes {

    volume_name = "shared_volume"

    container_path = "/var/lib/mysql"
  }

  ports {
    internal = 3306
    external = 3306
  }

  networks_advanced {
    name = docker_network.bgg_net.id
  }
}

resource "docker_container" "bgg_backend" {

  count = var.backend_instance_count

  name = "bgg_backend_${count.index}"
  # image = "chukmunnlee/bgg-backend:v3"
  image = docker_image.bgg_backend.name

  env = [
    "BGG_DB_USER=root",
    "BGG_DB_PASSWORD=changeit",
    "BGG_DB_HOST=${docker_container.bgg_database.name}",
  ]

  networks_advanced {
    name = docker_network.bgg_net.id
  }

  ports {
    internal = 3000
  }

}


resource "local_file" "nginx_conf" {
  filename = "nginx.conf"
  content = templatefile("sample.nginx.conf.tftpl", {
    docker_host = var.docker_host,
    ports       = docker_container.bgg_backend[*].ports[0].external
  })
}

# Create a new SSH key
resource "digitalocean_ssh_key" "webserver_key" {
  name       = "webserver_key"
  public_key = file("/home/fred/.ssh/webserver_key.pub")
}

resource "digitalocean_droplet" "web_server" {
  name     = "webserver"
  image    = var.do_image
  size     = var.do_size
  region   = var.do_region
  tags     = ["webserver", "reverse_proxy"]
  ssh_keys = [digitalocean_ssh_key.webserver_key.id]

  # install by user_data
  # user_data = file("nginx_deployment.yaml")

  # install by sshing

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/webserver_key")
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "/usr/bin/apt update -y",
      "/usr/bin/apt upgrade -y",
      "/usr/bin/apt install nginx -y"

    ]
  }

  provisioner "file" {
    source      = local_file.nginx_conf.filename
    destination = "/etc/nginx/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "/usr/bin/systemctl restart nginx",
      "/usr/bin/systemctl enable nginx"
    ]
  }

}



output "webserver_public_ip" {
  value = digitalocean_droplet.web_server.ipv4_address
}

output "backend_ports" {
  value = docker_container.bgg_backend[*].ports[0].external
}


