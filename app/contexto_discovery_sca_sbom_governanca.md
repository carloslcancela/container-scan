# Contexto Consolidado --- Discovery de Arquitetura de SCA, SBOM e Software Component Governance

> **Objetivo deste documento**
>
> Este Markdown consolida o contexto discutido sobre o discovery de
> arquitetura de segurança de componentes de software. Ele foi escrito
> para ser fornecido diretamente a outra IA como contexto para gerar uma
> apresentação executiva e técnica para liderança de Cyber Security.
>
> A apresentação resultante deve explicar o cenário atual, os riscos, as
> perguntas ainda em aberto, a arquitetura AS-IS, a arquitetura TO-BE,
> os gaps, as métricas e um plano de evolução.
>
> **Importante:** funcionalidades, integrações e coberturas que ainda
> não foram confirmadas durante o discovery devem ser apresentadas como
> **"a validar"**, e não como fatos do ambiente.

------------------------------------------------------------------------

# 1. Contexto do discovery

O objetivo não é simplesmente verificar se a empresa possui uma
ferramenta de SCA.

O discovery deve avaliar se existe uma capacidade corporativa e ponta a
ponta de **Software Component Governance / Software Supply Chain
Security**, capaz de:

1.  prevenir a introdução de componentes inadequados;
2.  detectar vulnerabilidades conhecidas durante o desenvolvimento;
3.  manter inventário dos componentes utilizados;
4.  identificar novas vulnerabilidades descobertas depois do deploy;
5.  correlacionar componentes com artefatos e workloads efetivamente em
    produção;
6.  identificar rapidamente aplicação e owner responsáveis;
7.  priorizar o risco;
8.  iniciar o processo de resposta/remediação;
9.  validar que a correção chegou ao ambiente produtivo;
10. medir todo esse processo.

A pergunta executiva central é:

> **Se amanhã for publicada uma CVE crítica para uma biblioteca X,
> conseguimos identificar automaticamente todas as aplicações e
> workloads em produção que utilizam a versão afetada?**

Uma segunda pergunta importante é:

> **Quanto tempo leva desde a publicação/disponibilização da
> vulnerabilidade até a identificação dos workloads afetados e seus
> respectivos owners?**

------------------------------------------------------------------------

# 2. Ambiente tecnológico conhecido

Até o momento foram identificados os seguintes componentes:

## GitHub

Utilizado para:

-   repositórios;
-   código-fonte;
-   workflows;
-   pipelines CI/CD;
-   Dependency Graph;
-   Dependabot;
-   possivelmente reusable workflows;
-   integração com controles de segurança.

Existe um ambiente GitHub de grande escala, portanto governança
centralizada e cobertura são preocupações relevantes.

## Mend

Identificado como solução relacionada a:

-   SCA;
-   análise de dependências;
-   vulnerabilidades de componentes;
-   SBOM;
-   potencialmente políticas e governança de componentes.

Ainda é necessário confirmar exatamente:

-   quais módulos/licenças estão habilitados;
-   quais repositórios estão cobertos;
-   em quais pipelines a análise ocorre;
-   quais políticas estão configuradas;
-   como funciona a geração e persistência do SBOM;
-   se existe monitoramento contínuo depois do build;
-   como componentes internos/proprietários são tratados.

## JFrog Artifactory

Utilizado como repositório corporativo de:

-   dependências;
-   pacotes;
-   artefatos;
-   possivelmente imagens de container.

O Artifactory é um ponto importante da arquitetura porque representa uma
camada intermediária entre build e execução.

## JFrog Xray

Foi discutido como possível controle para análise contínua/periódica dos
artefatos armazenados no Artifactory.

O discovery deve confirmar:

-   se está habilitado;
-   quais repositórios são analisados;
-   frequência/reavaliação;
-   comportamento quando surge uma nova CVE;
-   associação com SBOM;
-   integração com processos de Vulnerability Management;
-   capacidade de identificar quais artefatos contêm determinado
    componente.

## RHACS

Red Hat Advanced Cluster Security está relacionado à camada de runtime.

O ambiente possui workloads Kubernetes em:

-   ARO;
-   AKS;
-   EKS.

O discovery deve validar se o RHACS permite estabelecer a correlação:

``` text
Imagem
  ↓
Workload
  ↓
Namespace
  ↓
Cluster
  ↓
Aplicação
  ↓
Owner
```

Também deve ser validado como alertas e vulnerabilidades chegam a:

-   Vulnerability Management;
-   SOC;
-   CSIRT;
-   times de aplicação.

------------------------------------------------------------------------

# 3. Problema arquitetural principal

O ponto central da discussão foi que **SCA apenas na pipeline não
resolve completamente o risco de componentes de software**.

Exemplo:

