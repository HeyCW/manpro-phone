import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late String token;
  List<dynamic> documents = [];
  List<QuillController> controllers = [];
  String? email;
  String? username;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadToken();
    await _loadDocuments();
    await _loadUsername();
    await _loadEmail();
  }

  Future<void> _loadToken() async {
    token = await secureStorage.read(key: 'token') ?? '';
  }

  Future<void> _loadUsername() async {
    username = await secureStorage.read(key: 'username') ?? '';
  }

  Future<void> _loadEmail() async {
    email = await secureStorage.read(key: 'email') ?? '';
  }

  Future<void> _loadDocuments() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/notes');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          documents = json.decode(response.body);
          for (int i = 0; i < documents.length; i++) {
            // Cek apakah ada 'ops' di dalam 'data'
            if (documents[i]['data'] is Map &&
                documents[i]['data']['ops'] != null &&
                documents[i]['data']['ops'] is List) {
              // Tipe pertama: 'data' memiliki properti 'ops'
              try {
                // Buat QuillController untuk dokumen dengan 'ops'
                QuillController controller = QuillController(
                  document: Document.fromJson(documents[i]['data']['ops']),
                  selection: const TextSelection.collapsed(offset: 0),
                );
                controllers.add(controller); // Tambahkan ke list controllers
              } catch (e) {
                print(
                    'Error creating QuillController for document $i (ops): $e');
                controllers.add(QuillController(
                  document: Document(),
                  selection: const TextSelection.collapsed(offset: 0),
                ));
              }
            } else if (documents[i]['data'] is List) {
              // Tipe kedua: 'data' langsung berupa array, tanpa 'ops'
              try {
                // Buat QuillController untuk dokumen tanpa 'ops'
                QuillController controller = QuillController(
                  document: Document.fromJson(documents[i]['data']),
                  selection: const TextSelection.collapsed(offset: 0),
                );
                controllers.add(controller); // Tambahkan ke list controllers
              } catch (e) {
                print(
                    'Error creating QuillController for document $i (direct data): $e');
                controllers.add(QuillController(
                  document: Document(),
                  selection: const TextSelection.collapsed(offset: 0),
                ));
              }
            } else {
              // Jika formatnya tidak sesuai, tambahkan controller kosong
              print('Invalid data format at index $i');
              controllers.add(QuillController(
                document: Document(),
                selection: const TextSelection.collapsed(offset: 0),
              ));
            }
          }
        });
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  List<Widget> buildRows(List<dynamic> docs) {
    List<Widget> rows = [];
    for (int i = 0; i < docs.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    child: QuillEditor.basic(
                      configurations:
                          const QuillEditorConfigurations(autoFocus: false),
                      controller: controllers[
                          i], // Gunakan controller yang sesuai untuk dokumen
                      focusNode: FocusNode(),
                      scrollController: ScrollController(),
                    ),
                  ),
                  Text(docs[i]["name"],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    docs[i]["owner"],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ButtonTheme(
                      child: ElevatedButton(
                          onPressed: () {
                            GoRouter.of(context)
                                .go('/document/${docs[i]['_id']}');
                          },
                          child: Text("Open"))),
                ],
              ),
            ),
          ),
          if (i + 1 < docs.length)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      // Atur tinggi sesuai kebutuhan
                      child: QuillEditor.basic(
                        configurations:
                            const QuillEditorConfigurations(autoFocus: false),
                        controller: controllers[i +
                            1], // Gunakan controller yang sesuai untuk dokumen
                        focusNode: FocusNode(),
                        scrollController: ScrollController(),
                      ),
                    ),
                    Text(docs[i + 1]["name"],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(docs[i + 1]["owner"],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ButtonTheme(
                        child: ElevatedButton(
                            onPressed: () {
                              GoRouter.of(context)
                                  .go('/document/${docs[i + 1]['_id']}');
                            },
                            child: Text("Open"))),
                  ],
                ),
              ),
            ),
        ],
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: Center(
              child: Text("Welcome $username",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
            backgroundColor: Colors.blue,
          ),
          body: documents.isEmpty || controllers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  const SizedBox(height: 20),
                  TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                      onChanged: (value) async {
                        await _loadDocuments();

                        setState(() {
                          documents = documents
                              .where((doc) => doc['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      }),
                  const SizedBox(height: 20),
                  Expanded(
                      child: ListView(
                    children: buildRows(documents),
                  ))
                ])),
    );
  }
}
