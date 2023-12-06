import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PhotoListScreen(),
    );
  }
}

class Photo {
  String id;
  String author;
  String imageUrl;
  String authorProfileUrl;

  Photo({
    required this.id,
    required this.author,
    required this.imageUrl,
    required this.authorProfileUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      author: json['user']['username'],
      imageUrl: json['urls']['regular'],
      authorProfileUrl: json['user']['links']['html'],
    );
  }
}

class UnsplashApi {
  final String apiKey = 'uMMIAf8R4FdsjeGUmEKkZRjFtap0BhJU-3P9Ww8Fe_s';

  Future<List<Photo>> getPhotos(int page) async {
    final response = await http.get(
      Uri.parse('https://api.unsplash.com/photos?page=$page&per_page=10'),
      headers: {'Authorization': 'Client-ID $apiKey'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load photos');
    }
  }
}

class PhotoListScreen extends StatefulWidget {
  const PhotoListScreen({super.key});

  @override
  _PhotoListScreenState createState() {
    return _PhotoListScreenState();
  }
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  final UnsplashApi _unsplashApi = UnsplashApi();
  final List<Photo> _allPhotos = [];
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final List<Photo> newPhotos = await _unsplashApi.getPhotos(_currentPage);
    setState(() {
      _allPhotos.addAll(newPhotos);
      _currentPage++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsplash Photos List'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadPhotos();
          }
          return true;
        },
        child: ListView.builder(
          itemCount: _allPhotos.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_allPhotos[index].author),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(_allPhotos[index].imageUrl),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      String url = _allPhotos[index].authorProfileUrl;
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: const Text('Author Profile'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