``` text
DIA 1

Aplicação
   ↓
Dependência X v1.2
   ↓
Pipeline
   ↓
Mend SCA
   ↓
Nenhuma CVE conhecida
   ↓
Build aprovado
   ↓
Artifactory
   ↓
Produção
```

Alguns dias depois:

``` text
DIA N

Nova CVE crítica publicada
        ↓
Afeta Dependência X v1.2
```

A pipeline original já terminou.

Portanto, simplesmente possuir um gate de SCA no momento do build não
responde automaticamente:

> Quais aplicações que já estão em produção utilizam X v1.2?

Esse é o cenário que precisa ser tratado pela arquitetura.

------------------------------------------------------------------------

# 4. O problema das novas CVEs / "zero-day"

Uma dependência pode ser considerada segura no momento do build e
tornar-se vulnerável posteriormente.

Portanto, a arquitetura precisa possuir capacidade de **reavaliação
contínua**.

O fluxo desejado é:

``` text
Nova vulnerabilidade
        ↓
Vulnerability Intelligence
        ↓
Componente afetado
        ↓
Versões afetadas
        ↓
SBOMs afetados
        ↓
Artefatos/imagens afetados
        ↓
Deployments afetados
        ↓
Workloads em produção
        ↓
Aplicações
        ↓
Owners
        ↓
Resposta
        ↓
Remediação
```

Essa capacidade é muito mais importante do que simplesmente afirmar:

> "Temos SCA na pipeline."

------------------------------------------------------------------------

# 5. Papel de cada capacidade

Uma forma importante de explicar a arquitetura é separar
responsabilidades.

## SCA

O SCA responde principalmente:

> Quais componentes/dependências existem e quais riscos conhecidos estão
> associados a eles no momento da análise?

Pode identificar, dependendo da solução e configuração:

-   vulnerabilidades;
-   dependências diretas;
-   dependências transitivas;
-   licenças;
-   políticas;
-   versões;
-   riscos de componentes.

## SBOM

O SBOM é essencialmente um **inventário estruturado de componentes**.

Ele não deve ser confundido com a vulnerabilidade em si.

Uma forma simples de explicar:

``` text
SCA = análise
SBOM = inventário
Policy = decisão
Runtime = realidade operacional
Vulnerability Intelligence = mudança do risco ao longo do tempo
```

O SBOM possibilita perguntar posteriormente:

> "Quais artefatos possuem o componente X na versão Y?"

Sem necessariamente precisar reconstruir todas as aplicações.

## Artifactory

Representa o inventário de artefatos distribuíveis.

Pode ajudar a responder:

> "Quais artefatos armazenados possuem o componente vulnerável?"

Mas existe uma diferença crítica:

``` text
Artefato vulnerável no Artifactory
            ≠
Workload vulnerável em produção
```

Nem todo artefato armazenado está necessariamente executando.

## Xray

Pode representar uma camada de análise contínua dos artefatos
armazenados.

A hipótese arquitetural a validar é:

``` text
Nova CVE
   ↓
Xray/Vulnerability Intelligence
   ↓
Reavaliação dos artefatos
   ↓
Artefatos afetados
```

Mas ainda é necessário chegar ao runtime.

## RHACS

A camada de runtime deve ajudar a responder:

> "O que está efetivamente executando agora?"

A correlação ideal seria:

``` text
Artifact/Image
      ↓
Deployment
      ↓
Workload
      ↓
Cluster
      ↓
Application
      ↓
Owner
```

------------------------------------------------------------------------

# 6. Arquitetura AS-IS conceitual

O cenário atualmente conhecido pode ser representado inicialmente como:

``` text
┌─────────────────────────────┐
│           GitHub            │
│                             │
│ Repositories                │
│ Dependency Graph            │
│ Dependabot                  │
│ Workflows / CI/CD           │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│          Pipeline           │
│                             │
│ Mend SCA                    │
│ SBOM                        │
│ Security Gates              │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      JFrog Artifactory      │
│                             │
│ Dependencies                │
│ Packages                    │
│ Artifacts / Images          │
│ Xray ?                      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│               Runtime                   │
│                                         │
│      ARO          AKS          EKS      │
│                                         │
│                RHACS                    │
└──────────────────┬──────────────────────┘
                   │
                   ▼
          VM / SOC / CSIRT
```

Existem ainda elementos que precisam ser posicionados corretamente:

-   segunda análise/solução de SBOM identificada;
-   source of truth do SBOM;
-   Vulnerability Intelligence;
-   fluxo de incidentes;
-   CMDB/catálogo de aplicações;
-   associação aplicação → owner;
-   integração Mend → Artifactory;
-   integração Artifactory → RHACS;
-   integração RHACS → VM/SOC/CSIRT.

------------------------------------------------------------------------

# 7. Duas análises/fluxos de SBOM

Durante o discovery foram identificadas aparentemente **duas análises ou
soluções relacionadas a SBOM**.

Isso precisa ser investigado.

As principais perguntas são:

