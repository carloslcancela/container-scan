# DevSecOps Container Security Lab

Laboratório prático para estudar a implementação de **DevSecOps em GitHub Actions**, com foco em:

- SCA (Software Composition Analysis)
- Container Image Scanning
- SBOM (Software Bill of Materials)
- Security Gate / bloqueio da pipeline
- GitHub Actions
- Docker
- Trivy
- GitHub Artifacts
- Evolução posterior para SARIF / GitHub Code Scanning
- Evolução posterior para Reusable Workflows e governança em escala

O laboratório foi desenhado para funcionar **sem necessidade de Azure, AWS, Kubernetes ou uma máquina virtual própria**.

---

## 1. Objetivo

Construir uma pipeline de segurança capaz de:

1. Baixar o código da aplicação.
2. Analisar as dependências da aplicação com SCA.
3. Construir uma imagem Docker.
4. Analisar a imagem do container em busca de vulnerabilidades.
5. Gerar um SBOM.
6. Aplicar um Security Gate.
7. Fazer a pipeline falhar quando forem encontradas vulnerabilidades `HIGH` ou `CRITICAL`.
8. Armazenar o SBOM como Artifact do workflow.
9. Evoluir posteriormente para integração com GitHub Code Scanning via SARIF.
10. Transformar o workflow em uma Reusable Workflow para reutilização por múltiplos repositórios.

---

# 2. Arquitetura

A arquitetura inicial do laboratório será:

```text
                         GitHub Repository
                                │
                                │ Push / Pull Request
                                ▼
                     ┌──────────────────────┐
                     │   GitHub Actions     │
                     │    ubuntu-latest     │
                     └──────────┬───────────┘
                                │
                ┌───────────────┼────────────────┐
                │               │                │
                ▼               ▼                ▼
             SCA Scan       Docker Build     SBOM
                │               │                │
                ▼               ▼                ▼
          Dependências      Docker Image     sbom.json
                │               │
                ▼               ▼
              Trivy           Trivy
                │               │
                └───────┬───────┘
                        ▼
                  Security Gate
                        │
                  ┌─────┴─────┐
                  ▼           ▼
                PASS          FAIL
```

---

# 3. Por que não é necessário Azure ou AWS?

O laboratório utiliza **GitHub-hosted runners**.

Quando o workflow contém:

```yaml
runs-on: ubuntu-latest
```

o GitHub disponibiliza temporariamente uma máquina Linux para executar o job.

Essa máquina possui o ambiente necessário para o laboratório, incluindo Docker.

O fluxo é:

```text
GitHub
   │
   ▼
GitHub Actions
   │
   ▼
Runner Ubuntu temporário
   │
   ├── Checkout
   ├── SCA
   ├── Docker Build
   ├── Container Scan
   └── SBOM
   │
   ▼
Fim do job
   │
   ▼
Runner descartado
```

A imagem Docker pode existir apenas localmente durante a execução do job.

Portanto, não é necessário:

- Azure VM
- AWS EC2
- Azure Container Registry
- Amazon ECR
- Kubernetes
- AKS
- EKS
- servidor próprio

---

# 4. Tecnologias utilizadas

| Tecnologia | Função |
|---|---|
| GitHub | Hospedagem do código |
| GitHub Actions | CI/CD e execução da pipeline |
| GitHub-hosted Runner | Ambiente temporário de execução |
| Ubuntu | Sistema operacional do runner |
| Docker | Build da imagem |
| Trivy | SCA, Container Scan e geração de SBOM |
| Node.js | Aplicação de exemplo |
| npm | Gerenciamento de dependências |
| GitHub Artifacts | Armazenamento do SBOM |
| SARIF | Formato para futura integração com GitHub Security |

---

# 5. Estrutura do repositório

Estrutura inicial:

```text
devsecops-container-lab/
│
├── app/
│   ├── package.json
│   ├── package-lock.json
│   └── server.js
│
├── Dockerfile
│
├── .dockerignore
│
└── .github/
    └── workflows/
        └── security.yml
```

A estrutura será expandida nas etapas futuras.

---

# 6. Aplicação de exemplo

Será utilizada uma aplicação simples em Node.js.

## `app/package.json`

```json
{
  "name": "devsecops-container-lab",
  "version": "1.0.0",
  "description": "Laboratório de DevSecOps",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

A versão da dependência é propositalmente antiga para permitir que o laboratório demonstre o funcionamento do SCA.

## `app/server.js`

```javascript
const express = require("express");

const app = express();
const port = 3000;

app.get("/", (req, res) => {
  res.json({
    application: "DevSecOps Container Lab",
    status: "running"
  });
});

