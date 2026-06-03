class Organization {
  final String id;
  final String name;
  final String authorIds;

  Organization({
    required this.id,
    required this.name,
    required this.authorIds,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      authorIds: json['author_ids'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author_ids': authorIds,
    };
  }
}

Map<String, Organization> organizations = {
  "1001": Organization(id: "1001", name: "四禧丸子", authorIds: "1,10029,10030,10028"),
  "1015": Organization(id: "1015", name: "星瞳", authorIds: "10031"),
  "1011": Organization(id: "1011", name: "PSPlive", authorIds: "10098,10080,10079"),
  "1034": Organization(id: "1034", name: "雪糕cheese", authorIds: "10078"),
  "1045": Organization(id: "1045", name: "黎歌Neeko", authorIds: "10108"),
  "1032": Organization(id: "1032", name: "泽音Melody", authorIds: "10085"),
};