-   Quem gera cada SBOM?
-   Em qual etapa?
-   Qual ferramenta?
-   Qual formato?
-   SPDX?
-   CycloneDX?
-   Onde o SBOM é armazenado?
-   Existe versionamento?
-   O SBOM acompanha o artefato?
-   O SBOM é atualizado depois do build?
-   Quem consome cada SBOM?
-   Vulnerability Management?
-   Mend?
-   Xray?
-   RHACS?
-   auditoria?
-   governança?
-   As duas soluções são complementares?
-   Existe duplicidade?
-   Qual delas é o **source of truth**?
-   Existe diferença de cobertura entre elas?

O objetivo não é simplesmente eliminar duplicidade.

Primeiro é necessário entender:

> **Qual função arquitetural cada implementação de SBOM está tentando
> cumprir?**

------------------------------------------------------------------------

# 8. Dependabot

Foi discutida a necessidade de descobrir onde o Dependabot está
configurado.

Pontos a investigar nos repositórios GitHub:

``` text
.github/dependabot.yml
```

ou:

``` text
.github/dependabot.yaml
```

Também devem ser avaliados:

-   Dependency Graph;
-   Dependabot alerts;
-   Dependabot Security Updates;
-   Dependabot Version Updates;
-   Pull Requests gerados;
-   configurações de Security;
-   reusable workflows;
-   configurações centralizadas em organização;
-   possíveis templates corporativos.

O usuário identificou informações relacionadas ao Dependabot também
através do **GitHub Insights**.

A questão de discovery não é apenas:

> "Dependabot existe?"

Mas:

> "Qual é a cobertura real do Dependabot no universo de repositórios?"

E também:

> "Ele é configurado individualmente, por template, por reusable
> workflow ou por política central?"

------------------------------------------------------------------------

# 9. Dependabot versus Mend

Não devemos assumir que Dependabot e Mend são necessariamente
redundantes.

Uma possível separação conceitual é:

``` text
Dependabot
   ↓
Atualização de dependências
   ↓
Pull Requests

Mend
   ↓
SCA
   ↓
Vulnerabilidades
Licenças
Policies
SBOM
Governança
```

Mas essa divisão precisa ser validada no ambiente real.

Perguntas importantes:

-   Dependabot é usado para atualização?
-   Mend também gera PRs?
-   Existe sobreposição?
-   Quem é a fonte oficial para vulnerabilidades?
-   Quem bloqueia pipeline?
-   Quem controla políticas?
-   Quem é responsável pela remediação?
-   Existe duplicação de alertas?

------------------------------------------------------------------------

# 10. Governança de bibliotecas além de CVEs

O discovery não deve limitar Software Component Governance apenas a
vulnerabilidades.

A organização também pode precisar governar:

``` text
Componente vulnerável
Componente obsoleto
Componente sem suporte
Versão proibida
Licença proibida
Componente não aprovado
Componente malicioso
Componente interno vulnerável
Componente com versão excessivamente antiga
```

A pergunta arquitetural passa a ser:

> "Quais componentes são permitidos dentro do ecossistema corporativo?"

E não apenas:

> "Quais componentes possuem CVE?"

------------------------------------------------------------------------

# 11. Bibliotecas internas/proprietárias

Outro ponto discutido foi o tratamento de componentes desenvolvidos
internamente.

Exemplo:

``` text
biblioteca-auth-interna
```

É importante que componentes internos também possam fazer parte do
inventário e da governança.

Cenário:

``` text
Biblioteca interna
       ↓
Usada por 500 aplicações
       ↓
Falha crítica descoberta
```

A organização precisa conseguir responder:

> "Quais aplicações consomem essa biblioteca?"

Portanto, a governança de componentes não pode considerar apenas
componentes open source.

------------------------------------------------------------------------

# 12. Source of Truth

Um ponto importante do discovery é descobrir quais sistemas são fontes
oficiais para cada informação.

Exemplo:

  Informação        Possível Source of Truth
  ----------------- --------------------------
  Código            GitHub
  Dependências      GitHub / Mend
  SBOM              A validar
  Artefato          Artifactory
  Vulnerabilidade   Mend / Xray / VM
  Runtime           RHACS
  Aplicação         CMDB / catálogo
  Owner             CMDB / catálogo / GitHub
  Incidente         SOC / CSIRT / ITSM

A arquitetura precisa evitar múltiplas fontes conflitantes sem definição
de autoridade.

------------------------------------------------------------------------

# 13. Correlação ponta a ponta

O objetivo final é conseguir estabelecer esta cadeia:

``` text
CVE
 ↓
Component
 ↓
Version
 ↓
SBOM
 ↓
Artifact/Image
 ↓
Deployment
 ↓
Workload
 ↓
Cluster
 ↓
Application
 ↓
Owner
 ↓
Incident
 ↓
Remediation
```

