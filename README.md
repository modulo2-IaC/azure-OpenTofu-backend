# Infraestructura como Código (IaC) - Asistencia Backend en Azure

Este repositorio contiene la definición completa en **OpenTofu** para aprovisionar y gestionar la infraestructura en **Microsoft Azure** del backend de la aplicación de control de asistencia (NestJS + TypeScript), conectada a una base de datos externa **PostgreSQL en Neon**.

---

## 🏛 Arquitectura de Infraestructura

```mermaid
graph TD
    Client[Cliente / Frontend] -->|HTTP :3000| PIP[Azure Public IP Estática]
    PIP --> NSG[Network Security Group<br/>Puertos 22, 3000]
    NSG --> NIC[Network Interface]
    NIC --> VM[Azure Linux VM<br/>Standard_B2as_v2<br/>Ubuntu 22.04 LTS]
    subgraph VM_Internal [Servicios en VM]
        PM2[PM2 Process Manager]
        App[NestJS Backend API]
        PM2 --> App
    end
    VM --> VM_Internal
    App -->|SSL Pooler :5432| Neon[(Neon PostgreSQL)]
    Tofu[OpenTofu CLI / CI-CD] -->|State Lock & Storage| AzureBlob[(Azure Blob Storage<br/>sttofuasistenciadev / tfstate)]
```

### Recursos Provisionados
- **Grupo de Recursos**: `rg-vm-asistencia-dev-<sufijo>` (`swedencentral`).
- **Red Virtual (VNet)**: `10.0.0.0/16` con subred dedicada `subnet-backend` (`10.0.1.0/24`).
- **IP Pública Estática**: SKU Standard con nombre DNS FQDN asignado.
- **Network Security Group (NSG)**: Firewall perimetral permitiendo SSH (puerto 22) y API NestJS (puerto 3000).
- **Máquina Virtual Linux**: `Standard_B2as_v2` (2 vCPU, 2 GB RAM, serie B con ráfagas, 100% elegible para Azure Free Trial).
- **Disco OS**: 30 GB Standard HDD (optimizado para plan gratuito).
- **Cloud-Init Automatizado**:
  - Configuración de 1 GB de Swap para compilación fluida.
  - Instalación de Node.js 20 LTS y PM2.
  - Clonación opcional del repositorio Git (`repo_url`).
  - Creación de `.env` de producción seguro.
  - Script utilitario de actualización y recarga: `~/deploy.sh`.

---

## 🔒 Estado Remoto en Azure Blob Storage

El archivo de estado (`.tfstate`) se almacena de forma remota y segura en Azure con bloqueo de concurrencia:
- **Resource Group**: `rg-asistencia-tfstate`
- **Storage Account**: `sttofuasistenciadev`
- **Container**: `tfstate`
- **Key**: `backend.terraform.tfstate`

---

## 🚀 Despliegue Paso a Paso

### 1. Prerrequisitos
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) instalado y logueado:
  ```bash
  az login
  ```
- [OpenTofu](https://opentofu.org/) v1.6 o superior:
  ```bash
  tofu version
  ```

### 2. Configurar Variables
Copia el archivo de plantilla y completa tus credenciales reales:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars`:
```hcl
project_name    = "asistencia"
environment     = "dev"
location        = "swedencentral"
admin_username  = "azureuser"
admin_password  = "TuPasswordSeguro123!" # Cambiar obligatoriamente
database_url    = "postgresql://neondb_owner:PASSWORD@ep-xxx-pooler.c-7.us-east-2.aws.neon.tech/neondb?sslmode=require"
repo_url        = "https://github.com/Joandrr/asistencia-backend.git"
```

### 3. Comandos de OpenTofu

```bash
# 1. Inicializar con el backend remoto en Azure
tofu init

# 2. Validar sintaxis y configuración
tofu validate

# 3. Previsualizar cambios
tofu plan

# 4. Aprovisionar infraestructura
tofu apply
```

### 4. Salidas Importantes (Outputs)
Al finalizar `tofu apply`, obtendrás:
- **`backend_http_url`**: URL directa del backend (ej: `http://51.12.93.59:3000`).
- **`swagger_docs_http_url`**: Documentación interactiva Swagger (`/api/v1/docs`).
- **`ssh_connection_command`**: Comando directo para conectarte vía SSH.
- **`deploy_command`**: Comando para compilar y reiniciar el backend remotamente (`ssh azureuser@<IP> '~/deploy.sh'`).

---

## 🔄 Despliegue y Actualización de Código

### Opción A: Vía Git (Recomendada)
Si configuraste `repo_url`, cada vez que hagas cambios en el código de NestJS:
```bash
ssh azureuser@<IP-PUBLICA> '~/deploy.sh'
```

### Opción B: Subida Directa Ultra-Rápida (Comprimir sin node_modules ni .env)
> ⚠️ **IMPORTANTE**: Nunca uses `scp -r` directo sobre la carpeta del proyecto porque subirá 50,000+ archivos de `node_modules` (tarda 45 min) y sobreescribiría las variables de entorno del servidor. Con este comando, se empaqueta solo el código fuente (pesa ~180 KB), sube en **1 segundo** y compila en la VM:

```bash
tar --exclude='node_modules' --exclude='.git' --exclude='dist' --exclude='.env*' -czf backend.tar.gz -C ../../../../../asistencia-backend . && \
scp backend.tar.gz azureuser@<IP-PUBLICA>:/tmp/ && \
ssh azureuser@<IP-PUBLICA> 'tar -xzf /tmp/backend.tar.gz -C /opt/asistencia-backend && rm /tmp/backend.tar.gz && ~/deploy.sh' && \
rm backend.tar.gz
```

---

## 💡 Optimización para Azure Free Trial

- **Apagar VM cuando no esté en uso**:
  Para no consumir el crédito de tu cuenta Free de Azure, desasigna la VM cuando no la utilices:
  ```bash
  az vm deallocate --resource-group <NOMBRE_RG> --name <NOMBRE_VM>
  ```
  Para volver a encenderla:
  ```bash
  az vm start --resource-group <NOMBRE_RG> --name <NOMBRE_VM>
  ```
  *(Nota: Al usar IP pública estática Standard, la IP se conserva al encender y apagar).*

---

## 📦 Instrucciones para Subir a un Repositorio GitHub Independiente

Para publicar este código en su propio repositorio de GitHub:

```bash
# 1. Inicializar repositorio git local (si aún no lo está)
git init

# 2. Agregar origen remoto
git remote add origin https://github.com/modulo2-IaC/azure-OpenTofu-backend.git

# 3. Verificar que .gitignore proteja los archivos sensibles
git status
# Asegúrate de que NO aparezcan terraform.tfvars ni archivos .tfstate

# 4. Crear commit inicial
git add .
git commit -m "feat: initial OpenTofu infrastructure for backend VM with Azure remote state"

# 5. Subir a GitHub
git branch -M main
git push -u origin main
```
