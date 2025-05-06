class MusicTrack {
  final String id;
  final String name;
  final List<String> artists;
  final String albumName;
  final String albumImageUrl;
  final String? previewUrl;
  final String emotionCategory;
  final bool hasPreview;
  final String spotifyUri;     
  final String externalUrl;   

  MusicTrack({
    required this.id,
    required this.name, 
    required this.artists,
    required this.albumName,
    required this.albumImageUrl,
    this.previewUrl,
    required this.emotionCategory,
    required this.spotifyUri,
    required this.externalUrl,
  }) : hasPreview = previewUrl != null && previewUrl.isNotEmpty;

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    // Extract album image if available
    String albumImageUrl = '';
    if (json['album'] != null && 
        json['album']['images'] != null && 
        json['album']['images'].isNotEmpty) {
      albumImageUrl = json['album']['images'][0]['url'] ?? '';
    }

    // Extract artist names
    List<String> artists = [];
    if (json['artists'] != null) {
      artists = List<String>.from(
        json['artists'].map((artist) => artist['name'] ?? 'Unknown Artist')
      );
    }

    return MusicTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artists: artists,
      albumName: json['album']?['name'] ?? 'Unknown Album',
      albumImageUrl: albumImageUrl,
      previewUrl: json['preview_url'],
      emotionCategory: json['emotionCategory'] ?? 'Unknown',
      spotifyUri: json['uri'] ?? '',
      externalUrl: json['external_urls']?['spotify'] ?? '',
    );
  }
}