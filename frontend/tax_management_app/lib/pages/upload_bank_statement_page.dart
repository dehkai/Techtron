import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';

class UploadBankStatementPage extends StatefulWidget {
  const UploadBankStatementPage({super.key});

  @override
  State<UploadBankStatementPage> createState() => _UploadBankStatementPageState();
}

class _UploadBankStatementPageState extends State<UploadBankStatementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFileName;
  String? _selectedFilePath;
  List<String> _bulkFiles = [];
  int? _selectedMonth;

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

  void _pickSingleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFilePath = result.files.single.path;
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
        _bulkFiles = result.files.map((file) => file.name).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Bank Statement'),
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
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickSingleFile,
                        child:
                            _selectedFileName == null
                                ? DottedBorder(
                                  borderType: BorderType.RRect,
                                  radius: const Radius.circular(12),
                                  dashPattern: [8, 4],
                                  color: Colors.blueGrey,
                                  strokeWidth: 2,
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.upload_file, size: 36, color: Colors.blueGrey),
                                        SizedBox(height: 8),
                                        Text('Tap to choose file', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )
                                : Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blueGrey, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8),
                                  child:
                                      _selectedFileName!.toLowerCase().endsWith('.jpg') || _selectedFileName!.toLowerCase().endsWith('.jpeg')
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.file(File(_selectedFilePath!), fit: BoxFit.contain),
                                          )
                                          : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.picture_as_pdf, size: 36, color: Colors.red),
                                              SizedBox(height: 8),
                                              Text('PDF Preview Not Available', style: TextStyle(color: Colors.red, fontSize: 16)),
                                            ],
                                          ),
                                ),
                      ),
                      if (_selectedFileName != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _selectedFileName = null;
                                  _selectedFilePath = null;
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      _selectedFileName != null
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
                        final fileName = _bulkFiles[index];
                        return Container(
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
                                      fileName.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                                      color: fileName.toLowerCase().endsWith('.pdf') ? Colors.red : Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(fileName, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
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
