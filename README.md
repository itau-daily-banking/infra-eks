# Infraestrutura EKS para Sistema de Renegociação de Dívidas

## Visão Geral

Este repositório contém a infraestrutura como código (IaC) para provisionar e gerenciar um cluster Amazon EKS (Elastic Kubernetes Service) que suporta o sistema de desafio t[ecnico do mercado livre. A infraestrutura é gerenciada através do Terraform, permitindo uma implantação consistente e reproduzível do ambiente.

## Estrutura do Repositório

### Arquivos Principais

- `eks.tf`: Configuração principal do cluster EKS
- `vpc.tf`: Definição da rede virtual e subnets
- `backend.tf`: Configuração do backend do Terraform (S3)
- `data.tf`: Fontes de dados do Terraform
- `variables.tf`: Definição de variáveis utilizadas na infraestrutura

### Configurações Kubernetes

- `ingress-controller.yaml`: Configuração do controlador de ingress
- `irsa.yaml`: Configuração de IAM Roles for Service Accounts

### CI/CD

- `.github/workflows/`: Diretório contendo os workflows de GitHub Actions
  - `tf_deploy.yaml`: Workflow para deploy da infraestrutura
  - `tf_destroy.yaml`: Workflow para destruição da infraestrutura

## Componentes da Infraestrutura

### Cluster EKS

- Cluster Kubernetes gerenciado pela AWS
- Configurado com alta disponibilidade
- Suporte a múltiplas zonas de disponibilidade

### Nodes

- Instâncias t3.large (SPOT)
- Auto-scaling configurado (1-7 nós)
- Disco de 20GB por nó

### Rede

- VPC dedicada
- Subnets públicas e privadas
- NAT Gateway para acesso à internet
- Security Groups configurados

### Segurança

- IAM Roles e Policies
- Provedor OIDC para autenticação
- Políticas de segurança restritivas

## Como Utilizar

### Pré-requisitos

1. Terraform instalado (versão 1.3.0 ou superior)
2. Credenciais AWS configuradas
3. Bucket S3 para estado do Terraform
4. Acesso à AWS com permissões adequadas

### Deploy

1. Configure as variáveis de ambiente necessárias
2. Execute o workflow de deploy via GitHub Actions
3. Aguarde a conclusão do processo

### Manutenção

- Atualizações do cluster via Terraform
- Monitoramento via CloudWatch
- Backups automáticos do estado

## Monitoramento e Logs

- Métricas do CloudWatch
- Logs do cluster
- Monitoramento de recursos EC2
