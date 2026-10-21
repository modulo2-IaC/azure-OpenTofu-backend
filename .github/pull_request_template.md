## 🛡️ Checklist de Seguridad y Confiabilidad (DevSecOps IaC)

### Descripción de los cambios
<!-- Explica brevemente los cambios en la infraestructura OpenTofu / Azure -->

### Controles Obligatorios de Calidad y Seguridad
- [ ] **Punto 2 (Control de versiones):** El código sigue branch protection rules y pasa la revisión de pares (Peer Review).
- [ ] **Punto 3 (Módulos y dependencias):** Proveedores fijados y verificados con `.terraform.lock.hcl`.
- [ ] **Punto 5 (Análisis estático):**
  - [ ] `tflint` ejecutado y sin advertencias críticas.
  - [ ] `checkov` ejecutado y políticas CIS de Azure evaluadas.
- [ ] **Punto 6 (Escaneo de secretos):** `gitleaks` verificado (sin credenciales, tokens ni passwords expuestas).
- [ ] **Punto 11 (Monitoreo):** Recursos auditados y métricas/alertas en Azure Monitor validadas.
- [ ] `tofu fmt -check` y `tofu validate` aprobados exitosamente.