Esse é provavelmente o ponto mais importante do discovery.

Ferramentas isoladas podem possuir pedaços da informação.

A arquitetura precisa avaliar se os pedaços conseguem ser
correlacionados.

------------------------------------------------------------------------

# 14. Capability Model

Uma forma recomendada de organizar a apresentação é através das
capacidades:

``` text
PREVENT
   ↓
DETECT
   ↓
IDENTIFY
   ↓
CORRELATE
   ↓
PRIORITIZE
   ↓
RESPOND
   ↓
REMEDIATE
   ↓
VALIDATE
```

Possível associação:

  Capability   Controles/Ferramentas
  ------------ -----------------------------------------
  Prevent      GitHub, Dependabot, Mend
  Detect       Mend, Xray, RHACS
  Identify     SBOM, Mend, Artifactory
  Correlate    SBOM + Artifact + Runtime + Application
  Prioritize   Vulnerability Management
  Respond      VM, SOC, CSIRT
  Remediate    GitHub, Pipeline, Application Teams
  Validate     SCA + Artifact Scan + Runtime

------------------------------------------------------------------------

# 15. Arquitetura TO-BE conceitual

A arquitetura futura deveria permitir:

``` text
              Vulnerability Intelligence
                         │
                         ▼
                       CVE
                         │
                         ▼
                  Component/Version
                         │
                         ▼
                   SBOM Inventory
                         │
                         ▼
                  Artifact / Image
                         │
                         ▼
                    Artifactory
                         │
                         ▼
                     Deployment
                         │
             ┌───────────┼───────────┐
             ▼           ▼           ▼
            ARO         AKS         EKS
             └───────────┼───────────┘
                         │
                         ▼
                       RHACS
                         │
                         ▼
                      Workload
                         │
                         ▼
                    Application
                         │
                         ▼
                       Owner
                         │
                         ▼
              Vulnerability Management
                         │
                         ▼
                    SOC / CSIRT
                         │
                         ▼
                    Remediation
                         │
                         ▼
                       GitHub
                         │
                         ▼
                       Build
                         │
                         ▼
                       Deploy
                         │
                         ▼
                     Validation
```

------------------------------------------------------------------------

# 16. Principais gaps a investigar

## Gap 1 --- Coverage

Precisamos saber:

-   quantos repositórios existem;
-   quantos possuem Mend;
-   quantos geram SBOM;
-   quantos possuem Dependabot;
-   quantos artefatos são analisados;
-   quantos workloads são monitorados pelo RHACS;
-   cobertura por ARO, AKS e EKS.

## Gap 2 --- SBOM duplicado ou fragmentado

Existem aparentemente duas análises de SBOM.

Precisamos entender:

-   objetivo;
-   cobertura;
-   formato;
-   persistência;
-   consumidor;
-   source of truth.

## Gap 3 --- SBOM → Artifact

É possível relacionar inequivocamente:

``` text
SBOM
 ↓
Artifact
```

?

## Gap 4 --- Artifact → Runtime

É possível responder:

``` text
Artifact/Image
      ↓
Onde está rodando?
```

?

## Gap 5 --- Runtime → Application

É possível transformar:

``` text
pod/container/image
```

em:

``` text
aplicação corporativa
```

?

## Gap 6 --- Application → Owner

Existe identificação automática do responsável?

## Gap 7 --- Nova CVE

Quando surge uma vulnerabilidade depois do deploy, existe reavaliação
automática?

## Gap 8 --- Resposta

Depois de identificar o risco:

-   ticket é criado?
-   incidente é aberto?
-   owner é notificado?
-   SOC recebe alerta?
-   CSIRT participa?
-   SLA começa automaticamente?

## Gap 9 --- Governança

Existem políticas para:

-   componentes obsoletos;
-   versões antigas;
-   componentes proibidos;
-   licenças;
-   componentes internos;
-   exceções.

## Gap 10 --- Métricas

Existe medição de:

-   cobertura;
-   tempo de identificação;
-   tempo de resposta;
-   tempo de remediação;
-   reincidência;
-   exceptions/risk acceptance.

------------------------------------------------------------------------

# 17. MTTI --- Mean Time to Identify

Uma métrica importante proposta foi o **MTTI**.

Definição conceitual:

> Tempo entre a disponibilização/publicação de uma vulnerabilidade
> relevante e a identificação das aplicações/workloads/owners afetados.

Exemplo:

``` text
T0 — CVE publicada
T1 — ferramenta de segurança recebe a inteligência
T2 — componente afetado identificado
T3 — versões vulneráveis identificadas
T4 — SBOMs/artefatos afetados identificados
T5 — workloads produtivos afetados identificados
T6 — aplicação e owner identificados
```

Uma definição possível seria:

``` text
MTTI = T6 - T0
```

A definição final deve ser acordada pela organização.

O ponto importante é que MTTI não é apenas uma métrica de uma
ferramenta.

