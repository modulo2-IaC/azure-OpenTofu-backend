# ===========================================================================
# 11. INFRAESTRUCTURA Y MONITOREO (Azure Monitor - IaC.md)
# Observabilidad, confiabilidad operativa y alertas automatizadas
# ===========================================================================

# 1. Log Analytics Workspace (almacén central de telemetría y logs)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# 2. Grupo de Acción de Alertas (Action Group para notificación a DevOps/SRE)
resource "azurerm_monitor_action_group" "sre_alerts" {
  name                = "ag-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "ag-alerts"
  tags                = local.common_tags

  email_receiver {
    name                    = "admin-email"
    email_address           = "devops-admin@example.com"
    use_common_alert_schema = true
  }
}

# 3. Métrica de alerta para la Máquina Virtual (Confiabilidad)
#    Dispara alerta si el uso promedio de CPU supera 80% en ventana de 5 minutos
resource "azurerm_monitor_metric_alert" "vm_cpu_alert" {
  name                = "alert-vm-cpu-high-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.backend_vm.id]
  description         = "Alerta disparada cuando el uso de CPU de la VM supera el 80% durante 5 minutos consecutivos"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_alerts.id
  }
}
