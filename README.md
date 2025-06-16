# EKS Infrastructure for Daily Banking Case

## Visão Geral

Este repositório contém a infraestrutura como código (IaC) para implantação de um cluster Amazon EKS (Elastic Kubernetes Service) para o caso Daily Banking. A infraestrutura é gerenciada usando Terraform.

## Componentes da Infraestrutura

### Cluster EKS

- Nome do Cluster: `dailybanking-case`
- Grupo de Nodes: `appNodedailybanking-case`
- Tipo de Instância: t3.large (instâncias SPOT)
- Configuração do Grupo de Nodes:
  - Tamanho Desejado: 3 nodes
  - Tamanho Mínimo: 1 node
  - Tamanho Máximo: 7 nodes
  - Tipo de Capacidade: instâncias SPOT para otimização de custos

### Configuração de Rede

- Utiliza VPC padrão em us-east-1
- Duas sub-redes em diferentes zonas de disponibilidade:
  - us-east-1a
  - us-east-1b
- Sub-redes devidamente marcadas para integração com EKS e ELB

### Roles e Políticas IAM

1. Role do Cluster EKS (`roleEKS-2`)

   - AmazonEKSClusterPolicy
   - AmazonEKSVPCResourceController
   - Política EC2 personalizada para descrição de instâncias

2. Role do Grupo de Nodes (`roleNodeEKS-2`)

   - AmazonEKSWorkerNodePolicy
   - AmazonEKS_CNI_Policy
   - AmazonEC2ContainerRegistryReadOnly
   - ElasticLoadBalancingFullAccess
   - AmazonEC2FullAccess

3. Role de Gerenciamento de Secrets (`roleNodeSecrets-2`)
   - Política SNS personalizada para notificações

## Pré-requisitos

- AWS CLI configurado com credenciais apropriadas
- Terraform instalado (versão 1.0.0 ou superior)
- kubectl instalado
- Permissões IAM da AWS para criar clusters EKS e recursos relacionados

## Uso

1. Inicializar o Terraform:

```bash
terraform init
```

2. Revisar as mudanças planejadas:

```bash
terraform plan
```

3. Aplicar a infraestrutura:

```bash
terraform apply
```

4. Configurar kubectl:

```bash
aws eks update-kubeconfig --name dailybanking-case --region us-east-1
```

## Componentes Adicionais

- Provedor OIDC configurado para IRSA (IAM Roles for Service Accounts)
- Template de lançamento para instâncias node com suporte a IMDSv2
- Configuração do controlador de ingress incluída
