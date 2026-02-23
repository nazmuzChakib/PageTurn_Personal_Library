import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart
import 'package:cached_network_image/cached_network_image.dart'; // Offline Image
import 'package:url_launcher/url_launcher.dart'; // Link Launcher

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(BookTrackerApp(prefs: prefs));
}

// --- 1. Data model ---
class Book {
  String id;
  String title;
  String author;
  String category;
  bool isBorrowed;
  bool isRead;
  bool isWishlist;
  String? borrowerName;
  String? borrowerContact;
  DateTime? borrowDate;

  int? pages;
  bool isTranslated;
  String? publisher;
  String? series;
  String? coverImagePath;
  String? coverUrl;
  String? notes;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    this.isBorrowed = false,
    this.isRead = false,
    this.isWishlist = false,
    this.borrowerName,
    this.borrowerContact,
    this.borrowDate,
    this.pages,
    this.isTranslated = false,
    this.publisher,
    this.series,
    this.coverImagePath,
    this.coverUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'category': category,
    'isBorrowed': isBorrowed,
    'isRead': isRead,
    'isWishlist': isWishlist,
    'borrowerName': borrowerName,
    'borrowerContact': borrowerContact,
    'borrowDate': borrowDate?.toIso8601String(),
    'pages': pages,
    'isTranslated': isTranslated,
    'publisher': publisher,
    'series': series,
    'coverImagePath': coverImagePath,
    'coverUrl': coverUrl,
    'notes': notes,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    category: json['category'],
    isBorrowed: json['isBorrowed'] ?? false,
    isRead: json['isRead'] ?? false,
    isWishlist: json['isWishlist'] ?? false,
    borrowerName: json['borrowerName'],
    borrowerContact: json['borrowerContact'],
    borrowDate: json['borrowDate'] != null ? DateTime.parse(json['borrowDate']) : null,
    pages: json['pages'],
    isTranslated: json['isTranslated'] ?? false,
    publisher: json['publisher'],
    series: json['series'],
    coverImagePath: json['coverImagePath'],
    coverUrl: json['coverUrl'],
    notes: json['notes'],
  );
}

// --- 2. App settings controller ---
class BookTrackerApp extends StatefulWidget {
  final SharedPreferences prefs;
  const BookTrackerApp({super.key, required this.prefs});

  @override
  State<BookTrackerApp> createState() => _BookTrackerAppState();
}

class _BookTrackerAppState extends State<BookTrackerApp> {
  late bool _isDarkMode;
  late String _language;
  late double _textScale;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefs.getBool('isDarkMode') ?? false;
    _language = widget.prefs.getString('language') ?? 'bn';
    _textScale = widget.prefs.getDouble('textScale') ?? 1.0;
  }

  void _toggleTheme(bool value) {
    setState(() => _isDarkMode = value);
    widget.prefs.setBool('isDarkMode', value);
  }

  void _changeLanguage(String lang) {
    setState(() => _language = lang);
    widget.prefs.setString('language', lang);
  }

  void _changeTextScale(double value) {
    setState(() => _textScale = value);
    widget.prefs.setDouble('textScale', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _language == 'bn' ? 'পিপিএল বুক ট্র্যাকার' : 'PPL Book Tracker',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 14 * _textScale),
          titleMedium: TextStyle(fontSize: 16 * _textScale),
          titleLarge: TextStyle(fontSize: 22 * _textScale),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 14 * _textScale),
          titleMedium: TextStyle(fontSize: 16 * _textScale),
          titleLarge: TextStyle(fontSize: 22 * _textScale),
        ),
      ),
      home: LibraryHomePage(
        language: _language,
        isDarkMode: _isDarkMode,
        textScale: _textScale,
        onThemeChanged: _toggleTheme,
        onLanguageChanged: _changeLanguage,
        onTextScaleChanged: _changeTextScale,
      ),
    );
  }
}

