class VideoItem {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoId;
  final String channelTitle;
  final DateTime publishedAt;
  final String emotionCategory; // The emotion this video is meant to address

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoId,
    required this.channelTitle,
    required this.publishedAt,
    required this.emotionCategory,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    // Handle the case where 'id' can be either a string or a map
    String videoId;
    String id;

    if (json['id'] is Map) {
      videoId = json['id']['videoId'] ?? '';
      id = videoId; // Use videoId as id if id is a Map
    } else {
      videoId = json['id'] ?? '';
      id = videoId;
    }

    return VideoItem(
      id: id,
      title: json['snippet']['title'] ?? '',
      description: json['snippet']['description'] ?? '',
      thumbnailUrl: json['snippet']['thumbnails']['medium']['url'] ?? '',
      videoId: videoId,
      channelTitle: json['snippet']['channelTitle'] ?? '',
      publishedAt: DateTime.parse(json['snippet']['publishedAt']),
      emotionCategory: json['emotionCategory'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'channelTitle': channelTitle,
      'publishedAt': publishedAt.toIso8601String(),
      'emotionCategory': emotionCategory,
    };
  }
}
