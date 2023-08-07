resource "kubernetes_namespace" "nginx_ns" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }

  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
    namespace = kubernetes_namespace.nginx_ns.metadata.0.name
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = var.images.nginx
          port {
            container_port = 80
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_svc" {
  #   depends_on = [kubernetes_config_map.metallb_cfg_map]
  metadata {
    namespace = kubernetes_namespace.nginx_ns.metadata.0.name
    name      = "nginx-fwd"
  }
  spec {
    port {
      name        = "nginx-http"
      port        = 8081
      target_port = 80
    }
    # load_balancer_ip = "${var.network_subnet}.${var.net_hosts.adguard_catchall}"
    selector = {
      "app" : "nginx"
    }
    session_affinity = "ClientIP"
    type             = "LoadBalancer"
  }
}

resource "kubernetes_ingress_v1" "nginx_ingress" {
  metadata {
    name = "traefik-nginx"
    annotations = {
      "kubernetes.io/ingress.class" : "traefik"
    }
    namespace = kubernetes_namespace.nginx_ns.metadata.0.name
  }

  spec {
    rule {
      host = "nginx.local"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.nginx_svc.metadata.0.name
              port {
                name = "nginx-http"
              }
            }
          }
        }
      }
    }
  }
}
