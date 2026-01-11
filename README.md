# MinIO on OpenShift — Helm + ArgoCD

Este repositório contém um **Helm Chart** para deploy do **MinIO** no OpenShift, preparado para uso com **ArgoCD (OpenShift GitOps)**.

>  **Importante:** antes de usar este chart via ArgoCD, é necessário um *bootstrap* de permissões no namespace de destino.

---

##  Por que isso é necessário?

O ArgoCD aplica manifests no cluster usando o ServiceAccount:

```
system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller
```

Por padrão, esse ServiceAccount **não possui permissão** para criar recursos como:

- `Deployment`
- `Service`
- `Route`
- `PersistentVolumeClaim`

em namespaces arbitrários (ex.: `minio-ocp`).

Sem essa permissão, o ArgoCD falha com erros do tipo:

```
is forbidden: User "openshift-gitops-argocd-application-controller"
cannot create resource "deployments/services/routes"
```

---

##  Pré-requisito (obrigatório para Helm via ArgoCD)

Antes de sincronizar a Application do ArgoCD, **crie o RoleBinding abaixo no namespace de destino**, **uma única vez**, como *cluster-admin*.

###  Exemplo: namespace `minio-ocp`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rb-minio
  namespace: minio-ocp
subjects:
  - kind: ServiceAccount
    name: openshift-gitops-argocd-application-controller
    namespace: openshift-gitops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
```

### Como aplicar

Via CLI:
```bash
oc apply -f rolebinding.yaml
```

Ou via **OpenShift Web Console**:
- Administrator → Project `minio-ocp`
- User Management → RoleBindings
- Criar RoleBinding:
  - **Role:** `admin`
  - **Subject:** ServiceAccount  
    `openshift-gitops-argocd-application-controller`  
    Namespace: `openshift-gitops`

---

##  Observações de segurança

- O RoleBinding é **namespaced** (não é ClusterRoleBinding)
- A permissão fica **restrita ao namespace alvo**
- `admin` foi escolhido por simplicidade e compatibilidade com:
  - Services
  - Routes
  - Deployments
  - PVCs
- Em ambientes mais restritivos, é possível substituir por um role customizado

---

##  Depois do bootstrap

Após criar o RoleBinding:

1. Crie a **Application** no ArgoCD apontando para este repositório
2. Sincronize normalmente
3. O ArgoCD conseguirá:
   - Criar o Deployment do MinIO
   - Provisionar PVCs (`WaitForFirstConsumer` funcionará corretamente)
   - Criar Services e Routes com hostname dinâmico do cluster

---

##  Importante saber

Este bootstrap é necessário **apenas uma vez por namespace**.  
Após isso, todo o ciclo de vida do MinIO passa a ser **100% GitOps**.