É uma métrica **end-to-end da arquitetura e do processo**.

Pode envolver:

-   AppSec;
-   DevSecOps;
-   Vulnerability Management;
-   Platform;
-   SOC;
-   CSIRT;
-   Application Teams.

------------------------------------------------------------------------

# 18. Outras métricas

Além de MTTI:

## MTTD

``` text
Mean Time to Detect
```

Quanto tempo até a organização detectar que existe um novo risco.

## MTTR

``` text
Mean Time to Remediate
```

Quanto tempo até a vulnerabilidade ser efetivamente corrigida.

## Coverage

Exemplos:

``` text
% repositories with SCA
% repositories with SBOM
% repositories with Dependabot
% artifacts continuously monitored
% production workloads mapped to SBOM
% workloads mapped to application
% applications mapped to owner
```

## Governança

``` text
% componentes fora da política
% componentes obsoletos
% componentes sem suporte
% vulnerabilidades críticas fora do SLA
% exceções de segurança
% risk acceptances vencidos
```

------------------------------------------------------------------------

# 19. Timeline completa para teste controlado

Foi proposta uma simulação para medir o processo real.

``` text
T0 — vulnerabilidade disponibilizada
T1 — security tooling recebe a informação
T2 — componente identificado
T3 — versão afetada identificada
T4 — SBOMs afetados identificados
T5 — artefatos/imagens afetados identificados
T6 — workloads afetados identificados
T7 — aplicação/owner identificados
T8 — ticket/incidente criado
T9 — correção validada
```

Para cada etapa registrar:

  Campo               Exemplo
  ------------------- ---------------------
  Timestamp           horário
  Tool                Mend / Xray / RHACS
  Team                VM / SOC / AppSec
  Action              identificação
  Result              aplicações afetadas
  Manual dependency   sim/não
  Elapsed time        minutos/horas

O objetivo é descobrir onde estão os gargalos.

------------------------------------------------------------------------

# 20. Teste de arquitetura recomendado

Executar um teste controlado utilizando uma biblioteca conhecida.

Objetivo:

> Simular o cenário em que uma nova vulnerabilidade é identificada em
> uma biblioteca já presente no ambiente.

Perguntas que o teste deve responder:

1.  A ferramenta detecta a nova vulnerabilidade?
2.  Quanto tempo leva?
3.  Quais SBOMs são encontrados?
4.  Quais artefatos são encontrados?
5.  Quais imagens são encontradas?
6.  Quais workloads estão rodando?
7.  Em quais clusters?
8.  Em ARO, AKS ou EKS?
9.  Quais aplicações são afetadas?
10. Quem são os owners?
11. O ticket é criado automaticamente?
12. O SOC é informado?
13. O CSIRT participa?
14. Existe SLA?
15. A correção pode ser validada automaticamente?

------------------------------------------------------------------------

# 21. Perguntas para o time de GitHub / DevSecOps

## Inventário

-   Quantos repositórios existem?
-   Quantos estão ativos?
-   Quantos representam aplicações?
-   Quantos são bibliotecas?
-   Quantos são IaC?
-   Quantos são templates/reusable workflows?

## Mend

-   Quantos repositórios executam Mend?
-   Existe configuração central?
-   Existe reusable workflow?
-   A análise pode ser removida por um time?
-   Existe bypass?
-   Qual política bloqueia pipeline?

## Dependabot

-   Quantos repositórios possuem Dependabot?
-   Security Updates estão habilitados?
-   Version Updates estão habilitados?
-   Existe configuração central?
-   Existem arquivos `.github/dependabot.yml`?
-   Existe configuração organizacional?
-   Como o GitHub Insights representa essa cobertura?

## SBOM

-   Quem gera?
-   Quando?
-   Qual formato?
-   Onde fica armazenado?
-   É associado ao build?
-   É associado ao artefato?
-   Existe histórico?

------------------------------------------------------------------------

# 22. Perguntas para o time de Mend

-   Quais produtos/módulos estão licenciados?
-   Qual cobertura?
-   Quais linguagens?
-   Dependências transitivas são identificadas?
-   O SBOM é gerado?
-   Qual formato?
-   SPDX?
-   CycloneDX?
-   Onde fica armazenado?
-   Existe histórico?
-   Existe API?
-   Existe reavaliação contínua quando novas CVEs surgem?
-   Existe política para componente obsoleto?
-   Existe política para versão proibida?
-   Existe política de licença?
-   Existe allowlist/denylist?
-   É possível tratar componentes internos/proprietários?
-   Como esses componentes são identificados?
-   Existe integração com GitHub?
-   Existe geração automática de PR?
-   Existe integração com Artifactory?
-   Existe integração com ticketing/VM?
-   Existe identificação de application owner?

------------------------------------------------------------------------

# 23. Perguntas para Artifactory / Xray

