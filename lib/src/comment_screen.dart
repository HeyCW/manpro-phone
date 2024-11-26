import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentScreen extends StatefulWidget {
  final String noteId;
  final String token;
  final String user;

  const CommentScreen(
      {super.key,
      required this.noteId,
      required this.token,
      required this.user});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List<dynamic> comments = [];
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  Future<void> getComments() async {
    try {
      final uri =
          Uri.parse('http://10.0.2.2:5000/api/comments/getByDocumentId');

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(<String, String>{
          'document_id': widget.noteId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          comments = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error (e.g., show a snackbar or dialog)
    }
  }

  @override
  void initState() {
    super.initState();
    getComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Loading indicator
            )
          : Stack(
              children: [
                // List view to display comments
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.only(bottom: 150), // Space for TextField
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true, // Agar tidak memaksa ukuran penuh
                        physics:
                            const NeverScrollableScrollPhysics(), // Supaya tidak scrollable secara independen
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(), // Avatar kosong
                            title: Text(
                              comments[index]
                                  ['owner'], // Menampilkan nama pengguna
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              comments[index]
                                  ['comment'], // Menampilkan isi komentar
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Sticky TextField at the bottom with adjusted position and white background
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -10, // Naikkan sedikit dari bawah
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: const Color.fromRGBO(
                          254, 247, 255, 1), // Warna latar belakang abu-abu
                      width: double.infinity, // Agar lebar penuh
                      height: 155,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(),
                                fillColor: Colors.white,
                                filled:
                                    true, // Pastikan latar belakang putih pada textfield
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final url = Uri.parse(
                                  "http://10.0.2.2:5000/api/comments/add");

                              final body = {
                                'document_id': widget
                                    .noteId, // Menggunakan noteId dari widget
                                'owner': widget
                                    .user, // Ganti dengan data pengguna yang sesuai
                                'comment': _commentController.text,
                              };

                              try {
                                final response = await http.post(
                                  url,
                                  headers: <String, String>{
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer ${widget.token}',
                                  },
                                  body: jsonEncode(body),
                                );

                                if (response.statusCode == 200) {
                                  final newComment = jsonDecode(response.body);
                                  setState(() {
                                    comments.add(newComment);
                                    _commentController.clear();
                                  });
                                  getComments();
                                } else {
                                  print(
                                      'Failed to submit comment: ${response.body}');
                                }
                              } catch (e) {
                                print('Error submitting comment: $e');
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
