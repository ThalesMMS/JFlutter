# Índice de estruturas e algoritmos do repositório `dart-petitparser-examples-main`

## Visão geral
Este projeto oferece coleções completas de gramáticas e avaliadores para diversas linguagens e formatos, construídas com PetitParser.
O índice abaixo destaca os principais módulos, suas estruturas de dados e algoritmos de parsing/avaliação que podemos reaproveitar no JFlutter.

## Gramáticas e avaliadores específicos

### BibTeX
- `BibTeXDefinition` implementa a gramática de arquivos BibTeX, cobrindo entradas, campos, strings entre aspas/chaves e regras de tokenização.【F:References/dart-petitparser-examples-main/lib/src/bibtex/definition.dart†L6-L87】
- `BibTeXEntry` modela cada entrada com tipo, chave e mapa de campos, oferecendo `toString` formatado.【F:References/dart-petitparser-examples-main/lib/src/bibtex/model.dart†L3-L25】

### JSON
- `JsonDefinition` define a gramática completa do JSON (objetos, arrays, strings, números e literais boolean/null).【F:References/dart-petitparser-examples-main/lib/src/json/definition.dart†L7-L80】
- `jsonEscapeChars` centraliza o mapeamento de caracteres de escape e `JSON` descreve o tipo composto usado no parser.【F:References/dart-petitparser-examples-main/lib/src/json/encoding.dart†L1-L11】【F:References/dart-petitparser-examples-main/lib/src/json/types.dart†L1-L2】
- `parseJson` disponibiliza um conversor pronto de `String` para a árvore JSON tipada.【F:References/dart-petitparser-examples-main/lib/json.dart†L9-L31】

### Matemática (expressões aritméticas)
- Estruturas AST (`Expression`, `Value`, `Variable`, `Application`) encapsulam avaliação com ambiente de variáveis e funções.【F:References/dart-petitparser-examples-main/lib/src/math/ast.dart†L1-L39】
- `common.dart` lista constantes e funções matemáticas (unárias e binárias) reutilizáveis.【F:References/dart-petitparser-examples-main/lib/src/math/common.dart†L1-L26】
- O builder `parser` monta uma gramática de expressões com precedência, suporte a chamadas de função e operadores prefixados/infixados.【F:References/dart-petitparser-examples-main/lib/src/math/parser.dart†L8-L86】

### LISP
- `Cons` implementa a célula básica de listas, com utilitários de navegação e impressão.【F:References/dart-petitparser-examples-main/lib/src/lisp/cons.dart†L1-L54】
- `Environment` provê encadeamento lexical de bindings com atualização e definição dinâmica.【F:References/dart-petitparser-examples-main/lib/src/lisp/environment.dart†L1-L43】
- As funções `eval`, `evalList` e `evalArguments` suportam avaliação recursiva, aplicação de funções e avaliação de listas.【F:References/dart-petitparser-examples-main/lib/src/lisp/evaluator.dart†L9-L37】
- `StandardEnvironment` carrega uma biblioteca padrão escrita em LISP, incluindo algoritmos clássicos de listas como `length`, `append`, `map` e `inject`.【F:References/dart-petitparser-examples-main/lib/src/lisp/standard.dart†L5-L65】

### Prolog
- `PrologGrammarDefinition` descreve regras, termos, parâmetros e tokens, incluindo suporte a comentários e trim automático.【F:References/dart-petitparser-examples-main/lib/src/prolog/grammar.dart†L4-L52】
- `PrologParserDefinition` transforma a gramática em objetos `Rule`, `Term` e `Variable`, compartilhando escopo de variáveis por regra.【F:References/dart-petitparser-examples-main/lib/src/prolog/parser.dart†L7-L48】
- O núcleo avaliador (`Database`, `Rule`, `Term`, `Conjunction`) fornece unificação, fusão de bindings e resolução recursiva de consultas Prolog.【F:References/dart-petitparser-examples-main/lib/src/prolog/evaluator.dart†L7-L247】

### Expressões Regulares
- `nodeParser` usa `ExpressionBuilder` para gerar a AST de regex com literais, agrupamentos, quantificadores e operadores (concatenação, alternância, interseção, complemento).【F:References/dart-petitparser-examples-main/lib/src/regexp/parser.dart†L7-L45】
- Hierarquia de `Node` traduz regex para autômatos (`EmptyNode`, `DotNode`, `LiteralNode`, `ConcatenationNode`, `AlternationNode`, `QuantificationNode`, etc.).【F:References/dart-petitparser-examples-main/lib/src/regexp/node.dart†L4-L218】
- `Nfa` implementa o algoritmo de Thompson para simular um autômato finito não determinístico com transições epsilon e curingas.【F:References/dart-petitparser-examples-main/lib/src/regexp/nfa.dart†L4-L52】
- `RegexpPattern` integra a simulação com a interface `Pattern` de Dart, expondo buscas por prefixo e todas as correspondências.【F:References/dart-petitparser-examples-main/lib/src/regexp/pattern.dart†L1-L35】

### Smalltalk
- A AST (`MethodNode`, `SequenceNode`, `ReturnNode`, `MessageNode`, etc.) modela métodos, cascatas, blocos e literais conforme a gramática Smalltalk.【F:References/dart-petitparser-examples-main/lib/src/smalltalk/ast.dart†L1-L128】
- `Visitor` define o padrão de visita para percorrer a AST e processar nós específicos.【F:References/dart-petitparser-examples-main/lib/src/smalltalk/visitor.dart†L1-L55】
- `objects.dart` fornece estruturas de runtime (comportamentos, classes nativas) e uma função `bootstrap` que registra métodos padrões para tipos centrais como números, strings e booleanos.【F:References/dart-petitparser-examples-main/lib/src/smalltalk/objects.dart†L1-L83】

### Linguagens adicionais
- `DartGrammarDefinition` implementa tokens, palavras-chave e produções completas da linguagem Dart segundo a especificação ECMA-408.【F:References/dart-petitparser-examples-main/lib/src/dart/grammar.dart†L3-L159】
- `PascalGrammarDefinition` cobre programas, blocos, declarações, controle de fluxo e estrutura de dados da linguagem Pascal clássica.【F:References/dart-petitparser-examples-main/lib/src/pascal/grammar.dart†L1-L160】

### Parsers utilitários
- `TabularDefinition` permite construir parsers CSV/TSV parametrizáveis, controlando aspas, escapes e delimitadores de linha/coluna.【F:References/dart-petitparser-examples-main/lib/tabular.dart†L1-L76】
- O parser `uri` decompoõe URIs conforme RFC 3986 e reusa sub-parsers para autoridade (usuário/senha/host/porta) e query string (pares chave/valor).【F:References/dart-petitparser-examples-main/lib/uri.dart†L1-L29】【F:References/dart-petitparser-examples-main/lib/src/uri/authority.dart†L1-L21】【F:References/dart-petitparser-examples-main/lib/src/uri/query.dart†L1-L17】

