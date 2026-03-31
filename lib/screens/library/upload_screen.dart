import 'dart:io';
import 'package:flutter/material.dart';
import 'library_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:dotted_border/dotted_border.dart';

const Color primaryColor = LibraryTheme.primary;
const Color backgroundColor = LibraryTheme.bg;
const Color textColor = LibraryTheme.text;

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedFile;
  bool _isUploading = false;

  final _subjectNameController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCollege;
  String? _selectedSpecialization;
  String? _selectedLevel;
  String? _selectedTerm;

  final List<String> _colleges = ['كلية الحاسبات', 'كلية إدارة الأعمال', 'كلية الهندسة', 'كلية الحقوق'];
  final List<String> _specializations = ['علوم الحاسب', 'نظم المعلومات', 'هندسة البرمجيات', 'الأمن السيبراني'];
  final List<String> _levels = ['المستوى الأول', 'المستوى الثاني', 'المستوى الثالث', 'المستوى الرابع', 'المستوى الخامس'];
  final List<String> _terms = ['الفصل الأول', 'الفصل الثاني', 'الفصل الصيفي'];

  @override
  void dispose() {
    _subjectNameController.dispose();
    _doctorNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg'],
        );
        if (result != null) {
          setState(() {
            _selectedFile = File(result.files.single.path!);
          });
        }
      } catch (e) {
        _showSnackBar('خطأ أثناء اختيار الملف: $e', isError: true);
      }
    } else if (status.isPermanentlyDenied) {
      _showSnackBarWithAction('تم رفض إذن الوصول للملفات بشكل دائم. يرجى تفعيله من إعدادات التطبيق.');
    } else {
      _showSnackBar('تم رفض إذن الوصول للملفات.', isError: true);
    }
  }

  void _submitForm() {
    if (_selectedFile == null) {
      _showSnackBar('الرجاء اختيار ملف أولاً.', isError: true);
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() { _isUploading = true; });
      Future.delayed(const Duration(seconds: 3), () {
        setState(() { _isUploading = false; });
        _showSnackBar('تم رفع الملف بنجاح (محاكاة).');
        setState(() {
          _selectedFile = null;
          _formKey.currentState!.reset();
          _selectedCollege = null;
          _selectedSpecialization = null;
          _selectedLevel = null;
          _selectedTerm = null;
        });
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? LibraryTheme.danger : LibraryTheme.success,
      ),
    );
  }

  void _showSnackBarWithAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'فتح الإعدادات',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('رفع ملف جديد'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              child: const Icon(Icons.person, color: primaryColor),
            ),
          ),
        ],
      ),
      body: _isUploading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 20),
            Text('جارٍ رفع الملف...', style: TextStyle(fontSize: 16, color: textColor)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickFile,
                child: DottedBorder(
                  color: LibraryTheme.muted,
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: LibraryTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _selectedFile == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 50, color: LibraryTheme.muted),
                        const SizedBox(height: 12),
                        const Text('اضغط هنا لاختيار ملف', style: TextStyle(fontSize: 16, color: LibraryTheme.muted)),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getFileIcon(_selectedFile!.path),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(controller: _subjectNameController, label: 'اسم المادة', icon: Icons.book_outlined),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _doctorNameController, label: 'اسم الدكتور', icon: Icons.person_outline),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown(hint: 'الكلية', icon: Icons.school_outlined, value: _selectedCollege, items: _colleges, onChanged: (val) => setState(() => _selectedCollege = val))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown(hint: 'التخصص', icon: Bootstrap.rulers, value: _selectedSpecialization, items: _specializations, onChanged: (val) => setState(() => _selectedSpecialization = val))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown(hint: 'المستوى', icon: Icons.bar_chart_outlined, value: _selectedLevel, items: _levels, onChanged: (val) => setState(() => _selectedLevel = val))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown(hint: 'الترم', icon: Icons.calendar_today_outlined, value: _selectedTerm, items: _terms, onChanged: (val) => setState(() => _selectedTerm = val))),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _descriptionController, label: 'وصف إضافي للملف (اختياري)', icon: Icons.description_outlined, isRequired: false, maxLines: 3),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('تأكيد الرفع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String label, required IconData icon, bool isRequired = true, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: LibraryTheme.surface,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({required String hint, required IconData icon, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: LibraryTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      ),
      hint: Text(hint, overflow: TextOverflow.ellipsis),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'مطلوب' : null,
    );
  }

  Widget _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf': return const Icon(FontAwesome.file_pdf, color: LibraryTheme.danger, size: 40);
      case 'doc': case 'docx': return const Icon(FontAwesome.file_word, color: LibraryTheme.primary, size: 40);
      case 'png': case 'jpg': case 'jpeg': return const Icon(FontAwesome.file_image, color: LibraryTheme.accent, size: 40);
      default: return const Icon(FontAwesome.file, color: LibraryTheme.muted, size: 40);
    }
  }
}
