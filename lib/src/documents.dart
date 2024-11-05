import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadToken(); // Tunggu hingga token selesai dimuat
    await _loadDocuments(); // Panggil setelah token berhasil dimuat
  }

  Future<void> _loadToken() async {
    token = await secureStorage.read(key: 'token') ?? '';
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
          QuillController _controller = QuillController(
            document: Document.fromJson(
                documents[0]['data']['ops']), // "\n" is mandatory
            selection: TextSelection.collapsed(offset: 0),
          );
          ;
          _controller.readOnly = true;
          // print(documents[0]['data']['ops']);
          controllers = List.generate(documents.length, (index) => _controller);
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
    for (int i = 0; i < 2; i += 2) {
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
                    child: SingleChildScrollView(
                      child: QuillEditor.basic(
                        configurations:
                            const QuillEditorConfigurations(autoFocus: false),
                        controller: controllers[i + 1],
                        focusNode: FocusNode(),
                        scrollController: ScrollController(),
                      ),
                    ),
                  ),
                  Text(
                    docs[i]["name"],
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    docs[i]["owner"],
                    overflow: TextOverflow.ellipsis,
                  ),
                  ButtonTheme(
                      child: ElevatedButton(
                          onPressed: () {}, child: Text("Open"))),
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
                        controller: controllers[i + 1],
                        focusNode: FocusNode(),
                        scrollController: ScrollController(),
                      ),
                    ),
                    Text(
                      docs[i + 1]["name"],
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      docs[i + 1]["owner"],
                      overflow: TextOverflow.ellipsis,
                    ),
                    ButtonTheme(
                        child: ElevatedButton(
                            onPressed: () {}, child: Text("Open"))),
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
          title: const Center(
            child: Text("Documents",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          backgroundColor: Colors.blue,
        ),
        body: documents.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: buildRows(documents),
              ),
      ),
    );
  }
}
