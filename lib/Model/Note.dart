class Note {
  final String id;
  final String name;
  final String publicAccess;
  final String publicPermission;
  final String owner;
  final List<String> readAccess;
  final List<String> writeAccess;

  Note({
    required this.id,
    required this.name,
    required this.publicAccess,
    required this.publicPermission,
    required this.owner,
    required this.readAccess,
    required this.writeAccess,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'],
      name: json['name'],
      publicAccess: json['public_access'],
      publicPermission: json['public_permission'],
      owner: json['owner'],
      readAccess: List<String>.from(json['read_access']),
      writeAccess: List<String>.from(json['write_access']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'publicAccess': publicAccess,
      'publicPermission': publicPermission,
      'owner': owner,
      'readAccess': readAccess,
      'writeAccess': writeAccess,
    };
  }
}