app.listen(port, () => {
  console.log(`Application running on port ${port}`);
});
```

---

# 7. Dockerfile

O Dockerfile será utilizado para construir a imagem da aplicação.

```dockerfile
FROM node:18

WORKDIR /app

COPY app/package*.json ./

RUN npm ci --omit=dev

COPY app/ .

EXPOSE 3000

CMD ["node", "server.js"]
```

O processo será:

```text
Dockerfile
    │
    ▼
docker build
    │
    ▼
devsecops-lab:<commit-sha>
```

A imagem não precisa ser enviada para um registry na primeira etapa do laboratório.

---

# 8. SCA — Software Composition Analysis

## Objetivo

Identificar vulnerabilidades conhecidas nas dependências utilizadas pela aplicação.

O fluxo será:

```text
package.json
      │
      ▼
package-lock.json
      │
      ▼
Trivy
      │
      ▼
Vulnerability Database
      │
      ▼
CVE / Vulnerability
      │
      ▼
Severity
```

O SCA analisa principalmente os componentes de software utilizados pela aplicação.

Exemplo conceitual:

```text
Aplicação
   │
   └── express
         │
         └── dependency
               │
               └── versão vulnerável
                       │
                       ▼
                     CVE
                       │
                       ▼
                   HIGH/CRITICAL
```

---

# 9. Container Image Scanning

Depois do SCA, a pipeline constrói a imagem Docker.

```text
Dockerfile
     │
     ▼
Docker Build
     │
     ▼
Container Image
     │
     ▼
Trivy
     │
     ▼
Vulnerabilities
```

O scan da imagem permite identificar vulnerabilidades presentes em:

- pacotes do sistema operacional;
- bibliotecas;
- dependências da aplicação;
- componentes incluídos na imagem.

Isso permite comparar dois pontos diferentes:

```text
SCA

Código
  ↓
Dependências
  ↓
Vulnerabilidades
```

versus:

```text
Container Scan

Docker Image
  ↓
OS + Libraries + Application Dependencies
  ↓
Vulnerabilidades
```

---

# 10. SBOM

SBOM significa:

> Software Bill of Materials

É uma relação estruturada dos componentes presentes no software ou container.

Exemplo conceitual:

```text
Container
│
├── Node.js
├── Debian packages
├── Express
├── body-parser
├── qs
├── outras dependências
└── ...
```

O laboratório utilizará o Trivy para gerar um SBOM em formato CycloneDX.

O resultado será:

```text
sbom.json
```

Esse arquivo será armazenado como GitHub Artifact.

Fluxo:

```text
Docker Image
     │
     ▼
   Trivy
     │
     ▼
CycloneDX
     │
     ▼
sbom.json
     │
     ▼
GitHub Artifact
```

---

# 11. Security Gate

Um dos objetivos principais do laboratório é entender como transformar o resultado de uma ferramenta de segurança em uma decisão de pipeline.

A regra inicial será:

```text
HIGH       → FAIL
CRITICAL   → FAIL
MEDIUM     → permitido
LOW        → permitido
```

No Trivy:

```yaml
severity: HIGH,CRITICAL
exit-code: 1
```

O `exit-code: 1` faz com que o processo retorne código de erro quando uma vulnerabilidade dentro dos critérios for encontrada.

Assim:

```text
Scanner
   │
   ▼
Vulnerabilidade encontrada?
   │
   ├── NÃO ──► PASS
   │
   └── SIM
         │
         ▼
      HIGH/CRITICAL?
         │
         ├── NÃO ──► PASS
         │
         └── SIM ──► FAIL
```

---

# 12. Workflow inicial

Arquivo:

```text
.github/workflows/security.yml
```

Conteúdo:

```yaml
name: DevSecOps Security

on:
  push:
    branches:
      - main
  pull_request:

permissions:
  contents: read
  security-events: write

jobs:

  sca:
    name: SCA - Dependency Scan
    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Run SCA
        uses: aquasecurity/trivy-action@0.36.0
        with:
          scan-type: fs
          scan-ref: ./app
          scanners: vuln
          severity: HIGH,CRITICAL
          ignore-unfixed: true
          exit-code: 1


  container:
    name: Container Security Scan
    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Build Docker Image
        run: |
          docker build \
            -t devsecops-lab:${{ github.sha }} \
            .

      - name: Scan Container
        uses: aquasecurity/trivy-action@0.36.0
        with:
          image-ref: devsecops-lab:${{ github.sha }}
          format: table
          scanners: vuln
          severity: HIGH,CRITICAL
          ignore-unfixed: true
          exit-code: 1


  sbom:
    name: Generate SBOM
    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Build Docker Image
        run: |
          docker build \
            -t devsecops-lab:${{ github.sha }} \
            .

      - name: Generate SBOM
        uses: aquasecurity/trivy-action@0.36.0
        with:
          image-ref: devsecops-lab:${{ github.sha }}
          format: cyclonedx
          output: sbom.json
          scanners: vuln

      - name: Upload SBOM
        uses: actions/upload-artifact@v4
        with:
          name: container-sbom
          path: sbom.json
