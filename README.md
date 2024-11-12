```mermaid
graph TD;
    A[Azure Repos] --> B[Azure Pipeline];
    B --> C[ACR];
    B --> D[Key Vault];
    C --> E[AKS Cluster];
    E --> F[Prod Namespace];
    E --> G[Dev Namespace];
