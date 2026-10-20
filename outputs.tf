output "resource_group_name" {
  description = "Nombre del Grupo de Recursos creado"
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Nombre de la Maquina Virtual creada"
  value       = azurerm_linux_virtual_machine.backend_vm.name
}

output "public_ip_address" {
  description = "Direccion IP publica de la VM (estatica)"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_fqdn" {
  description = "Nombre DNS completo de la VM"
  value       = azurerm_public_ip.pip.fqdn
}

output "backend_http_url" {
  description = "URL HTTP del backend NestJS en la VM"
  value       = "http://${azurerm_public_ip.pip.fqdn}:3000"
}

output "backend_api_http_url" {
  description = "URL HTTP del endpoint base de la API"
  value       = "http://${azurerm_public_ip.pip.fqdn}:3000/api/v1"
}

output "swagger_docs_http_url" {
  description = "URL HTTP de la documentacion Swagger"
  value       = "http://${azurerm_public_ip.pip.fqdn}:3000/api/v1/docs"
}

output "ssh_connection_command" {
  description = "Comando para conectarse a la VM via SSH"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "upload_command" {
  description = "Comando sugerido para subir el codigo del backend a la VM (excluye node_modules y .env para transferir en 2 segundos sin sobreescribir la config del servidor)"
  value       = "tar --exclude='node_modules' --exclude='.git' --exclude='dist' --exclude='.env*' -czf backend.tar.gz -C ../../../../../asistencia-backend . && scp backend.tar.gz ${var.admin_username}@${azurerm_public_ip.pip.ip_address}:/tmp/ && ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address} 'tar -xzf /tmp/backend.tar.gz -C /opt/asistencia-backend && rm /tmp/backend.tar.gz && ~/deploy.sh' && rm backend.tar.gz"
}

output "deploy_command" {
  description = "Comando para ejecutar la compilacion y despliegue dentro de la VM via SSH"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address} '~/deploy.sh'"
}