```

---

# 13. Fluxo completo da pipeline

Quando um commit for enviado para a branch `main`:

```text
git push
   │
   ▼
GitHub
   │
   ▼
GitHub Actions
   │
   ├───────────────────────┐
   │                       │
   ▼                       ▼
SCA                     Container
   │                     │
   │                     ▼
   │                 Docker Build
   │                     │
   │                     ▼
   │                 Container
   │                     │
   │                     ▼
   │                   Trivy
   │
   ▼
Trivy
   │
   └──────────────┐
                  │
                  ▼
             Vulnerability
                  │
                  ▼
            Security Gate
                  │
          ┌───────┴────────┐
          ▼                ▼
        PASS              FAIL
```

O job de SBOM executa separadamente:

```text
Docker Build
     │
     ▼
    Trivy
     │
     ▼
 CycloneDX
     │
     ▼
 sbom.json
     │
     ▼
GitHub Artifact
```

---

# 14. Como executar

## 14.1 Criar o repositório

No GitHub:

```text
New repository
```

Nome sugerido:

```text
devsecops-container-lab
```

Pode ser privado.

---

## 14.2 Clonar

```bash
git clone <repository>
cd devsecops-container-lab
```

---

## 14.3 Criar a estrutura

```bash
mkdir -p app
mkdir -p .github/workflows
```

Adicionar:

```text
app/package.json
app/server.js
Dockerfile
.github/workflows/security.yml
```

---

## 14.4 Gerar o package-lock.json

Dentro de `app`:

```bash
npm install
```

Isso produzirá:

```text
app/
├── package.json
└── package-lock.json
```

O `package-lock.json` é importante para representar as versões efetivamente resolvidas das dependências.

---

## 14.5 Fazer o commit

```bash
git add .
git commit -m "initial devsecops security lab"
git push
```

---

# 15. O que observar no GitHub

No repositório:

```text
Actions
```

Você deverá encontrar:

```text
DevSecOps Security
│
├── SCA - Dependency Scan
├── Container Security Scan
└── Generate SBOM
```

O objetivo inicial é observar:

### SCA

Quais dependências possuem vulnerabilidades?

### Container Scan

Quais vulnerabilidades existem dentro da imagem?

### SBOM

Quais componentes existem dentro do container?

### Security Gate

Por que o workflow passou ou falhou?

---

# 16. Conceito importante: SCA x Container Scan

Não considerar os dois scans como exatamente a mesma coisa.

## SCA

Pergunta:

> "Quais vulnerabilidades existem nas dependências que minha aplicação utiliza?"

Exemplo:

```text
package-lock.json
       │
       ▼
Express
       │
       ▼
CVE
```

## Container Scan

Pergunta:

> "Quais vulnerabilidades existem na imagem que estou prestes a executar?"

Exemplo:

```text
Container
│
├── OS packages
├── Runtime
├── Application
├── Libraries
└── Dependencies
       │
       ▼
    Trivy
```

Em uma estratégia DevSecOps, os dois controles são complementares.

---

# 17. Por que gerar SBOM?

O SBOM permite criar uma visão de inventário dos componentes.

Isso é especialmente importante para situações como:

```text
Nova vulnerabilidade crítica descoberta
             │
             ▼
        Qual componente?
             │
             ▼
          SBOM
             │
             ▼
       Quais aplicações?
             │
             ▼
       Quais containers?
```

Em ambientes corporativos, isso pode ajudar em processos de:

- Vulnerability Management
- Supply Chain Security
- Incident Response
- Compliance
- Software Asset Management
- Dependency Management

---

# 18. Próxima etapa: SARIF

A próxima evolução será fazer o Trivy gerar:

```text
trivy-results.sarif
```

E publicar o resultado no GitHub Code Scanning.

Fluxo:

```text
Trivy
  │
  ▼
SARIF
  │
  ▼
GitHub Security
  │
  ▼
