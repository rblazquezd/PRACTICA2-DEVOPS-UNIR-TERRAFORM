output "webbalancer_publicip" {
  description = "Web Load Balancer Public Address"
  value = azurerm_public_ip.pip.ip_address
}

output "webbalancer_id" {
  description = "Web Load Balancer ID."
  value = azurerm_lb.lb.id 
}

output "webbalancer_frontendipconfiguration" {
  description = "Web LB frontend_ip_configuration Block"
  value = [azurerm_lb.lb.frontend_ip_configuration]
}

output "vm1_privateip" {
  value = azurerm_network_interface.vm1nic.private_ip_address
}

output "vm2_privateip" {
  value = azurerm_network_interface.vm2nic.private_ip_address
}

output "vm2_publicip" {
  value = azurerm_public_ip.vm2pip.ip_address
}

output "containerregistry_id" {
  description = "The Container Registry ID"
  value       = azurerm_container_registry.acr.id
}

output "containerregistry_loginserver" {
  description = "The URL that can be used to log into the container registry."
  value       = azurerm_container_registry.acr.login_server
}

output "containerregistry_adminpassword" {
  value = azurerm_container_registry.acr.admin_password
  description = "The object ID of the user"
  sensitive = true
}

output "aks_clientcertificate" {
  value     = azurerm_kubernetes_cluster.clusterkube.kube_config.0.client_certificate
  sensitive = true
}

output "aks_kubeconfig" {
  value = azurerm_kubernetes_cluster.clusterkube.kube_config_raw
  sensitive = true
}

