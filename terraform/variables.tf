variable "cluster_name" {
  description = "Name of the local kind cluster"
  type        = string
  default     = "devops-platform"
}

variable "node_image" {
  description = "kind node image (Kubernetes version)"
  type        = string
  default     = "kindest/node:v1.30.4"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.5.2"
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.11.2"
}
