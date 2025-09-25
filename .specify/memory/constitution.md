<!--
Sync Impact Report:
- Version change: 1.0.0 → 2.0.0
- List of modified principles:
  - `PROPÓSITO (NÃO-NEGOCIÁVEL)` → `PROPÓSITO (NÃO-NEGOCIÁVEL)` (rephrased)
  - `ESCOPO (ALTA PRIORIDADE)` → `ESCOPO (NÃO-NEGOCIÁVEL)` (content replaced with syllabus)
- Removed sections:
  - `FORA DE ESCOPO (NÃO-NEGOCIÁVEL)`
  - `LICENÇAS & CONFORMIDADE`
  - `UI/UX & ACESSIBILIDADE`
  - `PADRÕES DE CÓDIGO & FERRAMENTAS (NÃO-NEGOCIÁVEL)`
  - `REPRODUTIBILIDADE & RASTREABILIDADE`
  - `Governance`
- Templates requiring updates:
  - `.specify/templates/plan-template.md` (⚠ pending)
  - `.specify/templates/spec-template.md` (⚠ pending)
- Follow-up TODOs: None
-->
# JFlutter Constitution

## Core Principles

### PROPÓSITO (NÃO-NEGOCIÁVEL)
JFlutter é um port moderno (Flutter, mobile-first) do JFLAP para ensino de teoria da computação, focado em construção, simulação e transformação de autômatos, gramáticas, e Máquinas de Turing, com foco acadêmico/educacional.

### ESCOPO (NÃO-NEGOCIÁVEL)
O escopo do aplicativo não deve exceder a ementa da disciplina de Fundamentos Teóricos da Computação:

**Ementa:** Linguagens. Expressões regulares. Gramáticas. Autômatos. Máquinas de Turing. Hierarquia de Chomsky. Decidibilidade.

**Objetivos:**
- Levar o aluno a construir conhecimentos sobre linguagens formais, autômatos e gramáticas.
- Levar o aluno a construir conhecimentos sobre os fundamentos teóricos da computação.
- Permitir que o aluno diferencie problemas decidíveis e indecidíveis.

**UNIDADE 1- Nivelamento e Conceitos Básicos (10 ha):**
1.1. Conceitos matemáticos preliminares.
1.2. Alfabetos, sentenças e linguagens.
1.3. Operações com linguagens.
1.4. Expressôes regulares (ER).

**UNIDADE 2 - Autômatos Finitos e Linguagens Regulares (24 ha):**
2.1. Máquinas de estado finito: reconhecedores e transdutores.
2.2. Autômatos finitos (AF).
2.2.1.Autômato finito determinístico (AFD).
2.2.2. Autômato finito não-determinístico (AFN).
2.2.3. Autômato finito não-determ. com transição-lambda (AFN-L).
2.2.4. Conversão de autômatos: AFNL -> AFN -> AFD.
2.3. Linguagens Regulares (LReg).
2.4. Gramáticas lineares e gramáticas regulares (GRJ).
2.5. Conversão de GR em AF / Conversão de AF em GR.
2.6. Conversão de ER em AF / Conversão de AF em ER.
2.7. Propriedades de fechamento das LRegs.
2.8. Lema do bombeamento para LRegs.

**UNIDADE 3 - Autômatos com Pilha e Linguagens Livres de Contexto (20 ha):**
3.1. Introdução.
3.2. Autômatos com pilha (AP).
3.2.1. Autômato com pilha determinístico (APD).
3.2.2. Autômato com pilha não-determinístico (APN).
3.3. Linguagens Livres de Contexto (LLC).
3.4. Gramáticas livres de contexto (GLC).
3.4.1. Árvore de derivação e ambiguidade.
3.4.2. Conversão de GLC em AP / Conversão de AP em GLC.
3.4.3. Introdução à formas normais - Forma Normal de Chomsky.
3.5. Propriedades de fechamento das LLCs.
3.6. Lema do bombeamento para LLCs.

**UNIDADE 4 - Máquinas de Turing e suas Linguagens (14 ha):**
4.1. Introdução.
4.2. Máquidas de Turing (MT).
4.2.1.Máquina de Turing determinística (MTD).
4.2.2 Máquina de Turing não-determinística (MTN).
4.2.3 Variações das máquinas de Turing.
4.3. Linguagens reconhecidas por uma MT.
4.3.1. Linguagens recursivamente enumeráveis (LRE).
4.3.2. Linguagens recursivas (LRec).
4.4. Gramáticas irrestrita (GI).
4.4.1. Equivalência entre GIs e LREs.
4.5. Propriedades de fechamento das LREs e LRecs.
4.6. Autômato linearmente limitado (ALL).
4.6.1. Gramáticas sensíveis ao contexto (GSC).
4.6.2. Linguagens sensíveis ao contexto (LSC).
4.7. Hierarquia de Chomsky.

## Governance

**Version**: 2.0.0 | **Ratified**: 2025-09-24 | **Last Amended**: 2025-09-24