locals {
    config = yamldecode(file("${path.module}/config/environment/${terraform.workspace}/config.yaml"))
}