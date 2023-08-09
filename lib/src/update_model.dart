class VersionsData {
  VersionsData({
    required this.url,
    required this.assetsUrl,
    required this.uploadUrl,
    required this.htmlUrl,
    required this.id,
    required this.author,
    required this.nodeId,
    required this.tagName,
    required this.targetCommitish,
    required this.name,
    required this.draft,
    required this.prerelease,
    required this.createdAt,
    required this.publishedAt,
    required this.assets,
    required this.tarballUrl,
    required this.zipballUrl,
    required this.body,
  });
  factory VersionsData.fromJson(Map<String, dynamic> json) => VersionsData(
        url: json['url'] as String,
        assetsUrl: json['assets_url'] as String,
        uploadUrl: json['upload_url'] as String,
        htmlUrl: json['html_url'] as String,
        id: json['id'] as int,
        author: Author.fromJson(json['author'] as Map<String, dynamic>),
        nodeId: json['node_id'] as String,
        tagName: json['tag_name'] as String,
        targetCommitish: json['target_commitish'] as String,
        name: json['name'] as String,
        draft: json['draft'] as bool,
        prerelease: json['prerelease'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        publishedAt: DateTime.parse(json['published_at'] as String),
        assets: List<Asset>.from(
          (json['assets'] as Map<String, Asset>)
              .map(
                (k, e) =>
                    MapEntry(k, Asset.fromJson(e as Map<String, dynamic>)),
              )
              .values,
        ),
        tarballUrl: json['tarball_url'] as String,
        zipballUrl: json['zipball_url'] as String,
        body: json['body'] as String,
      );

  final String url;
  final String assetsUrl;
  final String uploadUrl;
  final String htmlUrl;
  final int id;
  final Author author;
  final String nodeId;
  final String tagName;
  final String targetCommitish;
  final String name;
  final bool draft;
  final bool prerelease;
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<Asset> assets;
  final String tarballUrl;
  final String zipballUrl;
  final String body;

  Map<String, dynamic> toJson() => {
        'url': url,
        'assets_url': assetsUrl,
        'upload_url': uploadUrl,
        'html_url': htmlUrl,
        'id': id,
        'author': author.toJson(),
        'node_id': nodeId,
        'tag_name': tagName,
        'target_commitish': targetCommitish,
        'name': name,
        'draft': draft,
        'prerelease': prerelease,
        'created_at': createdAt.toIso8601String(),
        'published_at': publishedAt.toIso8601String(),
        'assets': List<dynamic>.from(assets.map((x) => x.toJson())),
        'tarball_url': tarballUrl,
        'zipball_url': zipballUrl,
        'body': body,
      };
}

class Asset {
  Asset({
    required this.url,
    required this.id,
    required this.nodeId,
    required this.name,
    required this.uploader,
    required this.contentType,
    required this.state,
    required this.size,
    required this.downloadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.browserDownloadUrl,
    this.label,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        url: json['url'] as String,
        id: json['id'] as int,
        nodeId: json['node_id'] as String,
        name: json['name'] as String,
        label: json['label'] as String?,
        uploader: Author.fromJson(json['uploader'] as Map<String, dynamic>),
        contentType: json['content_type'] as String,
        state: json['state'] as String,
        size: json['size'] as int,
        downloadCount: json['download_count'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        browserDownloadUrl: json['browser_download_url'] as String,
      );

  final String url;
  final int id;
  final String nodeId;
  final String name;
  final String? label;
  final Author uploader;
  final String contentType;
  final String state;
  final int size;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String browserDownloadUrl;

  Map<String, dynamic> toJson() => {
        'url': url,
        'id': id,
        'node_id': nodeId,
        'name': name,
        'label': label,
        'uploader': uploader.toJson(),
        'content_type': contentType,
        'state': state,
        'size': size,
        'download_count': downloadCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'browser_download_url': browserDownloadUrl,
      };
}

class Author {
  Author({
    required this.login,
    required this.id,
    required this.nodeId,
    required this.avatarUrl,
    required this.gravatarId,
    required this.url,
    required this.htmlUrl,
    required this.followersUrl,
    required this.followingUrl,
    required this.gistsUrl,
    required this.starredUrl,
    required this.subscriptionsUrl,
    required this.organizationsUrl,
    required this.reposUrl,
    required this.eventsUrl,
    required this.receivedEventsUrl,
    required this.type,
    required this.siteAdmin,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        login: json['login'] as String,
        id: json['id'] as int,
        nodeId: json['node_id'] as String,
        avatarUrl: json['avatar_url'] as String,
        gravatarId: json['gravatar_id'] as String,
        url: json['url'] as String,
        htmlUrl: json['html_url'] as String,
        followersUrl: json['followers_url'] as String,
        followingUrl: json['following_url'] as String,
        gistsUrl: json['gists_url'] as String,
        starredUrl: json['starred_url'] as String,
        subscriptionsUrl: json['subscriptions_url'] as String,
        organizationsUrl: json['organizations_url'] as String,
        reposUrl: json['repos_url'] as String,
        eventsUrl: json['events_url'] as String,
        receivedEventsUrl: json['received_events_url'] as String,
        type: json['type'] as String,
        siteAdmin: json['site_admin'] as bool,
      );

  final String login;
  final int id;
  final String nodeId;
  final String avatarUrl;
  final String gravatarId;
  final String url;
  final String htmlUrl;
  final String followersUrl;
  final String followingUrl;
  final String gistsUrl;
  final String starredUrl;
  final String subscriptionsUrl;
  final String organizationsUrl;
  final String reposUrl;
  final String eventsUrl;
  final String receivedEventsUrl;
  final String type;
  final bool siteAdmin;

  Map<String, dynamic> toJson() => {
        'login': login,
        'id': id,
        'node_id': nodeId,
        'avatar_url': avatarUrl,
        'gravatar_id': gravatarId,
        'url': url,
        'html_url': htmlUrl,
        'followers_url': followersUrl,
        'following_url': followingUrl,
        'gists_url': gistsUrl,
        'starred_url': starredUrl,
        'subscriptions_url': subscriptionsUrl,
        'organizations_url': organizationsUrl,
        'repos_url': reposUrl,
        'events_url': eventsUrl,
        'received_events_url': receivedEventsUrl,
        'type': type,
        'site_admin': siteAdmin,
      };
}
