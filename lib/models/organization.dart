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
  "1021": Organization(id: "1021", name: "小海梓", authorIds: "10044"),
  "1004": Organization(id: "1004", name: "Istella_Offical", authorIds: "10006"),
  "1013": Organization(id: "1013", name: "伊万酱哒油", authorIds: "10061"),
  "1032": Organization(id: "1032", name: "VirtuaReal2", authorIds: "10085,10101"),
  "1014": Organization(id: "1014", name: "EOE组合", authorIds: "10023,10025"),
};
