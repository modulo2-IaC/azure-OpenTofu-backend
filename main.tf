locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    },
    var.extra_tags
  )

  name_prefix = "${var.project_name}-${var.environment}"
  rg_name     = "rg-vm-${local.name_prefix}-${random_string.suffix.result}"
  vm_name     = "vm-${local.name_prefix}-${random_string.suffix.result}"
  dns_label   = "vm-${local.name_prefix}-${random_string.suffix.result}"
}

# 1. Sufijo aleatorio para unicidad de nombres en Azure
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# 2. JWT secret autogenerado (solo se usa si no se pasa uno en variables)
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

# 3. Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# RED: VNet + Subnet + IP publica + NSG + NIC
# Azure necesita estos 5 recursos de red antes de crear cualquier VM
# ---------------------------------------------------------------------------

# 4. Red Virtual (VNet) - espacio de red privado de la VM
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

# 5. Subred dentro de la VNet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-backend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 6. IP publica estatica (para acceder a la VM desde internet)
# Standard SKU: cuota disponible en Azure Free Trial
# (Basic SKU tiene limite = 0 en cuentas Free Trial, por eso usamos Standard)
resource "azurerm_public_ip" "pip" {
  name                = "pip-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_label
  tags                = local.common_tags
}

# 7. Network Security Group (firewall de la VM)
#    Solo abre puerto 22 (SSH) y 3000 (backend HTTP)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # Permite SSH para administracion remota
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite el puerto 3000 donde corre el backend NestJS
  security_rule {
    name                       = "Allow-Backend-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 8. Tarjeta de red virtual (NIC) - conecta la VM a la red y la IP publica
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 9. Asociar el NSG (firewall) a la NIC de la VM
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ---------------------------------------------------------------------------
# MAQUINA VIRTUAL LINUX
# Standard_B2ats_v2: 2 vCPU, 1 GB RAM -> B-series v2 (reemplazo oficial de B1s)
# Microsoft retiró Standard_B1s en 2024; B2ats_v2 es la alternativa recomendada
# para Azure Free Trial y tiene capacidad disponible en las regiones actuales.
# Ubuntu 22.04 LTS (imagen oficial, sin costo adicional)
# ---------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = local.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Autenticacion por contrasena (mas simple; SSH key es alternativa)
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # Conectar la VM a la tarjeta de red creada arriba
  network_interface_ids = [azurerm_network_interface.nic.id]

  # Disco del sistema operativo (Standard HDD: mas economico para Free tier)
  os_disk {
    name                 = "osdisk-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # Imagen de Ubuntu 22.04 LTS de Canonical (sin costo en Azure)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # ---------------------------------------------------------------------------
  # CLOUD-INIT: script que se ejecuta UNA SOLA VEZ al arrancar la VM por primera vez
  # Este script instala Node.js, clona el codigo, configura el servicio y lo inicia
  # ---------------------------------------------------------------------------
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username = var.admin_username
    node_version   = var.node_version
    database_url   = var.database_url
    jwt_secret     = coalesce(var.jwt_secret, random_password.jwt_secret.result)
    cors_origin    = var.cors_origin
    app_timezone   = var.app_timezone
    run_migrations = var.run_migrations ? "true" : "false"
    repo_url       = var.repo_url
  }))
}