// --- 3. Localization Helper ---
class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'bn': {
      'app_title': 'পিপিএল বুক ট্র্যাকার',
      'home': 'হোম পেজ',
      'tab_dashboard': 'ড্যাশবোর্ড',
      'tab_all': 'সব বই',
      'tab_borrowed': 'ধার',
      'tab_wishlist': 'উইশলিস্ট',
      'add_book': 'বই যোগ করুন',
      'add_manual': 'ম্যানুয়ালি যোগ করুন',
      'add_isbn': 'ISBN দিয়ে যোগ করুন',
      'enter_isbn': 'বইয়ের ISBN নম্বর দিন',
      'fetching': 'তথ্য খোঁজা হচ্ছে...',
      'isbn_not_found': 'বইটি পাওয়া যায়নি!',
      'dashboard_stats': 'লাইব্রেরি পরিসংখ্যান',
      'author_groups': 'লেখকদের তালিকা',
      'total_books': 'মোট বই',
      'read_books': 'পড়া হয়েছে',
      'unread_books': 'পড়া বাকি',
      'edit_book': 'বই এডিট করুন',
      'settings': 'সেটিংস',
      'dark_mode': 'ডার্ক মোড',
      'language': 'ভাষা',
      'font_size': 'ফন্ট সাইজ',
      'about': 'অ্যাপ সম্পর্কে',
      'app_desc': 'অ্যাপ বর্ণনা',
      'view_source': 'সোর্স কোড দেখুন',
      'details': 'বইয়ের বিস্তারিত',
      'status': 'অবস্থা',
      'available': 'আপনার কাছে আছে',
      'borrowed': 'ধার দেওয়া হয়েছে',
      'read_status': 'পড়া শেষ হয়েছে?',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'lend_book': 'ধার দিন',
      'return_book': 'ফেরত নিন',
      'borrower_name': 'গ্রহীতার নাম',
      'borrower_contact': 'কন্টাক্ট নম্বর',
      'borrower_name_hint': 'যিনি বই নিচ্ছেন',
      'save': 'সেভ করুন',
      'cancel': 'বাতিল',
      'delete': 'মুছে ফেলুন',
      'delete_msg': 'বইটি মুছে ফেলা হয়েছে',
      'empty_list': 'আপনার সংগ্রহে এখনো কোনো বই নেই!\nনতুন বই যোগ করতে নিচের বাটনে ক্লিক করুন।',
      'empty_borrowed': 'বর্তমানে কোনো বই ধার দেওয়া নেই।',
      'empty_wishlist': 'উইশলিস্টে কোনো বই নেই।',
      'book_name': 'বইয়ের নাম',
      'author_name': 'লেখকের নাম',
      'category': 'ধরণ',
      'date': 'তারিখ',
      'success_add': 'বইটি সফলভাবে যোগ করা হয়েছে!',
      'success_edit': 'বইয়ের তথ্য আপডেট করা হয়েছে!',
      'pages': 'পৃষ্ঠা সংখ্যা',
      'is_translated': 'অনুবাদ বই?',
      'publisher': 'প্রকাশনী (ঐচ্ছিক)',
      'series': 'সিরিজ (ঐচ্ছিক)',
      'notes': 'নোট বা ডকুমেন্ট (ঐচ্ছিক)',
      'pick_image': 'প্রচ্ছদ যোগ করুন',
      'camera': 'ক্যামেরা',
      'gallery': 'গ্যালারি',
      'is_wishlist': 'উইশলিস্টে যোগ করুন?',
      'return_confirm': '%s কি বইটি ফেরত দিয়েছে?',
      'search_hint': 'বইয়ের নাম, লেখক, ধরন খুঁজুন...',
      'desc_text': 'এটি একটি ব্যক্তিগত লাইব্রেরি ম্যানেজমেন্ট অ্যাপ। এর মাধ্যমে আপনি আপনার বইয়ের হিসাব রাখতে পারবেন, কাকে ধার দিয়েছেন তা ট্র্যাক করতে পারবেন এবং বইয়ের তালিকা সুন্দরভাবে গুছিয়ে রাখতে পারবেন।',
    },
    'en': {
      'app_title': 'PPL Book Tracker',
      'home': 'Home',
      'tab_dashboard': 'Dashboard',
      'tab_all': 'All Books',
      'tab_borrowed': 'Lent',
      'tab_wishlist': 'Wishlist',
      'add_book': 'Add Book',
      'add_manual': 'Add Manually',
      'add_isbn': 'Add via ISBN',
      'enter_isbn': 'Enter Book ISBN',
      'fetching': 'Fetching data...',
      'isbn_not_found': 'Book not found!',
      'dashboard_stats': 'Library Statistics',
      'author_groups': 'Authors List',
      'total_books': 'Total Books',
      'read_books': 'Read',
      'unread_books': 'Unread',
      'edit_book': 'Edit Book',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'font_size': 'Font Size',
      'about': 'About App',
      'app_desc': 'App Description',
      'view_source': 'View Source Code',
      'details': 'Book Details',
      'status': 'Status',
      'available': 'Available',
      'borrowed': 'Borrowed',
      'read_status': 'Finished Reading?',
      'yes': 'Yes',
      'no': 'No',
      'lend_book': 'Lend Book',
      'return_book': 'Return Book',
      'borrower_name': 'Borrower Name',
      'borrower_contact': 'Contact No',
      'borrower_name_hint': 'Person taking the book',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_msg': 'Book deleted successfully',
      'empty_list': 'No books in your collection yet!\nClick the button below to add new ones.',
      'empty_borrowed': 'No books currently borrowed.',
      'empty_wishlist': 'No books in wishlist.',
      'book_name': 'Book Title',
      'author_name': 'Author Name',
      'category': 'Category',
      'date': 'Date',
      'success_add': 'Book added successfully!',
      'success_edit': 'Book details updated!',
      'pages': 'Pages',
      'is_translated': 'Is Translated?',
      'publisher': 'Publisher (Optional)',
      'series': 'Series (Optional)',
      'notes': 'Notes/Docs (Optional)',
      'pick_image': 'Add Cover',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'is_wishlist': 'Add to Wishlist?',
      'return_confirm': 'Did %s return the book?',
      'search_hint': 'Search by title, author, category...',
      'desc_text': 'This is a personal library management app. You can track your books, manage lending history, and organize your collection efficiently.',
    },
  };

  static String get(String lang, String key) {
    return values[lang]?[key] ?? key;
  }
}