Code Scanning
```

Isso permitirá visualizar os achados de segurança dentro do próprio GitHub.

---

# 19. Próxima etapa: Reusable Workflow

Depois de entender o workflow específico da aplicação, o laboratório deverá evoluir para uma arquitetura reutilizável.

Estrutura:

```text
.github/
└── workflows/
    ├── security.yml
    └── reusable-security.yml
```

A ideia é permitir que outras aplicações chamem o workflow de segurança.

Exemplo:

```yaml
jobs:

  security:
    uses: minha-org/devsecops/.github/workflows/reusable-security.yml@main
```

Arquitetura:

```text
                 GitHub Organization
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
        App A           App B          App C
          │              │              │
          └──────────────┼──────────────┘
                         ▼
                Reusable Workflow
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
             SCA       SBOM      Container
              │          │          │
              └──────────┼──────────┘
                         ▼
                  Security Gate
```

Essa etapa aproxima o laboratório de um cenário corporativo.

---

# 20. Evolução para escala

Depois do funcionamento básico, o laboratório poderá explorar:

```text
                     Security Platform
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
       SCA                SBOM             Container
        │                   │                   │
        ▼                   ▼                   ▼
     Trivy              CycloneDX           Trivy
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
                      Security Gate
                            │
                            ▼
                     GitHub Security
                            │
                            ▼
                    Security Dashboard
```

E posteriormente:

- Reusable Workflows
- Controle de versão do workflow
- Políticas de segurança
- Exceções / Risk Acceptance
- Allowlist / Ignore rules
- Severity thresholds
- Dependabot
- SAST
- Secret Scanning
- IaC Scanning
- API Security
- Supply Chain Security
- Artifact Attestation
- Container Registry
- GHCR
- Assinatura de imagens
- Provenance
- Verificação de integridade
- Governança de workflows
- Métricas de cobertura
- Inventário de repositórios
- Rollout em larga escala

---

# 21. Visão final do laboratório

A evolução planejada será:

```text
FASE 1
───────
GitHub
  │
  ▼
Actions
  │
  ├── SCA
  ├── Container Scan
  └── SBOM
```

```text
FASE 2
───────
GitHub
  │
  ▼
Actions
  │
  ├── SCA
  ├── Container Scan
  ├── SBOM
  └── SARIF
        │
        ▼
   GitHub Security
```

```text
FASE 3
───────
Aplicações
    │
    ▼
Reusable Security Workflow
    │
    ├── SCA
    ├── SAST
    ├── Secret Scan
    ├── IaC Scan
    ├── Container Scan
    └── SBOM
            │
            ▼
      Security Gate
```

```text
FASE 4
───────
DevSecOps Platform

             ┌── SAST
             ├── SCA
             ├── SBOM
             ├── Container
             ├── Secrets
             ├── IaC
             └── Supply Chain
                    │
                    ▼
              Security Gate
                    │
                    ▼
               Deployment
```

---

# 22. Objetivos de aprendizagem

Ao finalizar o laboratório, o objetivo é conseguir explicar claramente:

- O que é SCA.
- O que é Container Image Scanning.
- Qual a diferença entre SCA e Container Scanning.
- O que é SBOM.
- Para que serve um `package-lock.json`.
- Como dependências são identificadas.
- Como vulnerabilidades são associadas a componentes.
- Como uma imagem Docker é construída dentro do GitHub Actions.
- Onde o container existe durante a pipeline.
- Como o scanner acessa a imagem.
- Como transformar uma vulnerabilidade em falha da pipeline.
- Como gerar e armazenar um SBOM.
- O que é SARIF.
- Como integrar resultados de segurança ao GitHub.
- Como criar um workflow reutilizável.
- Como transformar um controle de segurança em uma capacidade centralizada de DevSecOps.
- Quais desafios surgem quando essa arquitetura precisa ser aplicada em grande escala.

---

# 23. Resultado esperado

Ao final da primeira versão, o repositório deverá ser capaz de executar:

```text
Commit
  │
  ▼
GitHub Actions
  │
  ├───────────────┐
  │               │
  ▼               ▼
 SCA           Docker Build
  │               │
  │               ▼
  │          Container Scan
  │               │
  └───────┬───────┘
          │
          ▼
     Vulnerabilities
          │
          ▼
    Security Gate
          │
      ┌───┴───┐
      ▼       ▼
    PASS     FAIL

        +

      SBOM
       │
       ▼
 GitHub Artifact
```

O laboratório começa simples, mas foi desenhado para evoluir para uma **arquitetura de DevSecOps em escala**, permitindo estudar não apenas as ferramentas, mas também os conceitos de **governança, automação, padronização e segurança da cadeia de software**.
