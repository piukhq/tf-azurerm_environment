terraform {
    required_providers {
        kubectl = {
            source  = "gavinbunney/kubectl"
            version = ">= 1.7.0"
        }
    }
}

variable "flux_config" {
    type = object({
        kube_admin_config = object({
            host = string
            client_key = string
            client_certificate = string
            cluster_ca_certificate = string
        })
        variables = object({
            cluster_name = string
            location = string
            loadbalancer_ip = string
            prometheus_ip = string
        })
    })
}

provider "kubectl" {
    host = var.flux_config.kube_admin_config.host
    client_key = base64decode(var.flux_config.kube_admin_config.client_key)
    client_certificate = base64decode(var.flux_config.kube_admin_config.client_certificate)
    cluster_ca_certificate = base64decode(var.flux_config.kube_admin_config.cluster_ca_certificate)
}

locals {
    flux_dir = "${var.flux_config.variables.location}-${trim(var.flux_config.variables.cluster_name, "0123456789")}"
}

resource "kubectl_manifest" "namespace" {
    yaml_body = file("${path.module}/manifests/namespace.yaml")
}

resource "kubectl_manifest" "cluster_vars" {
    depends_on = [ kubectl_manifest.namespace ]
    yaml_body = templatefile("${path.module}/manifests/cluster_vars.yaml", {
        location = var.flux_config.variables.location
        cluster_name = var.flux_config.variables.cluster_name
        loadbalancer_ip = var.flux_config.variables.loadbalancer_ip
        prometheus_ip = var.flux_config.variables.prometheus_ip
        kube_api_host = var.flux_config.kube_admin_config.host
    })
}

data "kubectl_file_documents" "deploy" {
    content = file("${path.module}/manifests/deploy.yaml")
}

resource "kubectl_manifest" "deploy" {
    depends_on = [ kubectl_manifest.namespace ]
    for_each = data.kubectl_file_documents.deploy.manifests
    yaml_body = each.value
    wait_for_rollout = false
    lifecycle {
        ignore_changes = all
    }
}

data "kubectl_file_documents" "sync" {
    content = templatefile("${path.module}/manifests/sync.yaml", {
        flux_dir = local.flux_dir
    })
}

resource "kubectl_manifest" "sync" {
    depends_on = [ kubectl_manifest.deploy ]
    for_each = data.kubectl_file_documents.sync.manifests
    yaml_body = each.value
    wait_for_rollout = false
    lifecycle {
        ignore_changes = all
    }
}
