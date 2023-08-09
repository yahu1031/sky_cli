// To parse this JSON data, do
//
//     final lockMap = lockMapFromJson(jsonString);

import 'dart:convert';

LockMap lockMapFromJson(String str) =>
    LockMap.fromJson(json.decode(str) as Map<String, dynamic>);

String lockMapToJson(LockMap data) => json.encode(data.toJson());

class LockMap {
  LockMap({
    required this.packages,
    required this.sdks,
  });

  factory LockMap.fromJson(Map<String, dynamic> json) => LockMap(
        packages:
            Map<String, dynamic>.from(json['packages'] as Map<String, dynamic>)
                .map(
          (k, v) => MapEntry<String, Package>(
            k,
            Package.fromJson(v as Map<String, dynamic>),
          ),
        ),
        sdks: Sdks.fromJson(json['sdks'] as Map<String, dynamic>),
      );
  Map<String, Package> packages;
  Sdks sdks;

  Map<String, dynamic> toJson() => {
        'packages': Map<String, dynamic>.from(packages).map(
          (k, v) => MapEntry<String, dynamic>(k, (v as Package).toJson()),
        ),
        'sdks': sdks.toJson(),
      };
}

class Package {
  Package({
    required this.dependency,
    required this.description,
    required this.source,
    required this.version,
  });

  factory Package.fromJson(Map<String, dynamic> json) => Package(
        dependency: dependencyValues.map[json['dependency']]!,
        description: Description.fromJson(
          json['description'] is String
              ? {'name': json['description']}
              : json['description'] as Map<String, dynamic>,
        ),
        source: sourceValues.map[json['source']]!,
        version: json['version'] as String,
      );
  Dependency dependency;
  Description description;
  Source source;
  String version;

  Map<String, dynamic> toJson() => {
        'dependency': dependencyValues.reverse[dependency],
        'description': description.toJson(),
        'source': sourceValues.reverse[source],
        'version': version,
      };
}

enum Dependency { directDev, directMain, transitive, directOverridden }

final dependencyValues = EnumValues({
  'direct dev': Dependency.directDev,
  'direct main': Dependency.directMain,
  'direct overridden': Dependency.directOverridden,
  'transitive': Dependency.transitive
});

class Description {
  Description({
    required this.name,
    required this.sha256,
    required this.url,
  });

  factory Description.fromJson(Map<String, dynamic> json) => Description(
        name: json['name'] as String?,
        sha256: json['sha256'] as String?,
        url: json['url'] as String?,
      );
  String? name;
  String? sha256;
  String? url;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sha256': sha256,
        'url': url,
      };
}

enum Source { hosted, sdk }

final sourceValues = EnumValues(
  {
    'hosted': Source.hosted,
    'sdk': Source.sdk,
  },
);

class Sdks {
  Sdks({
    required this.dart,
  });

  factory Sdks.fromJson(Map<String, dynamic> json) => Sdks(
        dart: json['dart'] as String,
      );
  String dart;

  Map<String, dynamic> toJson() => {
        'dart': dart,
      };
}

class EnumValues<T> {
  EnumValues(this.map);
  Map<String, T> map;

  Map<T, String> get reverse => map.map((k, v) => MapEntry(v, k));
}
