variable "project_name" {
  description = "Nombre base del proyecto para nombrar los recursos"
  type        = string
  default     = "asistencia"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Region de Azure donde se desplegaran los recursos"
  type        = string
  default     = "swedencentral"
}

variable "vm_size" {
  description = "Tamano de la maquina virtual. Standard_B2as_v2 (2 vCPU / 2 GB RAM) disponible sin restricciones para Azure Free Trial"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "admin_username" {
  description = "Usuario administrador de la VM (para SSH)"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Contrasena del administrador de la VM (para SSH). Minimo 12 caracteres con mayusculas, numeros y simbolos."
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "Cadena de conexion PostgreSQL (ej. Neon con sslmode=require)"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Clave secreta para firmar tokens JWT. Si es null, se genera automaticamente."
  type        = string
  default     = null
  sensitive   = true
}

variable "cors_origin" {
  description = "Origenes CORS permitidos para el frontend"
  type        = string
  default     = "*"
}

variable "app_timezone" {
  description = "Zona horaria IANA para el backend"
  type        = string
  default     = "America/La_Paz"
}

variable "run_migrations" {
  description = "Si es true, ejecuta migraciones TypeORM al iniciar la app"
  type        = bool
  default     = true
}

variable "node_version" {
  description = "Version de Node.js a instalar en la VM (LTS recomendado)"
  type        = string
  default     = "20"
}

variable "repo_url" {
  description = "URL del repositorio Git del backend (para clonar en la VM)"
  type        = string
  default     = ""
}

variable "extra_tags" {
  description = "Etiquetas adicionales opcionales para los recursos"
  type        = map(string)
  default     = {}
}