// --- 4. Home Page ---
class LibraryHomePage extends StatefulWidget {
  final String language;
  final bool isDarkMode;
  final double textScale;
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;
  final Function(double) onTextScaleChanged;

  const LibraryHomePage({
    super.key,
    required this.language,
    required this.isDarkMode,
    required this.textScale,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onTextScaleChanged,
  });

  @override
  State<LibraryHomePage> createState() => _LibraryHomePageState();
}

class _LibraryHomePageState extends State<LibraryHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  List<Book> _books = [];
  late SharedPreferences _prefs;

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Background Image URL
  final String _sidebarImageUrl = 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?q=80&w=800&auto=format&fit=crop';
  // GitHub Repo URL (Example - Change this to your real repo)
  final String _sourceCodeUrl = 'https://github.com/nazmuzChakib/PPLBookTracker';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSavedBooks();
  }

  Future<void> _loadSavedBooks() async {
    _prefs = await SharedPreferences.getInstance();
    final String? booksJson = _prefs.getString('saved_books_list');
    if (booksJson != null) {
      final List<dynamic> decodedList = jsonDecode(booksJson);
      setState(() {
        _books = decodedList.map((item) => Book.fromJson(item)).toList();
      });
    }
  }

  void _saveBooksLocally() {
    final String encodedList = jsonEncode(_books.map((b) => b.toJson()).toList());
    _prefs.setString('saved_books_list', encodedList);
  }

  Future<String> _saveImagePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = path.basename(imagePath);
    final imageFile = File(imagePath);
    final newImage = await imageFile.copy('${directory.path}/$name');
    return newImage.path;
  }

  Future<String?> _pickAndCropImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return null;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Cover',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio4x3,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]),
      ],
    );

    if (croppedFile != null) {
      return await _saveImagePermanently(croppedFile.path);
    }
    return null;
  }

  void _showImageSourceDialog(Function(String) onImagePicked) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(txt('camera')),
              onTap: () async {
                Navigator.pop(context);
                final p = await _pickAndCropImage(ImageSource.camera);
                if (p != null) onImagePicked(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(txt('gallery')),
              onTap: () async {
                Navigator.pop(context);
                final p = await _pickAndCropImage(ImageSource.gallery);
                if (p != null) onImagePicked(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  String txt(String key) => AppStrings.get(widget.language, key);

  void _navigateAndDisplaySettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          language: widget.language,
          isDarkMode: widget.isDarkMode,
          textScale: widget.textScale,
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
          onTextScaleChanged: widget.onTextScaleChanged,
        ),
      ),
    );
  }

  void _navigateAndShowDetails(Book book) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BookDetailsPage(
          book: book,
          language: widget.language,
          onUpdate: () {
            setState(() {});
            _saveBooksLocally();
          },
          onDelete: () {
            setState(() => _books.remove(book));
            _saveBooksLocally();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt('delete_msg'))));
          },
          onPickImage: _showImageSourceDialog,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
    setState(() {});
  }

  // --- External URL Launcher ---
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
    }
  }

  // --- Show App Description ---
  void _showAppDescription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.info, color: Colors.teal), SizedBox(width: 10), Text(txt('app_desc'))]),
        content: Text(txt('desc_text')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  // --- ISBN Fetch Logic ---
  Future<void> _fetchBookByISBN(String isbn) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Text(txt('fetching'))]),
      ),
    );

    try {
      final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
      final response = await http.get(url);
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          Book fetchedBook = Book(
            id: DateTime.now().toString(),
            title: volumeInfo['title'] ?? '',
            author: (volumeInfo['authors'] as List?)?.join(', ') ?? '',
            category: (volumeInfo['categories'] as List?)?.join(', ') ?? 'সাধারণ',
            pages: volumeInfo['pageCount'],
            publisher: volumeInfo['publisher'] ?? '',
            coverUrl: volumeInfo['imageLinks']?['thumbnail']?.replaceAll('http:', 'https:'),
          );
          _showAddBookDialog(prefilledBook: fetchedBook);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt('isbn_not_found'))));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt('isbn_not_found'))));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showISBNInputDialog() {
    final isbnController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(txt('add_isbn')),
        content: TextField(
          controller: isbnController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: txt('enter_isbn'), border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(txt('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (isbnController.text.isNotEmpty) {
                Navigator.pop(context);
                _fetchBookByISBN(isbnController.text.trim());
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.teal),
            title: Text(txt('add_manual')),
            onTap: () { Navigator.pop(context); _showAddBookDialog(); },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
            title: Text(txt('add_isbn')),
            onTap: () { Navigator.pop(context); _showISBNInputDialog(); },
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog({Book? prefilledBook}) {
    final titleController = TextEditingController(text: prefilledBook?.title);
    final authorController = TextEditingController(text: prefilledBook?.author);
    final categoryController = TextEditingController(text: prefilledBook?.category);
    final pagesController = TextEditingController(text: prefilledBook?.pages?.toString());
    final publisherController = TextEditingController(text: prefilledBook?.publisher);
    final seriesController = TextEditingController(text: prefilledBook?.series);
    final notesController = TextEditingController(text: prefilledBook?.notes);

    bool isTranslated = prefilledBook?.isTranslated ?? false;
    bool isWishlist = prefilledBook?.isWishlist ?? (_tabController.index == 3);
    String? imagePath = prefilledBook?.coverImagePath;
    String? imageUrl = prefilledBook?.coverUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(txt('add_book'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _showImageSourceDialog((path) {
                        setModalState(() { imagePath = path; imageUrl = null; });
                      });
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: imagePath != null
                          ? FileImage(File(imagePath!)) as ImageProvider
                          : (imageUrl != null ? NetworkImage(imageUrl!) : null),
                      child: (imagePath == null && imageUrl == null) ? Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).colorScheme.primary) : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: titleController, decoration: InputDecoration(labelText: txt('book_name'), prefixIcon: const Icon(Icons.book))),
                  TextField(controller: authorController, decoration: InputDecoration(labelText: txt('author_name'), prefixIcon: const Icon(Icons.person))),
                  Row(children: [
                    Expanded(child: TextField(controller: categoryController, decoration: InputDecoration(labelText: txt('category'), prefixIcon: const Icon(Icons.category)))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: pagesController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: txt('pages'), prefixIcon: const Icon(Icons.pages)))),
                  ]),
                  TextField(controller: publisherController, decoration: InputDecoration(labelText: txt('publisher'), prefixIcon: const Icon(Icons.business))),
                  TextField(controller: seriesController, decoration: InputDecoration(labelText: txt('series'), prefixIcon: const Icon(Icons.collections_bookmark))),
                  TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(labelText: txt('notes'), prefixIcon: const Icon(Icons.note))),
                  Row(children: [
                    Checkbox(value: isTranslated, onChanged: (val) => setModalState(() => isTranslated = val!)),
                    Text(txt('is_translated')),
                    const Spacer(),
                    Checkbox(value: isWishlist, onChanged: (val) => setModalState(() => isWishlist = val!)),
                    Text(txt('is_wishlist')),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(txt('cancel'))),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            setState(() {
                              _books.add(Book(
                                id: DateTime.now().toString(),
                                title: titleController.text,
                                author: authorController.text.isEmpty ? "অজানা" : authorController.text,
                                category: categoryController.text.isEmpty ? "সাধারণ" : categoryController.text,
                                pages: int.tryParse(pagesController.text),
                                isTranslated: isTranslated,
                                publisher: publisherController.text,
                                series: seriesController.text,
                                coverImagePath: imagePath,
                                coverUrl: imageUrl,
                                notes: notesController.text,
                                isWishlist: isWishlist,
                              ));
                            });
                            _saveBooksLocally();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt('success_add'))));
                          }
                        },
                        child: Text(txt('save')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Book> _getFilteredBooks(List<Book> sourceList) {
    if (_searchQuery.isEmpty) return sourceList;
    return sourceList.where((book) {
      final query = _searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)),
            child: Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.5)),
          ),
        ],
      ),
    );
  }

  // --- NEW: Dashboard with Pie Chart ---
  Widget _buildDashboardView() {
    final regularBooks = _books.where((b) => !b.isWishlist).toList();
    final readCount = regularBooks.where((b) => b.isRead).length;
    final borrowedCount = regularBooks.where((b) => b.isBorrowed).length;
    final unreadCount = regularBooks.length - (readCount + borrowedCount); // Just a rough logic for chart

    // Grouping
    Map<String, List<Book>> authorGroups = {};
    for (var book in regularBooks) {
      if (!authorGroups.containsKey(book.author)) { authorGroups[book.author] = []; }
      authorGroups[book.author]!.add(book);
    }

    // Pie Chart Data
    List<PieChartSectionData> sections = [];
    if (regularBooks.isNotEmpty) {
      if (borrowedCount > 0) {
        sections.add(PieChartSectionData(
          color: Colors.redAccent, value: borrowedCount.toDouble(), title: '$borrowedCount',
          radius: 50, titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
      if (readCount > 0) {
        sections.add(PieChartSectionData(
          color: Colors.green, value: readCount.toDouble(), title: '$readCount',
          radius: 50, titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
      // Remaining (Unread or just Available)
      double remaining = (regularBooks.length - borrowedCount - readCount).toDouble();
      if (remaining > 0) {
        sections.add(PieChartSectionData(
          color: Colors.teal, value: remaining, title: '${remaining.toInt()}',
          radius: 50, titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(txt('dashboard_stats'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          if (regularBooks.isEmpty)
            _buildEmptyState("বই যোগ করুন", Icons.pie_chart)
          else
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.teal, "${txt('total_books')}: ${regularBooks.length}"),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.green, "${txt('read_books')}: $readCount"),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.redAccent, "${txt('borrowed')}: $borrowedCount"),
                    ],
                  )
                ],
              ),
            ),

          const SizedBox(height: 24),
          Text(txt('author_groups'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (authorGroups.isEmpty)
            const SizedBox()
          else
            ...authorGroups.entries.map((entry) {
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  shape: const Border(),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${entry.value.length} টি বই'),
                  children: entry.value.map((b) => ListTile(
                    title: Text(b.title),
                    subtitle: Text(b.category),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: () => _navigateAndShowDetails(b),
                  )).toList(),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = _getFilteredBooks(_books.where((b) => !b.isWishlist).toList());
    final borrowedBooks = _getFilteredBooks(_books.where((b) => b.isBorrowed && !b.isWishlist).toList());
    final wishBooks = _getFilteredBooks(_books.where((b) => b.isWishlist).toList());

    return Scaffold(
      appBar: AppBar(
        // টাইটেল এবং টেক্সট কালার সাদা করা হয়েছে যাতে ব্যাকগ্রাউন্ডের ওপর ভালো দেখা যায়
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white), // সাদা টেক্সট
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: txt('search_hint'),
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        )
            : Text(txt('app_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),

        centerTitle: !_isSearching,
        backgroundColor: Colors.transparent, // ট্রান্সপারেন্ট রাখতে হবে
        iconTheme: const IconThemeData(color: Colors.white), // আইকন সাদা

        // --- এই অংশটুকু নতুন অ্যাড করা হয়েছে (Background Image) ---
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              // অফলাইন সাপোর্টের জন্য CachedNetworkImageProvider ব্যবহার করা হলো
              image: CachedNetworkImageProvider(_sidebarImageUrl),
              fit: BoxFit.cover,
              // টেক্সট যাতে পড়া যায় তাই ছবির ওপর কালো আস্তরণ (Dark Filter)
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
            ),
          ),
        ),
        // -------------------------------------------------------

        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: Colors.white, // সিলেক্টেড ট্যাব সাদা
          unselectedLabelColor: Colors.white70, // আনসিলেক্টেড ট্যাব আবছা সাদা
          indicatorColor: Colors.white, // ইন্ডিকেটর সাদা
          tabs: [
            Tab(icon: const Icon(Icons.pie_chart), text: txt('tab_dashboard')),
            Tab(icon: Badge(label: Text('${allBooks.length}'), child: const Icon(Icons.library_books)), text: txt('tab_all')),
            Tab(icon: Badge(label: Text('${borrowedBooks.length}'), child: const Icon(Icons.handshake)), text: txt('tab_borrowed')),
            Tab(icon: Badge(label: Text('${wishBooks.length}'), child: const Icon(Icons.favorite)), text: txt('tab_wishlist')),
          ],
        ),
      ),

      // ড্রয়ার এবং বডির বাকি অংশ অপরিবর্তিত থাকবে...
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // আপনার আগের ড্রয়ার কোড...
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: _sidebarImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.teal, child: const Center(child: Icon(Icons.image, color: Colors.white54))),
                    errorWidget: (context, url, error) => Container(color: Colors.teal, child: const Center(child: Icon(Icons.broken_image, color: Colors.white54))),
                    color: Colors.black45,
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
                Positioned(
                  bottom: 20, left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.library_books, size: 30, color: Colors.teal),
                      ),
                      const SizedBox(height: 10),
                      Text(txt('app_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                )
              ],
            ),
            ListTile(leading: const Icon(Icons.home), title: Text(txt('home')), onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(txt('settings')),
              onTap: () { Navigator.pop(context); _navigateAndDisplaySettings(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(txt('app_desc')),
              onTap: () { Navigator.pop(context); _showAppDescription(); },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(txt('view_source')),
              onTap: () { Navigator.pop(context); _launchURL(_sourceCodeUrl); },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardView(),
          allBooks.isEmpty ? _buildEmptyState(txt('empty_list'), Icons.auto_stories) : ListView.builder(itemCount: allBooks.length, itemBuilder: (ctx, i) => _buildBookCard(allBooks[i])),
          borrowedBooks.isEmpty ? _buildEmptyState(txt('empty_borrowed'), Icons.person_off) : ListView.builder(itemCount: borrowedBooks.length, itemBuilder: (ctx, i) => _buildBookCard(borrowedBooks[i])),
          wishBooks.isEmpty ? _buildEmptyState(txt('empty_wishlist'), Icons.favorite_border) : ListView.builder(itemCount: wishBooks.length, itemBuilder: (ctx, i) => _buildBookCard(wishBooks[i])),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        icon: const Icon(Icons.add),
        label: Text(txt('add_book')),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    ImageProvider? imageProvider;
    if (book.coverImagePath != null && File(book.coverImagePath!).existsSync()) {
      imageProvider = FileImage(File(book.coverImagePath!));
    } else if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      imageProvider = NetworkImage(book.coverUrl!);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        key: ValueKey(book.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) { setState(() => book.isRead = !book.isRead); _saveBooksLocally(); },
              backgroundColor: Colors.green, foregroundColor: Colors.white,
              icon: book.isRead ? Icons.remove_done : Icons.done_all, label: book.isRead ? 'Unread' : 'Read',
            ),
            SlidableAction(
              onPressed: (context) { setState(() => book.isWishlist = !book.isWishlist); _saveBooksLocally(); },
              backgroundColor: Colors.pink, foregroundColor: Colors.white,
              icon: book.isWishlist ? Icons.favorite_border : Icons.favorite, label: 'Wishlist',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                setState(() => _books.remove(book)); _saveBooksLocally();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt('delete_msg'))));
              },
              backgroundColor: Colors.red, foregroundColor: Colors.white, icon: Icons.delete, label: txt('delete'),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _navigateAndShowDetails(book),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Hero(
                  tag: 'cover_${book.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: book.isBorrowed ? Colors.red.shade100 : Colors.teal.shade100,
                    backgroundImage: imageProvider,
                    child: imageProvider == null ? Icon(book.isBorrowed ? Icons.person_remove : Icons.book, color: book.isBorrowed ? Colors.red : Colors.teal) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${book.author} • ${book.category}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (book.series != null && book.series!.isNotEmpty) Text('সিরিজ: ${book.series}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (book.isBorrowed) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text('${txt('borrowed')}: ${book.borrowerName}', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ),
                if (book.isRead && !book.isWishlist) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                if (book.isWishlist) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.favorite, color: Colors.pink, size: 20)),
                const SizedBox(width: 8),
                Icon(Icons.swipe_left, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 5. Book Details Page ---
class BookDetailsPage extends StatefulWidget {
  final Book book;
  final String language;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final Function(Function(String)) onPickImage;

  const BookDetailsPage({super.key, required this.book, required this.language, required this.onUpdate, required this.onDelete, required this.onPickImage});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  late bool _isRead;
  final _borrowerController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isRead = widget.book.isRead;
  }

  String txt(String key) => AppStrings.get(widget.language, key);

  void _showLendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(txt('lend_book')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('বই: ${widget.book.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _borrowerController, decoration: InputDecoration(labelText: txt('borrower_name'), hintText: txt('borrower_name_hint'), border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _contactController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: txt('borrower_contact'), prefixIcon: const Icon(Icons.phone), border: const OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(txt('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (_borrowerController.text.isNotEmpty) {
                setState(() {
                  widget.book.isBorrowed = true;
                  widget.book.borrowerName = _borrowerController.text;
                  widget.book.borrowerContact = _contactController.text;
                  widget.book.borrowDate = DateTime.now();
                });
                widget.onUpdate();
                Navigator.pop(context);
              }
            },
            child: Text(txt('save')),
          ),
        ],
      ),
    );
  }

  void _returnBook() {
    String message = txt('return_confirm').replaceAll('%s', widget.book.borrowerName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(txt('return_book')),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(txt('no'))),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.book.isBorrowed = false;
                widget.book.borrowerName = null;
                widget.book.borrowerContact = null;
                widget.book.borrowDate = null;
              });
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: Text(txt('yes')),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.book.title);
    final authorController = TextEditingController(text: widget.book.author);
    final categoryController = TextEditingController(text: widget.book.category);
    final pagesController = TextEditingController(text: widget.book.pages?.toString());
    final publisherController = TextEditingController(text: widget.book.publisher);
    final seriesController = TextEditingController(text: widget.book.series);
    final notesController = TextEditingController(text: widget.book.notes);

    bool isTranslated = widget.book.isTranslated;
    String? tempImagePath = widget.book.coverImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16, right: 16, top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(txt('edit_book'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      widget.onPickImage((path) {
                        setModalState(() {
                          tempImagePath = path;
                          widget.book.coverUrl = null;
                        });
                      });
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: tempImagePath != null && File(tempImagePath!).existsSync()
                          ? FileImage(File(tempImagePath!)) as ImageProvider
                          : (widget.book.coverUrl != null ? NetworkImage(widget.book.coverUrl!) : null),
                      child: (tempImagePath == null && widget.book.coverUrl == null) ? Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).colorScheme.primary) : null,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(controller: titleController, decoration: InputDecoration(labelText: txt('book_name'), prefixIcon: const Icon(Icons.book))),
                  TextField(controller: authorController, decoration: InputDecoration(labelText: txt('author_name'), prefixIcon: const Icon(Icons.person))),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: categoryController, decoration: InputDecoration(labelText: txt('category'), prefixIcon: const Icon(Icons.category)))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: pagesController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: txt('pages'), prefixIcon: const Icon(Icons.pages)))),
                    ],
                  ),
                  TextField(controller: publisherController, decoration: InputDecoration(labelText: txt('publisher'), prefixIcon: const Icon(Icons.business))),
                  TextField(controller: seriesController, decoration: InputDecoration(labelText: txt('series'), prefixIcon: const Icon(Icons.collections_bookmark))),
                  TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(labelText: txt('notes'), prefixIcon: const Icon(Icons.note))),

                  Row(
                    children: [
                      Checkbox(value: isTranslated, onChanged: (val) => setModalState(() => isTranslated = val!)),
                      Text(txt('is_translated')),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(txt('cancel'))),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            setState(() {
                              widget.book.title = titleController.text;
                              widget.book.author = authorController.text;
                              widget.book.category = categoryController.text;
                              widget.book.pages = int.tryParse(pagesController.text);
                              widget.book.publisher = publisherController.text;
                              widget.book.series = seriesController.text;
                              widget.book.notes = notesController.text;
                              widget.book.isTranslated = isTranslated;
                              widget.book.coverImagePath = tempImagePath;
                            });
                            widget.onUpdate();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt('success_edit'))));
                          }
                        },
                        child: Text(txt('save')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = widget.book.borrowDate != null
        ? "${widget.book.borrowDate!.day}/${widget.book.borrowDate!.month}/${widget.book.borrowDate!.year}"
        : "";

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusBgColor = widget.book.isBorrowed
        ? (isDark ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50)
        : (isDark ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50);

    Color statusBorderColor = widget.book.isBorrowed
        ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade200)
        : (isDark ? Colors.greenAccent.shade100 : Colors.green.shade200);

    Color statusTextColor = widget.book.isBorrowed
        ? (isDark ? Colors.red.shade200 : Colors.red.shade700)
        : (isDark ? Colors.green.shade200 : Colors.green.shade700);

    Widget coverWidget;
    if (widget.book.coverImagePath != null && File(widget.book.coverImagePath!).existsSync()) {
      coverWidget = Image.file(File(widget.book.coverImagePath!), height: 220, width: 150, fit: BoxFit.cover);
    } else if (widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty) {
      coverWidget = Image.network(widget.book.coverUrl!, height: 220, width: 150, fit: BoxFit.cover);
    } else {
      coverWidget = Container(
        height: 220, width: 150,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.menu_book, size: 80, color: Theme.of(context).primaryColor),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(txt('details')),
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: _showEditDialog),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'cover_${widget.book.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: coverWidget,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(widget.book.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text(widget.book.author, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Chip(label: Text(widget.book.category, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                      if (widget.book.isTranslated) Chip(label: Text(txt('is_translated'), style: const TextStyle(fontSize: 12))),
                      if (widget.book.pages != null) Chip(label: Text('${widget.book.pages} ${txt('pages')}', style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (widget.book.publisher != null && widget.book.publisher!.isNotEmpty)
              Text("প্রকাশনী: ${widget.book.publisher}", style: const TextStyle(fontSize: 16)),
            if (widget.book.series != null && widget.book.series!.isNotEmpty)
              Text("সিরিজ: ${widget.book.series}", style: const TextStyle(fontSize: 16)),
            if (widget.book.notes != null && widget.book.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.book.notes!, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),

            if (!widget.book.isWishlist) ...[
              SwitchListTile(
                title: Text(txt('read_status'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isRead ? 'পড়া হয়েছে' : 'পড়া বাকি আছে'),
                value: _isRead,
                onChanged: (val) {
                  setState(() {
                    _isRead = val;
                    widget.book.isRead = val;
                  });
                  widget.onUpdate();
                },
                secondary: Icon(_isRead ? Icons.mark_email_read : Icons.mark_email_unread, color: _isRead ? Colors.green : Colors.grey),
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(txt('status'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusBorderColor),
                ),
                child: Column(
                  children: [
                    Icon(widget.book.isBorrowed ? Icons.person_remove : Icons.check_circle, color: widget.book.isBorrowed ? Colors.redAccent : Colors.green, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      widget.book.isBorrowed ? txt('borrowed') : txt('available'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusTextColor),
                    ),
                    if (widget.book.isBorrowed) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Text('${txt('borrower_name')}: ${widget.book.borrowerName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      if (widget.book.borrowerContact != null && widget.book.borrowerContact!.isNotEmpty)
                        Text('${txt('borrower_contact')}: ${widget.book.borrowerContact}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${txt('date')}: $formattedDate', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: widget.book.isBorrowed ? _returnBook : _showLendDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.book.isBorrowed ? Colors.teal : Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(widget.book.isBorrowed ? Icons.download : Icons.upload),
                  label: Text(widget.book.isBorrowed ? txt('return_book') : txt('lend_book'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.book.isWishlist = false;
                    });
                    widget.onUpdate();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  icon: const Icon(Icons.library_add),
                  label: const Text('সংগ্রহে যোগ করুন', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- 6. Settings Page ---
class SettingsPage extends StatefulWidget {
  final String language;
  final bool isDarkMode;
  final double textScale;
  final Function(bool) onThemeChanged;
  final Function(String) onLanguageChanged;
  final Function(double) onTextScaleChanged;

  const SettingsPage({
    super.key,
    required this.language,
    required this.isDarkMode,
    required this.textScale,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onTextScaleChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentLanguage;
  late bool _currentDarkMode;
  late double _currentTextScale;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
    _currentDarkMode = widget.isDarkMode;
    _currentTextScale = widget.textScale;
  }

  String txt(String key) => AppStrings.get(_currentLanguage, key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(txt('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.language)),
                      const SizedBox(width: 16),
                      Text(txt('language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'bn', label: Text('বাংলা')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {_currentLanguage},
                      onSelectionChanged: (Set<String> newSelection) {
                        final val = newSelection.first;
                        setState(() => _currentLanguage = val);
                        widget.onLanguageChanged(val);
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: CircleAvatar(child: Icon(_currentDarkMode ? Icons.dark_mode : Icons.light_mode)),
              title: Text(txt('dark_mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
              value: _currentDarkMode,
              onChanged: (val) {
                setState(() => _currentDarkMode = val);
                widget.onThemeChanged(val);
              },
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.text_fields)),
                      const SizedBox(width: 16),
                      Text(txt('font_size'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _currentTextScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 10,
                    label: _currentTextScale.toStringAsFixed(1),
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      setState(() => _currentTextScale = val);
                      widget.onTextScaleChanged(val);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Small', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Normal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Large', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.info_outline)),
              title: Text(txt('about'), style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: txt('app_title'),
                  applicationVersion: '1.1.0 (Beta)',
                  applicationIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.library_books, size: 40, color: Theme.of(context).colorScheme.primary),
                  ),
                  applicationLegalese: 'Developed by nazmuzChakib\nTeam Cypher-Z\n© ${DateTime.now().year} All Rights Reserved.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}