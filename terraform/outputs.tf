output "kubeconfig_path" {
  description = "Path to the kubeconfig for the kind cluster"
  value       = kind_cluster.this.kubeconfig_path
}

output "argocd_port_forward" {
  description = "Command to reach the Argo CD UI"
  value       = "kubectl -n argocd port-forward svc/argocd-server 8082:443  # then open https://localhost:8082"
}

output "argocd_admin_password_cmd" {
  description = "Command to read the initial Argo CD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
