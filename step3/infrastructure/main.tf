provider "kubernetes" {
  config_path    = "~/.kube/config-home-k8s"
  config_context = "home-k8s"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config-home-k8s"
    config_context = "home-k8s"
  }
}
