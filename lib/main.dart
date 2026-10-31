import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storage_client/storage_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

// Supabase Configuration
// URL project Supabase milik Anda:
const String supabaseUrl = "https://ckgymiinffzfyfbiiyob.supabase.co";
// API Key (anon public) milik project Anda:
const String supabaseKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ3ltaWluZmZ6ZnlmYmlpeW9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyMDM3MDEsImV4cCI6MjEwNjc3OTcwMX0.uiCTFbIJkFk2H_urShILpXJbptKexztW0MT4yWoGviA";

// Initialize Supabase Storage Client
final SupabaseStorageClient supabaseStorage = SupabaseStorageClient(
  '$supabaseUrl/storage/v1',
  {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PML 07 - Supabase Storage & Firestore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E35B1), // Deep purple matching module
        ),
        useMaterial3: true,
      ),
      home: const SupabaseFirestoreHomeScreen(),
    );
  }
}

class SupabaseFirestoreHomeScreen extends StatefulWidget {
  const SupabaseFirestoreHomeScreen({super.key});

  @override
  State<SupabaseFirestoreHomeScreen> createState() =>
      _SupabaseFirestoreHomeScreenState();
}

class _SupabaseFirestoreHomeScreenState
    extends State<SupabaseFirestoreHomeScreen> {
  final TextEditingController _fileDescController = TextEditingController();

  PlatformFile? _selectedFile;
  String _selectedFileType = ''; // 'Image', 'PDF', 'Docx', 'Video'
  bool _isUploading = false;

  @override
  void dispose() {
    _fileDescController.dispose();
    super.dispose();
  }

  // Pilih file berdasarkan tipe (IMAGE, PDF, WORD, VIDEO)
  Future<void> _pickFile(String type) async {
    FileType pickerType = FileType.any;
    List<String>? allowedExtensions;

    switch (type) {
      case 'Image':
        pickerType = FileType.image;
        break;
      case 'PDF':
        pickerType = FileType.custom;
        allowedExtensions = ['pdf'];
        break;
      case 'Docx':
        pickerType = FileType.custom;
        allowedExtensions = ['doc', 'docx'];
        break;
      case 'Video':
        pickerType = FileType.video;
        break;
    }

    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: pickerType,
        allowedExtensions: allowedExtensions,
      );

      if (files.isNotEmpty) {
        setState(() {
          _selectedFile = files.first;
          _selectedFileType = type;
        });
        _showSnackBar('File terpilih: ${_selectedFile!.name}');
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file: $e');
    }
  }

  // Proses upload ke Supabase Storage lalu simpan metadata ke Firestore
  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      _showSnackBar('Pilih file yang akan diupload terlebih dahulu');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    _showUploadDialog();

    try {
      // Dapatkan data bytes dari file melalui xFile
      final Uint8List fileBytes = await _selectedFile!.xFile.readAsBytes();

      final String fileName = _selectedFile!.name;
      final String fileDescription = _fileDescController.text.trim().isEmpty
          ? 'No Description'
          : _fileDescController.text.trim();

      // Tentukan mime type sesuai tipe file
      String mimeType = 'application/octet-stream';
      if (_selectedFileType == 'Image') {
        mimeType = 'image/${_selectedFile!.extension ?? 'jpeg'}';
      } else if (_selectedFileType == 'PDF') {
        mimeType = 'application/pdf';
      } else if (_selectedFileType == 'Docx') {
        mimeType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (_selectedFileType == 'Video') {
        mimeType = 'video/${_selectedFile!.extension ?? 'mp4'}';
      }

      // Upload ke Supabase Storage (bucket 'Storage' sesuai yang dibuat di dashboard)
      const String bucketName = 'Storage';
      await supabaseStorage.from(bucketName).uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      // Dapatkan Public URL dari Supabase
      final String publicUrl =
          supabaseStorage.from(bucketName).getPublicUrl(fileName);

      // Simpan metadata ke Firebase Firestore (Collection "files")
      await FirebaseFirestore.instance.collection('files').doc(fileName).set({
        'file_name': fileName,
        'file_type': _selectedFileType,
        'file_url': publicUrl,
        'file_description': fileDescription,
        'uploaded_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog upload
        setState(() {
          _selectedFile = null;
          _selectedFileType = '';
          _fileDescController.clear();
          _isUploading = false;
        });
        _showSnackBar('Berhasil mengupload file dan menyimpan ke Firestore!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog upload
        setState(() {
          _isUploading = false;
        });
        _showSnackBar('Upload gagal: $e');
      }
    }
  }

  // Dialog loading upload sesuai modul
  void _showUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Proses upload sedang berlangsung ... please wait',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Buka URL file di browser / external viewer
  Future<void> _openFileUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback ke in-app browser jika external gagal
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      _showSnackBar('Gagal membuka link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Supa B',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF5E35B1),
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bagian Input & Tombol Picker
            Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4 Tombol Pilihan Jenis File
                  Row(
                    children: [
                      _buildTypeButton('IMAGE', 'Image'),
                      const SizedBox(width: 6),
                      _buildTypeButton('PDF', 'PDF'),
                      const SizedBox(width: 6),
                      _buildTypeButton('WORD', 'Docx'),
                      const SizedBox(width: 6),
                      _buildTypeButton('VIDEO', 'Video'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Teks status file yang akan diupload
                  Text(
                    'File yang akan diupload : ${_selectedFile?.name ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Deskripsi File :',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // TextField Deskripsi
                  TextField(
                    controller: _fileDescController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan deskripsi file yang akan diupload',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tombol Upload File
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _isUploading ? null : _uploadFile,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text(
                        'Upload File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Daftar File Realtime dari Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('files')
                    .orderBy('uploaded_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // Fallback query tanpa orderBy jika index Firestore belum siap
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('files')
                          .snapshots(),
                      builder: (context, fallbackSnapshot) {
                        if (fallbackSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${fallbackSnapshot.error}'),
                          );
                        }
                        if (fallbackSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return _buildFileList(fallbackSnapshot.data?.docs ?? []);
                      },
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return _buildFileList(snapshot.data?.docs ?? []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tombol tipe file
  Widget _buildTypeButton(String label, String type) {
    final bool isSelected = _selectedFileType == type;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFF5E35B1) : const Color(0xFF7E57C2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: isSelected ? 4 : 1,
        ),
        onPressed: () => _pickFile(type),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Widget daftar file dari Firestore
  Widget _buildFileList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Belum ada file yang diupload',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: docs.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 12, color: Colors.grey),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final String fileName = data['file_name'] ?? 'Unknown File';
        final String fileType = data['file_type'] ?? '';
        final String fileUrl = data['file_url'] ?? '';
        final String fileDesc = data['file_description'] ?? 'No Description';

        return InkWell(
          onTap: () => _openFileUrl(fileUrl),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail / Icon berdasarkan file_type
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: _buildFileThumbnail(fileType, fileUrl),
                  ),
                ),

                const SizedBox(width: 10),

                // Detail File (Nama, Tipe, URL, Deskripsi)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileUrl,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileDesc,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Thumbnail sesuai Gambar 13 modul
  Widget _buildFileThumbnail(String fileType, String fileUrl) {
    if (fileType == 'Image' && fileUrl.isNotEmpty) {
      return Image.network(
        fileUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image, size: 36, color: Colors.blueGrey);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
      );
    } else if (fileType == 'PDF') {
      return const Icon(
        Icons.picture_as_pdf,
        size: 36,
        color: Colors.red,
      );
    } else if (fileType == 'Docx') {
      return const Icon(
        Icons.description,
        size: 36,
        color: Colors.blue,
      );
    } else if (fileType == 'Video') {
      return const Icon(
        Icons.video_library,
        size: 36,
        color: Colors.deepPurple,
      );
    } else {
      return const Icon(
        Icons.insert_drive_file,
        size: 36,
        color: Colors.grey,
      );
    }
  }
}