-   Todos os artefatos passam pelo Artifactory?
-   Existem registries externos utilizados diretamente?
-   Todas as imagens passam pelo registry corporativo?
-   Xray está habilitado?
-   Qual cobertura?
-   Existe análise periódica?
-   Existe reavaliação quando uma nova CVE aparece?
-   Quanto tempo leva?
-   Existe SBOM associado ao artefato?
-   É possível consultar:
    -   componente;
    -   versão;
    -   artefato;
    -   aplicação?
-   Existe política de bloqueio?
-   Existe quarentena?
-   Existe promoção de artefatos?
-   Como saber se um artefato vulnerável está em produção?
-   Existe integração com RHACS?
-   Existe integração com VM?

------------------------------------------------------------------------

# 24. Perguntas para RHACS / Runtime Security

-   RHACS cobre ARO?
-   RHACS cobre AKS?
-   RHACS cobre EKS?
-   Qual percentual dos clusters?
-   Qual percentual dos workloads?
-   É possível identificar a imagem?
-   Digest?
-   Tag?
-   Registry?
-   Artifactory?
-   É possível identificar vulnerabilidades da imagem?
-   Existe correlação com SBOM?
-   Existe correlação com aplicação?
-   Existe correlação com owner?
-   Existe integração com CMDB?
-   Existe integração com SOC?
-   Existe integração com CSIRT?
-   Alertas críticos geram incidentes automaticamente?

------------------------------------------------------------------------

# 25. Perguntas para Vulnerability Management

-   Qual é a fonte oficial de vulnerabilidades?
-   Como novas CVEs são recebidas?
-   Existe threat/vulnerability intelligence?
-   Existe priorização por CVSS?
-   Existe priorização por exploitability?
-   Existe EPSS?
-   Existe contexto de runtime?
-   Existe contexto de exposição?
-   Existe contexto de criticidade da aplicação?
-   Como o owner é identificado?
-   Existe SLA?
-   Existe ticket automático?
-   Como exceções são controladas?
-   Como risk acceptance é controlado?
-   Existe MTTD?
-   Existe MTTI?
-   Existe MTTR?

------------------------------------------------------------------------

# 26. Perguntas para SOC / CSIRT

-   Quais vulnerabilidades viram alertas?
-   Quais vulnerabilidades viram incidentes?
-   Qual é o critério?
-   CVE crítica automaticamente gera incidente?
-   Existe integração com RHACS?
-   Existe integração com Xray?
-   Existe integração com Mend?
-   Existe automação?
-   Como o owner é localizado?
-   Existe SLA?
-   O tempo de resposta é medido?
-   Existe playbook para vulnerabilidade crítica?
-   Existe playbook para zero-day?

------------------------------------------------------------------------

# 27. Modelo de maturidade sugerido

## Nível 1 --- Pipeline Security

``` text
SCA durante build
```

Capacidade limitada a detectar vulnerabilidades conhecidas naquele
momento.

## Nível 2 --- Component Inventory

``` text
SCA + SBOM
```

A organização passa a possuir inventário estruturado.

## Nível 3 --- Continuous Vulnerability Monitoring

``` text
SCA
+
SBOM
+
Artifact scanning
```

Novas vulnerabilidades podem ser correlacionadas com artefatos
existentes.

## Nível 4 --- Runtime Correlation

``` text
CVE
 ↓
Component
 ↓
Artifact
 ↓
Workload
```

A organização sabe o que está efetivamente executando.

## Nível 5 --- Enterprise Software Component Governance

``` text
CVE
 ↓
Component
 ↓
Artifact
 ↓
Workload
 ↓
Application
 ↓
Owner
 ↓
Incident
 ↓
Remediation
 ↓
Validation
```

Nesse estágio existe governança ponta a ponta.

------------------------------------------------------------------------

# 28. Supply Chain Security

O discovery pode ser posicionado em um contexto mais amplo de:

> **Continuous Software Supply Chain Security**

Controles complementares podem envolver:

``` text
Source
 ↓
Branch Protection
 ↓
CODEOWNERS
 ↓
Dependency Governance
 ↓
SCA
 ↓
SBOM
 ↓
Secrets
 ↓
SAST
 ↓
IaC Scan
 ↓
Container Scan
 ↓
Artifact Repository
 ↓
Artifact Scanning
 ↓
Signing / Provenance / Attestation
 ↓
Deployment
 ↓
Runtime Security
 ↓
Continuous Vulnerability Monitoring
```

O foco atual, entretanto, é principalmente **SCA + SBOM + Component
Governance + Runtime Correlation**.

------------------------------------------------------------------------

# 29. Mensagens executivas importantes

Mensagem principal:

> **O objetivo não é simplesmente verificar se temos SCA. É determinar
> se temos uma capacidade completa de gestão do risco de componentes de
> software, desde o desenvolvimento até o runtime.**

