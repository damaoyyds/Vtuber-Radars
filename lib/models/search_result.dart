class Subtitle {
  final String clipId;
  final int start;
  final int end;
  final String markedContent;
  final String cleanContent;
  final String pinyin;
  final String text;

  Subtitle({
    required this.clipId,
    required this.start,
    required this.end,
    required this.markedContent,
    required this.cleanContent,
    required this.pinyin,
    required this.text,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      clipId: json['clip_id'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      markedContent: json['marked_content'] as String,
      cleanContent: json['clean_content'] as String,
      pinyin: json['pinyin'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clip_id': clipId,
      'start': start,
      'end': end,
      'marked_content': markedContent,
      'clean_content': cleanContent,
      'pinyin': pinyin,
      'text': text,
    };
  }

  String formatTime(int ms) {
    int seconds = ms ~/ 1000;
    int minutes = seconds ~/ 60;
    int hours = minutes ~/ 60;
    minutes = minutes % 60;
    seconds = seconds % 60;
    int milliseconds = ms % 1000;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}";
  }
}

class Author {
  final String name;

  Author({required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'] as String,
    );
  }
}

class ClipItem {
  final String id;
  final String title;
  final String datetime;
  final Author author;
  final String playUrl;
  final String bilibiliUrl;
  final String orgName;
  final String orgId;
  final List<Subtitle> subtitles;

  ClipItem({
    required this.id,
    required this.title,
    required this.datetime,
    required this.author,
    required this.playUrl,
    required this.bilibiliUrl,
    required this.orgName,
    required this.orgId,
    required this.subtitles,
  });

  factory ClipItem.fromJson(Map<String, dynamic> json) {
    var authorJson = json['author'] as Map<String, dynamic>? ?? {};
    var subtitlesList = json['subtitles'] as List<dynamic>? ?? [];
    
    return ClipItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
      author: Author.fromJson(authorJson),
      playUrl: json['play_url'] as String? ?? '',
      bilibiliUrl: json['bilibili_url'] as String? ?? '',
      orgName: json['org_name'] as String? ?? '',
      orgId: json['org_id']?.toString() ?? '',
      subtitles: subtitlesList.map((s) => Subtitle.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class Pagination {
  final int page;
  final int totalPages;
  final int total;

  Pagination({
    required this.page,
    required this.totalPages,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      totalPages: json['total_pages'] as int,
      total: json['total'] as int,
    );
  }
}

class SearchResult {
  final List<ClipItem> items;
  final Pagination pagination;

  SearchResult({
    required this.items,
    required this.pagination,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    var data = json['data'] as Map<String, dynamic>;
    var itemsList = data['items'] as List<dynamic>;
    
    return SearchResult(
      items: itemsList.map((item) => ClipItem.fromJson(item as Map<String, dynamic>)).toList(),
      pagination: Pagination.fromJson(data['pagination'] as Map<String, dynamic>),
    );
  }
}
