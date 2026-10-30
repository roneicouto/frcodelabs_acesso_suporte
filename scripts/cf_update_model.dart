class CfRelease {
  final String version;
  final Uri download;
  final int bytes;
  final String sha256;
  const CfRelease(this.version, this.download, {this.bytes = 0, this.sha256 = ''});

  bool get canInstall => bytes > 0 && bytes <= 512 * 1024 * 1024 &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256);

  static List<int>? versionParts(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
    return match == null ? null : [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
  }

  static bool isNewer(String candidate, String installed) {
    final next = versionParts(candidate);
    final current = versionParts(installed);
    if (next == null || current == null) return false;
    for (var i = 0; i < 3; i++) {
      if (next[i] != current[i]) return next[i] > current[i];
    }
    return false;
  }

  static CfRelease? fromJson(Map<String, dynamic> data, String current,
      String repository, String assetName) {
    final tag = data['tag_name'];
    if (data['draft'] == true || data['prerelease'] == true ||
        tag is! String || !isNewer(tag, current)) return null;
    final assets = data['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map || asset['name'] != assetName || asset['state'] != 'uploaded') continue;
      // Mixed-platform releases may retain an older package for another OS.
      final label = asset['label'];
      final labeledVersion = label is String ? RegExp(r'\bv(\d+\.\d+\.\d+)$').firstMatch(label)?.group(1) : null;
      final packageVersion = labeledVersion ?? tag;
      if (!isNewer(packageVersion, current)) continue;
      final value = asset['browser_download_url'];
      final uri = value is String ? Uri.tryParse(value) : null;
      if (uri == null || uri.scheme != 'https' || uri.host != 'github.com' ||
          uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
          uri.path != '/$repository/releases/download/$tag/$assetName') continue;
      final digest = asset['digest'];
      return CfRelease(packageVersion.replaceFirst(RegExp(r'^v'), ''), uri,
          bytes: asset['size'] is int ? asset['size'] : 0,
          sha256: digest is String && digest.startsWith('sha256:') ? digest.substring(7).toLowerCase() : '');
    }
    return null;
  }
}

