import 'package:freezed_annotation/freezed_annotation.dart';

part 'package_api.freezed.dart';
part 'package_api.g.dart';

/// API definition for package integration and playground
@freezed
class PackageAPI with _$PackageAPI {
  const factory PackageAPI({
    required String packageName,
    required String version,
    required String description,
    required List<APIMethod> methods,
    required List<APIType> types,
    required Map<String, dynamic> metadata,
    String? documentation,
    String? repository,
    List<String>? dependencies,
  }) = _PackageAPI;

  factory PackageAPI.fromJson(Map<String, dynamic> json) =>
      _$PackageAPIFromJson(json);
}

/// API method definition
@freezed
class APIMethod with _$APIMethod {
  const factory APIMethod({
    required String name,
    required String description,
    required String returnType,
    required List<APIParameter> parameters,
    required bool isAsync,
    required bool isStatic,
    String? example,
    Map<String, dynamic>? metadata,
  }) = _APIMethod;

  factory APIMethod.fromJson(Map<String, dynamic> json) =>
      _$APIMethodFromJson(json);
}

/// API parameter definition
@freezed
class APIParameter with _$APIParameter {
  const factory APIParameter({
    required String name,
    required String type,
    required bool isRequired,
    String? defaultValue,
    String? description,
    Map<String, dynamic>? metadata,
  }) = _APIParameter;

  factory APIParameter.fromJson(Map<String, dynamic> json) =>
      _$APIParameterFromJson(json);
}

/// API type definition
@freezed
class APIType with _$APIType {
  const factory APIType({
    required String name,
    required String description,
    required APITypeKind kind,
    required List<APIField> fields,
    String? baseType,
    Map<String, dynamic>? metadata,
  }) = _APIType;

  factory APIType.fromJson(Map<String, dynamic> json) =>
      _$APITypeFromJson(json);
}

/// API field definition
@freezed
class APIField with _$APIField {
  const factory APIField({
    required String name,
    required String type,
    required bool isRequired,
    String? description,
    String? defaultValue,
    Map<String, dynamic>? metadata,
  }) = _APIField;

  factory APIField.fromJson(Map<String, dynamic> json) =>
      _$APIFieldFromJson(json);
}

/// API type kinds
enum APITypeKind {
  @JsonValue('class')
  class_,
  @JsonValue('interface')
  interface,
  @JsonValue('enum')
  enum_,
  @JsonValue('union')
  union,
  @JsonValue('primitive')
  primitive,
}

/// API integration result
@freezed
class APIIntegrationResult with _$APIIntegrationResult {
  const factory APIIntegrationResult({
    required bool success,
    required String packageName,
    required List<String> availableMethods,
    required List<String> availableTypes,
    String? error,
    Map<String, dynamic>? metadata,
  }) = _APIIntegrationResult;

  factory APIIntegrationResult.fromJson(Map<String, dynamic> json) =>
      _$APIIntegrationResultFromJson(json);
}

/// Playground execution context
@freezed
class PlaygroundContext with _$PlaygroundContext {
  const factory PlaygroundContext({
    required String sessionId,
    required List<PackageAPI> availablePackages,
    required Map<String, dynamic> variables,
    required List<String> imports,
    String? currentPackage,
    Map<String, dynamic>? metadata,
  }) = _PlaygroundContext;

  factory PlaygroundContext.fromJson(Map<String, dynamic> json) =>
      _$PlaygroundContextFromJson(json);
}

/// Playground execution result
@freezed
class PlaygroundResult with _$PlaygroundResult {
  const factory PlaygroundResult({
    required bool success,
    required String output,
    String? error,
    required Map<String, dynamic> metadata,
    required DateTime timestamp,
  }) = _PlaygroundResult;

  factory PlaygroundResult.fromJson(Map<String, dynamic> json) =>
      _$PlaygroundResultFromJson(json);
}
