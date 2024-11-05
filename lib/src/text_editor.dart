import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class TextEditor extends StatefulWidget {
  final String? id;

  const TextEditor({super.key, this.id});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late QuillController _controller;
  late IO.Socket socket;
  Timer? _timer;
  bool isRemoteUpdate = false;

  @override
  void initState() {
    super.initState();

    _controller = QuillController.basic();

    socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    // _controller.addListener(() {
    //   final text = _controller.document.toPlainText();
    //   print(text);
    //   socket.emit(
    //       'message', text); // Emit konten ke server setiap kali ada perubahan
    // });

    _loadDocument();

    // Listen for the document load response
    socket.on('load-document', (response) {
      print("Received load-document response: $response");

      // Ensure that response is as expected
      if (response != null && response is List && response.length >= 2) {
        final documentContent =
            response[0]; // Accessing the first item assuming it's a map
        final documentName = response[1]; // Accessing the second item

        // Check if documentContent contains 'ops' key
        if (documentContent is Map && documentContent.containsKey('ops')) {
          setState(() {
            _controller = QuillController(
                document: Document.fromJson(documentContent['ops']),
                selection: const TextSelection.collapsed(offset: 0));
            _controller.document.changes.listen((change) {
              if (!isRemoteUpdate) {
                _sendChanges();
              }
            });
          });
        } else {
          print("Invalid document content structure: $documentContent");
        }
      } else {
        print("Invalid response structure: $response");
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _saveDocument();
      _receiveChanges();
    });
  }

  Future<void> _loadDocument() async {
    socket.emit('get-document', widget.id);
    socket.emit('join-room', widget.id);
  }

  void _saveDocument() {
    final delta = _controller.document.toDelta(); // Ambil delta dari dokumen
    final jsonDelta = delta.toJson(); // Konversi delta menjadi JSON

    // Kirimkan objek JSON ke server
    socket.emit('save-document-phone', {
      'documentId': widget.id,
      'data': jsonDelta, // Data yang sudah dikonversi ke JSON
      'name': 'Document',
      'owner': 'Budi'
    });
  }

  void _sendChanges() {
    if (!isRemoteUpdate) {
      // Only send changes if not in a remote update
      final delta = _controller.document.toDelta();
      final jsonDelta = delta.toJson();
      print(jsonDelta);
      socket.emit('send-changes-phone', {
        'documentId': widget.id,
        'delta': jsonDelta,
      });
    }
  }

  void _receiveChanges() {
    socket.on('receive-changes', (response) {
      isRemoteUpdate = true;
      _loadDocument();
      isRemoteUpdate = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      const SizedBox(
        height: 50,
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
