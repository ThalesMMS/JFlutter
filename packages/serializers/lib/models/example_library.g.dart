// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExampleLibraryImpl _$$ExampleLibraryImplFromJson(Map<String, dynamic> json) =>
    _$ExampleLibraryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => ExampleCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>,
      author: json['author'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ExampleLibraryImplToJson(
        _$ExampleLibraryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'categories': instance.categories,
      'metadata': instance.metadata,
      'author': instance.author,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$ExampleCategoryImpl _$$ExampleCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ExampleCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      examples: (json['examples'] as List<dynamic>)
          .map((e) => AutomatonExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: $enumDecode(_$ExampleDifficultyEnumMap, json['difficulty']),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      icon: json['icon'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ExampleCategoryImplToJson(
        _$ExampleCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'examples': instance.examples,
      'difficulty': _$ExampleDifficultyEnumMap[instance.difficulty]!,
      'tags': instance.tags,
      'icon': instance.icon,
      'metadata': instance.metadata,
    };

const _$ExampleDifficultyEnumMap = {
  ExampleDifficulty.beginner: 'beginner',
  ExampleDifficulty.intermediate: 'intermediate',
  ExampleDifficulty.advanced: 'advanced',
  ExampleDifficulty.expert: 'expert',
};

_$AutomatonExampleImpl _$$AutomatonExampleImplFromJson(
        Map<String, dynamic> json) =>
    _$AutomatonExampleImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ExampleTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      testCases:
          (json['testCases'] as List<dynamic>).map((e) => e as String).toList(),
      expectedResults: (json['expectedResults'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hint: json['hint'] as String?,
      solution: json['solution'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      difficulty: $enumDecode(_$ExampleDifficultyEnumMap, json['difficulty']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$AutomatonExampleImplToJson(
        _$AutomatonExampleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$ExampleTypeEnumMap[instance.type]!,
      'data': instance.data,
      'testCases': instance.testCases,
      'expectedResults': instance.expectedResults,
      'hint': instance.hint,
      'solution': instance.solution,
      'tags': instance.tags,
      'difficulty': _$ExampleDifficultyEnumMap[instance.difficulty]!,
      'metadata': instance.metadata,
    };

const _$ExampleTypeEnumMap = {
  ExampleType.finiteAutomaton: 'finite_automaton',
  ExampleType.pushdownAutomaton: 'pushdown_automaton',
  ExampleType.turingMachine: 'turing_machine',
  ExampleType.contextFreeGrammar: 'context_free_grammar',
  ExampleType.regularExpression: 'regular_expression',
  ExampleType.algorithmDemo: 'algorithm_demo',
  ExampleType.conversionDemo: 'conversion_demo',
};

_$ExampleTestCaseImpl _$$ExampleTestCaseImplFromJson(
        Map<String, dynamic> json) =>
    _$ExampleTestCaseImpl(
      input: json['input'] as String,
      expectedAccept: json['expectedAccept'] as bool,
      expectedOutput: json['expectedOutput'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ExampleTestCaseImplToJson(
        _$ExampleTestCaseImpl instance) =>
    <String, dynamic>{
      'input': instance.input,
      'expectedAccept': instance.expectedAccept,
      'expectedOutput': instance.expectedOutput,
      'description': instance.description,
      'metadata': instance.metadata,
    };

_$ExampleSearchOptionsImpl _$$ExampleSearchOptionsImplFromJson(
        Map<String, dynamic> json) =>
    _$ExampleSearchOptionsImpl(
      query: json['query'] as String?,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ExampleTypeEnumMap, e))
          .toList(),
      difficulties: (json['difficulties'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ExampleDifficultyEnumMap, e))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      category: json['category'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ExampleSearchOptionsImplToJson(
        _$ExampleSearchOptionsImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'types': instance.types?.map((e) => _$ExampleTypeEnumMap[e]!).toList(),
      'difficulties': instance.difficulties
          ?.map((e) => _$ExampleDifficultyEnumMap[e]!)
          .toList(),
      'tags': instance.tags,
      'category': instance.category,
      'limit': instance.limit,
      'offset': instance.offset,
    };

_$ExampleSearchResultImpl _$$ExampleSearchResultImplFromJson(
        Map<String, dynamic> json) =>
    _$ExampleSearchResultImpl(
      examples: (json['examples'] as List<dynamic>)
          .map((e) => AutomatonExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      hasMore: json['hasMore'] as bool,
    );

Map<String, dynamic> _$$ExampleSearchResultImplToJson(
        _$ExampleSearchResultImpl instance) =>
    <String, dynamic>{
      'examples': instance.examples,
      'totalCount': instance.totalCount,
      'offset': instance.offset,
      'limit': instance.limit,
      'hasMore': instance.hasMore,
    };