Outra mensagem:

> **Quando uma nova vulnerabilidade é descoberta, precisamos conseguir
> sair de "existe uma CVE" para "estas são as aplicações e workloads
> afetados, estes são os owners e este é o processo de remediação", com
> tempo mensurável.**

Outra:

> **SCA na pipeline é um controle preventivo importante, mas não resolve
> sozinho o risco de vulnerabilidades descobertas depois que o software
> já está em produção.**

Outra:

> **SBOM não deve ser tratado apenas como um arquivo gerado por
> compliance. Ele deve fazer parte da rastreabilidade do software.**

Outra:

> **O problema não é apenas detectar vulnerabilidades. O problema é
> identificar impacto, contexto, ownership e responder rapidamente.**

------------------------------------------------------------------------

# 30. Estrutura sugerida para apresentação

## Slide 1 --- Título

**SCA & Software Component Governance**

Subtítulo:

**Discovery de Arquitetura --- Da Pipeline ao Runtime**

------------------------------------------------------------------------

## Slide 2 --- Por que estamos fazendo o discovery?

Mostrar a mudança de perspectiva:

``` text
“Temos SCA?”
      ↓
“Conseguimos gerenciar continuamente o risco dos componentes de software?”
```

------------------------------------------------------------------------

## Slide 3 --- Current State / AS-IS

Representar:

``` text
GitHub
 ↓
Mend / Dependabot
 ↓
Pipeline
 ↓
SBOM
 ↓
Artifactory / Xray
 ↓
ARO / AKS / EKS
 ↓
RHACS
 ↓
VM / SOC / CSIRT
```

Marcar integrações ainda não confirmadas como **A VALIDAR**.

------------------------------------------------------------------------

## Slide 4 --- O problema do SCA somente na pipeline

Usar uma timeline:

``` text
Day 1
Dependency X v1.2
 ↓
SCA = OK
 ↓
Production

Day 30
New Critical CVE
 ↓
Who is affected?
```

------------------------------------------------------------------------

## Slide 5 --- Pergunta crítica

Destacar visualmente:

> **Se uma CVE crítica for publicada amanhã, conseguimos identificar
> automaticamente todos os workloads produtivos afetados?**

------------------------------------------------------------------------

## Slide 6 --- Gaps de arquitetura

Exemplo:

``` text
Coverage
SBOM
Artifact Correlation
Runtime Correlation
Application Mapping
Ownership
Continuous Monitoring
Response
Metrics
```

------------------------------------------------------------------------

## Slide 7 --- SCA + SBOM + Runtime

Explicar:

``` text
SCA
What is vulnerable?

SBOM
What do we have?

Artifact Repository
What was built?

Runtime
What is running?

Governance
Who owns it and what do we do?
```

------------------------------------------------------------------------

## Slide 8 --- Software Component Governance

Mostrar que a governança não trata apenas CVEs:

``` text
Vulnerable
Obsolete
Unsupported
Prohibited
License Risk
Malicious
Internal
```

------------------------------------------------------------------------

## Slide 9 --- Arquitetura TO-BE

Mostrar:

``` text
CVE
 ↓
Component
 ↓
SBOM
 ↓
Artifact
 ↓
Runtime
 ↓
Application
 ↓
Owner
 ↓
Response
 ↓
Remediation
```

------------------------------------------------------------------------

## Slide 10 --- Métricas

Destacar:

``` text
MTTD
MTTI
MTTR
Coverage
```

Principal métrica proposta:

> **MTTI --- Mean Time to Identify**

------------------------------------------------------------------------

## Slide 11 --- Controlled Test

Mostrar:

``` text
T0 CVE
 ↓
T1 Detect
 ↓
T2 Component
 ↓
T3 SBOM
 ↓
T4 Artifact
 ↓
T5 Runtime
 ↓
T6 Application
 ↓
T7 Owner
 ↓
T8 Incident
 ↓
T9 Remediation
```

------------------------------------------------------------------------

## Slide 12 --- Next Steps

Exemplo:

``` text
1. Mapear cobertura
2. Confirmar ferramentas e integrações
3. Identificar source of truth
4. Validar SBOM
5. Validar artifact correlation
6. Validar runtime correlation
7. Executar teste controlado
8. Medir MTTI
9. Identificar gaps
10. Definir arquitetura TO-BE
11. Criar roadmap
```

------------------------------------------------------------------------

# 31. Informações que precisam ser coletadas na empresa

Para que a decisão seja consistente, levantar números concretos.

## GitHub

``` text
Total repositories
Active repositories
Repositories with Mend
Repositories with SBOM
Repositories with Dependabot
Repositories using reusable security workflows
```

## Pipeline

``` text
% pipelines with SCA
% pipelines with security gate
% pipelines that can bypass the gate
Number of exceptions
```

## SBOM

``` text
Total SBOMs
Coverage %
Formats
Storage
Retention
Versioning
Artifact association %
```

