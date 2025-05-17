import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class UploadReceiptPage extends StatefulWidget {
  const UploadReceiptPage({super.key});

  @override
  State<UploadReceiptPage> createState() => _UploadReceiptPageState();
}

class _UploadReceiptPageState extends State<UploadReceiptPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlatformFile> _singleMonthFiles = [];
  List<PlatformFile> _bulkFiles = [];
  int? _selectedMonth;
  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _pickSingleMonthFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        final existingNames = _singleMonthFiles.map((f) => f.name).toSet();
        final newFiles = result.files.where((f) => !existingNames.contains(f.name));
        _singleMonthFiles.addAll(newFiles);
      });
    }
  }

  void _captureImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        final file = PlatformFile(name: image.name, path: image.path, size: File(image.path).lengthSync(), bytes: null);
        // Avoid duplicates by name
        if (!_singleMonthFiles.any((f) => f.name == file.name)) {
          _singleMonthFiles.add(file);
        }
      });
    }
  }

  void _pickBulkFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _bulkFiles = result.files;
      });
    }
  }

  void _showImagePreview(PlatformFile file) {
    if (file.path != null && (file.name.toLowerCase().endsWith('.jpg') || file.name.toLowerCase().endsWith('.jpeg'))) {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(file.path!), fit: BoxFit.contain)),
              ),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Receipt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Single Month'), Tab(text: 'Bulk Upload')]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Single Month Upload
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Month'),
                  value: _selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(value: index + 1, child: Text(months[index]));
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickSingleMonthFiles,
                              child: DottedBorder(
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                dashPattern: [8, 4],
                                color: Colors.blueGrey,
                                strokeWidth: 2,
                                child: Container(
                                  height: 80,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.upload_file, size: 28, color: Colors.blueGrey),
                                      SizedBox(height: 4),
                                      Text('Choose from files', style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _captureImage,
                              child: DottedBorder(
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                dashPattern: [8, 4],
                                color: Colors.green,
                                strokeWidth: 2,
                                child: Container(
                                  height: 80,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.camera_alt, size: 28, color: Colors.green),
                                      SizedBox(height: 4),
                                      Text('Capture Image', style: TextStyle(color: Colors.green, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child:
                            _singleMonthFiles.isEmpty
                                ? const Center(child: Text('No files selected.', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                  itemCount: _singleMonthFiles.length,
                                  itemBuilder: (context, index) {
                                    final file = _singleMonthFiles[index];
                                    return GestureDetector(
                                      onTap: () => _showImagePreview(file),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.blueGrey, width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    file.name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                                                    color: file.name.toLowerCase().endsWith('.pdf') ? Colors.red : Colors.blueGrey,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(file.name, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () {
                                                    setState(() {
                                                      _singleMonthFiles.removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(20),
                                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                                    ),
                                                    padding: const EdgeInsets.all(4),
                                                    child: const Icon(Icons.close, color: Colors.red, size: 20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      _singleMonthFiles.isNotEmpty
                          ? () {
                            // TODO: Implement submit logic
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted!')));
                          }
                          : null,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          // Bulk Upload
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(onPressed: _pickBulkFiles, icon: const Icon(Icons.upload_file), label: const Text('Choose Files')),
                const SizedBox(height: 24),
                if (_bulkFiles.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _bulkFiles.length,
                      itemBuilder: (context, index) {
                        final file = _bulkFiles[index];
                        return GestureDetector(
                          onTap: () => _showImagePreview(file),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blueGrey, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        file.name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                                        color: file.name.toLowerCase().endsWith('.pdf') ? Colors.red : Colors.blueGrey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(file.name, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setState(() {
                                          _bulkFiles.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, color: Colors.red, size: 20),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Text('No files selected.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      _bulkFiles.isNotEmpty
                          ? () {
                            // TODO: Implement bulk submit logic
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk submitted!')));
                          }
                          : null,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
