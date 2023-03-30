source digitalocean mynginx {
    api_token = var.do_token
    image = var.do_image
    region = var.do_region
    size = var.do_size
    ssh_username = "root"
    snapshot_name = "mynginx"
}

build {
    sources = [
        "source.digitalocean.mynginx"
    ]

    provisioner ansible {
        playbook_file = "playbook.yaml"
        ansible_ssh_extra_args = [
            "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"
        ]
    }
}