## Artifactory/Xray

``` text
Total artifacts
Artifacts scanned %
Repositories covered %
Images scanned %
Continuous re-evaluation enabled?
Time to identify new CVE
```

## Runtime

``` text
Total clusters
ARO clusters
AKS clusters
EKS clusters
Clusters covered by RHACS %
Workloads covered %
Images correlated with Artifactory %
```

## Application Mapping

``` text
Workloads mapped to application %
Applications mapped to owner %
```

## Vulnerability Management

``` text
Critical vulnerabilities
Critical vulnerabilities outside SLA
MTTD
MTTI
MTTR
Number of exceptions
Risk acceptances
```

------------------------------------------------------------------------

# 32. Hipóteses a validar

Não apresentar as seguintes hipóteses como fatos antes do discovery:

1.  Xray está habilitado em todos os repositórios.
2.  Xray faz reavaliação contínua de todos os artefatos.
3.  Mend monitora continuamente todos os projetos depois do build.
4.  Todo repositório gera SBOM.
5.  SBOM está associado ao artefato.
6.  Existe um único source of truth para SBOM.
7.  Dependabot possui cobertura corporativa.
8.  RHACS cobre todos os clusters.
9.  RHACS consegue correlacionar workload com aplicação.
10. Existe correlação automática Artifactory → Runtime.
11. Existe owner automático para todo workload.
12. SOC/CSIRT recebe automaticamente novas vulnerabilidades críticas.
13. Existe SLA end-to-end.
14. MTTI já é medido.
15. As duas soluções de SBOM são redundantes.

Tudo isso deve ser tratado como:

> **A VALIDAR DURANTE O DISCOVERY**

------------------------------------------------------------------------

# 33. Resultado esperado do discovery

Ao final, a organização deve conseguir responder com evidências:

``` text
1. O que temos?
2. Onde está?
3. Qual a cobertura?
4. Quem analisa?
5. Quem é responsável?
6. O que acontece quando surge uma nova CVE?
7. Quanto tempo levamos para identificar impacto?
8. Quanto tempo levamos para corrigir?
9. Quais gaps existem?
10. Qual arquitetura precisamos construir?
```

------------------------------------------------------------------------

# 34. Resultado arquitetural desejado

O objetivo final pode ser resumido assim:

``` text
PREVENT
   ↓
INVENTORY
   ↓
CONTINUOUSLY DETECT
   ↓
IDENTIFY
   ↓
CORRELATE
   ↓
PRIORITIZE
   ↓
RESPOND
   ↓
REMEDIATE
   ↓
VALIDATE
```

Com rastreabilidade:

``` text
Repository
   ↓
Dependency
   ↓
SBOM
   ↓
Artifact
   ↓
Image
   ↓
Deployment
   ↓
Workload
   ↓
Application
   ↓
Owner
```

E capacidade de reação:

``` text
New CVE
   ↓
Affected Component
   ↓
Affected Production
   ↓
Owner
   ↓
Incident
   ↓
Remediation
   ↓
Validation
```

------------------------------------------------------------------------

# 35. Orientação para a IA que gerar a apresentação

Ao utilizar este documento como contexto, gerar uma apresentação que
tenha dois níveis simultaneamente:

**Executivo:** risco, impacto, cobertura, governança, métricas,
ownership, gaps e roadmap.

**Arquitetura Cyber Security:** GitHub, Dependabot, Mend, SBOM,
Artifactory/Xray, RHACS, ARO/AKS/EKS, Vulnerability Management,
SOC/CSIRT e correlação ponta a ponta.

Priorizar recursos visuais:

-   diagramas;
-   fluxos;
-   timelines;
-   capability maps;
-   arquitetura AS-IS;
-   arquitetura TO-BE;
-   heatmap de gaps;
-   KPIs;
-   fluxo de zero-day;
-   roadmap.

Evitar uma apresentação excessivamente textual.

A narrativa central deve ser:

``` text
SCA na pipeline
      ↓
não é suficiente sozinho
      ↓
precisamos de inventário
      ↓
SBOM
      ↓
monitoramento contínuo
      ↓
artifact intelligence
      ↓
runtime correlation
      ↓
application + owner
      ↓
response
      ↓
remediation
      ↓
mensuração
```

A apresentação não deve assumir como implementadas capacidades ainda não
confirmadas. Sempre separar:

``` text
CONFIRMADO
A VALIDAR
GAP IDENTIFICADO
TO-BE PROPOSTO
```

------------------------------------------------------------------------

# 36. Frase de fechamento sugerida

> **A maturidade de SCA não deve ser medida apenas pela capacidade de
> bloquear uma vulnerabilidade durante o build, mas pela capacidade de
> identificar, correlacionar e responder continuamente ao risco de
> componentes de software durante todo o ciclo de vida da aplicação.**
