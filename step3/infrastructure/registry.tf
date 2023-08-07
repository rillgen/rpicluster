resource "kubernetes_namespace" "registry_ns" {
  metadata {
    name = "registry"
    labels = {
      app = "registry"
    }

  }
}

resource "kubernetes_storage_class" "registry_nfs" {
  metadata {
    name = "nfs-registry"
  }
  storage_provisioner    = "local"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "Immediate"
}

resource "kubernetes_config_map" "registry_cfg_map" {
  metadata {
    name      = "registry-config"
    namespace = kubernetes_namespace.registry_ns.metadata.0.name
  }
  data = {
    "config.yml" = file("static/registry-config.yml")
  }
}

resource "kubernetes_persistent_volume" "registry_shared_nfs" {
  metadata {
    name = "registry-pv"
    labels = {
      name  = "type"
      value = "local"
    }
  }
  spec {
    capacity = {
      storage = "30Gi"
    }
    storage_class_name = kubernetes_storage_class.registry_nfs.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    persistent_volume_source {
      host_path {
        path = "${var.nfs_storage.general}/registry"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "registry_shared_nfs_claim" {
  metadata {
    name      = "registry-pvc"
    namespace = kubernetes_namespace.registry_ns.metadata.0.name
  }
  spec {
    storage_class_name = kubernetes_storage_class.registry_nfs.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "30Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.registry_shared_nfs.metadata.0.name
  }
}


resource "kubernetes_deployment" "registry" {
  depends_on = [kubernetes_persistent_volume_claim.registry_shared_nfs_claim]

  metadata {
    name = "registry"
    labels = {
      app = "registry"
    }
    namespace = kubernetes_namespace.registry_ns.metadata.0.name
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "registry"
      }
    }
    template {
      metadata {
        labels = {
          app = "registry"
        }
      }

      spec {
        volume {
          name = "registry-v-nfs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.registry_shared_nfs_claim.metadata.0.name
          }
        }

        volume {
          name = "registry-config"
          config_map {
            name = kubernetes_config_map.registry_cfg_map.metadata.0.name
          }
        }        
        container {
          name  = "registry"
          image = var.images.registry
          
          volume_mount {
            mount_path = "/etc/docker/registry/config.yml"
            sub_path   = "config.yml"
            name       = "registry-config"
          }
          volume_mount {
            mount_path = "/var/registry/data"
            name       = "registry-v-nfs"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry_svc" {
  #   depends_on = [kubernetes_config_map.metallb_cfg_map]
  metadata {
    namespace = kubernetes_namespace.registry_ns.metadata.0.name
    name      = "registry-fwd"
  }
  spec {
    port {
      name        = "registry-http"
      port        = 5050
      target_port = 5050
    }
    port {
      name        = "registry-debug"
      port        = 5051
      target_port = 5051
    }
    # load_balancer_ip = "${var.network_subnet}.${var.net_hosts.registry_catchall}"
    selector = {
      "app" : "registry"
    }
    session_affinity = "ClientIP"
    type             = "LoadBalancer"
  }
}

resource "kubernetes_ingress_v1" "registry_ingress" {
  metadata {
    name = "traefik-registry"
    annotations = {
      "kubernetes.io/ingress.class" : "traefik"
    }
    namespace = kubernetes_namespace.registry_ns.metadata.0.name
  }

  spec {
    rule {
      host = "registry.local"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.registry_svc.metadata.0.name
              port {
                name = "registry-http"
              }
            }
          }
        }
      }
    }
  }
}
