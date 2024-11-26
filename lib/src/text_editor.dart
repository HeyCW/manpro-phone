import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:mynotes_phone/Model/Note.dart';
import 'package:mynotes_phone/src/comment_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:go_router/go_router.dart';

class TextEditor extends StatefulWidget {
  final String? id;

  const TextEditor({super.key, this.id});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late QuillController _controller;
  late IO.Socket socket;
  late Note _document = Note(
      id: '',
      name: '',
      publicAccess: '',
      publicPermission: '',
      owner: '',
      readAccess: [],
      writeAccess: []);
  late String token;
  late String user;
  late String email;
  Timer? _timer;
  bool isRemoteUpdate = false;
  final TextEditingController _namaDocument =
      TextEditingController(text: 'Document');
  String? selectedValue;
  String? selectedValue2 = "View";
  List<String> selectedPermissions = [];
  final TextEditingController _emailController = TextEditingController();
  bool _isSocketInitialized = false;
  BuildContext? _modalContext;

  void _openComment() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        _modalContext = context;
        return CommentScreen(noteId: _document.id, token: token, user: user);
      },
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text("Bagikan " + " \"" + _namaDocument.text + "\""),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize
                    .min, // Tambahkan ini agar konten tidak memanjang
                children: <Widget>[
                  Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Email',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final url = Uri.parse(
                              "http://10.0.2.2:5000/api/notes/addReadAccess");
                          final body = jsonEncode({
                            'id': widget.id,
                            'email': _emailController.text,
                          });

                          http.post(
                            url,
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: body,
                          );

                          _emailController.clear();
                        },
                        child: const Text('Kirim'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Orang yang memiliki akses",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 400,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            // Iterate over _document.readAccess and create widgets
                            for (int i = 0;
                                i < _document.readAccess.length;
                                i++)
                              Container(
                                width: double.infinity,
                                height: 75,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_document.readAccess[i]}',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                    DropdownButton<String>(
                                      value: 'Read',
                                      hint: const Text("Select an option"),
                                      onChanged: (String? newValue) {
                                        final url = Uri.parse(
                                            "http://10.0.2.2:5000/api/notes/addWriteAccess");
                                        final body = jsonEncode({
                                          'id': widget.id,
                                          'email': _document.readAccess[i],
                                        });

                                        http.post(
                                          url,
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                          },
                                          body: body,
                                        );

                                        final url2 = Uri.parse(
                                            "http://10.0.2.2:5000/api/notes/removeReadAccess");
                                        final body2 = jsonEncode({
                                          'id': widget.id,
                                          'email': _document.readAccess[i],
                                        });

                                        http.post(
                                          url2,
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                          },
                                          body: body2,
                                        );

                                        setDialogState(() {
                                          _document.writeAccess
                                              .add(_document.readAccess[i]);
                                          _document.readAccess.removeAt(i);
                                        });
                                      },
                                      items: <String>['Read', 'Write']
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            // Iterate over _document.writeAccess and create widgets
                            for (int i = 0;
                                i < _document.writeAccess.length;
                                i++)
                              Container(
                                width: double.infinity,
                                height: 75,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_document.writeAccess[i]}',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                    DropdownButton<String>(
                                      value: 'Write',
                                      hint: const Text("Select an option"),
                                      onChanged: (String? newValue) {
                                        final url = Uri.parse(
                                            "http://10.0.2.2:5000/api/notes/addReadAccess");
                                        final body = jsonEncode({
                                          'id': widget.id,
                                          'email': _document.writeAccess[i],
                                        });

                                        http.post(
                                          url,
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                          },
                                          body: body,
                                        );

                                        final url2 = Uri.parse(
                                            "http://10.0.2.2:5000/api/notes/removeWriteAccess");
                                        final body2 = jsonEncode({
                                          'id': widget.id,
                                          'email': _document.writeAccess[i],
                                        });

                                        http.post(
                                          url2,
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                          },
                                          body: body2,
                                        );

                                        setDialogState(() {
                                          _document.readAccess
                                              .add(_document.writeAccess[i]);
                                          _document.writeAccess.removeAt(i);
                                        });
                                      },
                                      items: <String>['Read', 'Write']
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )),
                  const Text(
                    "Akses",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  DropdownButton<String>(
                    value: selectedValue,
                    hint: const Text("Select an option"),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedValue = newValue;
                      });
                      setState(() {
                        selectedValue = newValue;
                      });

                      final url = Uri.parse(
                          "http://10.0.2.2:5000/api/notes/changePublicAccess");
                      final body = jsonEncode({
                        'id': widget.id,
                        'access': newValue,
                      });

                      http.post(
                        url,
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/json',
                        },
                        body: body,
                      );
                    },
                    items: <String>['Restricted', 'Anyone with the link']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          selectedValue == "Restricted"
                              ? "Only people added can access"
                              : "Anyone with the link can access",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                          overflow: TextOverflow
                              .ellipsis, // Tambahkan jika teks terlalu panjang
                        ),
                      ),
                      const SizedBox(width: 8), // Jarak antar elemen
                      if (selectedValue != "Restricted")
                        Expanded(
                          flex: 1, // Proporsi lebih kecil untuk dropdown
                          child: DropdownButton<String>(
                            isExpanded:
                                true, // Buat dropdown melebar sesuai container
                            value: selectedValue2,
                            hint: const Text("Select an option"),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                selectedValue2 = newValue;
                              });
                              setState(() {
                                selectedValue2 = newValue;
                              });

                              final url = Uri.parse(
                                  "http://10.0.2.2:5000/api/notes/changePublicPermission");

                              final body = jsonEncode({
                                'id': widget.id,
                                'public_permission': newValue,
                              });

                              http.post(
                                url,
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: body,
                              );
                            },
                            items: <String>['Viewer', 'Editor']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initialize();

    _controller = QuillController.basic();
    _controller.readOnly = true;

    if (!_isSocketInitialized) {
      socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnect': true, // Aktifkan reconnect
        'reconnectAttempts': 5, // Tentukan berapa kali mencoba reconnect
        'reconnectDelay': 2000,
      });

      _isSocketInitialized = true;
    }

    // _controller.addListener(() {
    //   final text = _controller.document.toPlainText();
    //   print(text);
    //   socket.emit(
    //       'message', text); // Emit konten ke server setiap kali ada perubahan
    // });

    _loadDocument();

    socket.on('load-document', (response) {
      if (response != null && response is List && response.length >= 2) {
        final documentContent = response[0];
        final documentName = response[1];
        _namaDocument.text = documentName;
        if (documentContent is Map && documentContent.containsKey('ops')) {
          if (mounted) {
            setState(() {
              _controller = QuillController(
                  document: Document.fromJson(documentContent['ops']),
                  selection: const TextSelection.collapsed(offset: 0));

              _controller.document.changes.listen((change) {
                if (!isRemoteUpdate) {
                  _sendChanges();
                }
              });
              if (_document.id == '') {
                print("masuk1");
                _controller.readOnly = false;
              } else if (_document.owner == email) {
                print("masuk2");
                _controller.readOnly = false;
              } else if (_document.publicAccess == "Anyone with the link" &&
                  _document.publicPermission == "Editor") {
                print("masuk3");
                _controller.readOnly = false;
              } else if (_document.publicAccess == "Anyone with the link" &&
                  _document.publicPermission == "Viewer") {
                if (_document.writeAccess.contains(user)) {
                  print("masuk4");
                  _controller.readOnly = false;
                } else {
                  print("masuk5");
                  _controller.readOnly = true;
                }
              } else if (_document.publicAccess == "Restricted") {
                if (_document.writeAccess.contains(user)) {
                  print("masuk6");
                  _controller.readOnly = false;
                } else {
                  print("masuk7");
                  _controller.readOnly = true;
                }
              } else {
                print("masuk8");
                GoRouter.of(context).go('/home');
              }
            });
          }
        } else {
          print("Invalid document content structure: $documentContent");
        }
      } else {
        print("Invalid response structure: $response");
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _saveDocument();
      _receiveChanges();
      if (_document.id == '') {
        await _getDocumentFeature();
        await _loadDocument();
      }
    });
  }

  Future<void> _loadToken() async {
    token = await secureStorage.read(key: 'token') ?? '';
  }

  Future<void> _loadUser() async {
    user = await secureStorage.read(key: 'username') ?? '';
  }

  Future<void> _loadEmail() async {
    email = await secureStorage.read(key: 'email') ?? '';
  }

  Future<void> _initialize() async {
    await _loadToken();
    await _loadUser();
    await _loadEmail();
    await _getDocumentFeature();
  }

  Future _getDocumentFeature() async {
    final url = Uri.parse('http://10.0.2.2:5000/api/notes/getNoteById');

    final body = jsonEncode({
      'id': widget.id,
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body, // Sending the JSON-encoded body
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      setState(() {
        _document = Note.fromJson(responseJson['note']);
        selectedValue = _document.publicAccess;
        selectedValue2 = _document.publicPermission;
        selectedPermissions = List<String>.from(List.filled(
                _document.readAccess.length, 'Read') // Creates the initial list
            )
          ..addAll(List<String>.filled(_document.writeAccess.length,
                  'Write') // Adds the "Write" values
              );
      });
    } else {
      print('Error: ${response.body}');
    }
  }

  Future<void> _loadDocument() async {
    socket.emit('get-document', widget.id);
    socket.emit('join-room', widget.id);
  }

  Future<void> _saveDocument() async {
    final delta = _controller.document.toDelta();
    final jsonDelta = delta.toJson();

    final formattedData = {
      'ops': jsonDelta.map((item) {
        final result = {'insert': item['insert'] ?? ''};

        // Menambahkan atribut jika ada
        if (item['attributes'] != null) {
          result['attributes'] = item['attributes'];
        }

        return result;
      }).toList()
    };

    // Kirimkan objek JSON ke server
    socket.emit('save-document-phone', {
      'documentId': widget.id,
      'data': formattedData,
      'name': _namaDocument.text,
      'owner': email,
    });
  }

  void _sendChanges() {
    if (!isRemoteUpdate) {
      final delta = _controller.document.toDelta();
      final jsonDelta = delta.toJson();
      final formattedData = {
        'ops': jsonDelta.map((item) {
          // Mengecek apakah item memiliki insert dan attributes
          final result = {
            'insert': item['insert'] ??
                '' // Jika tidak ada insert, kirimkan string kosong
          };

          // Menambahkan atribut jika ada
          if (item['attributes'] != null) {
            result['attributes'] = item['attributes'];
          }

          return result;
        }).toList()
      };
      print('send-changes-phone');
      socket.emit('send-changes-phone', {
        'documentId': widget.id,
        'delta': formattedData,
      });
    }
  }

  void _receiveChanges() {
    socket.on('receive-changes', (response) {
      final delta = response['ops'];
      if (delta is List) {
        if (mounted) {
          setState(() {
            isRemoteUpdate = true;
            _controller = QuillController(
                document: Document.fromJson(delta),
                selection: const TextSelection.collapsed(offset: 0));

            _controller.document.changes.listen((change) {
              if (!isRemoteUpdate) {
                _sendChanges();
              }
            });
            isRemoteUpdate = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_modalContext != null) {
      Navigator.pop(_modalContext!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      const SizedBox(
        height: 70,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextField(
              controller: _namaDocument,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
          ),
          SizedBox(width: 16), // Jarak antara tombol
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go('/home');
              },
              child: Text('My Notes'),
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _dialogBuilder(context);
              },
              child: Text('Share'),
            ),
          ),
          SizedBox(width: 16), // Jarak antara tombol
          Expanded(
            child: ElevatedButton(
              onPressed: _openComment,
              child: Text('Comment'),
            ),
          ),
        ],
      ),
      QuillSimpleToolbar(
        controller: _controller,
        configurations: const QuillSimpleToolbarConfigurations(),
      ),
      Expanded(
        child: QuillEditor.basic(
          controller: _controller,
          configurations: const QuillEditorConfigurations(),
        ),
      )
    ]));
  }
}
