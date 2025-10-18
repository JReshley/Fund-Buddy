import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../entity/transaction.dart';
import '../../entity/transaction_database.dart';
import '../../entity/user_profile.dart';
import '../../supabase_config.dart';
import 'dart:io';

//TODO: When creating a transction, change the createdBy to the full name of the creator

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({Key? key}) : super(key: key);

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  TransactionDatabase db = TransactionDatabase();
  
  // User profile state variables
  UserProfile? userProfile;
  bool isLoadingUser = true;
  // Image picker instance for document upload
  Future<void> _pickImage() async {
    final _picker = ImagePicker();

    // pick from gallery
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    // update image preview
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _imageFile = File(image.path);
        if (!kIsWeb) {
          _imageFile = File(image.path);
        }
      });
    }
  }

  // Method to fetch user profile data using UserProfile class
  Future<void> _fetchUserProfile() async {
    try {
      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser != null) {
        // Use UserProfile.getCurrentUser method for consistency
        final profile = await UserProfile.getCurrentUser(authUser.id);
        
        if (mounted) {
          setState(() {
            userProfile = profile;
            isLoadingUser = false;
          });
          // Fetch noteTitles after user profile is loaded
          _fetchNoteTitles();
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (mounted) {
        setState(() {
          isLoadingUser = false;
        });
      }
    }
  }

  // Method to upload image to Supabase storage
  Future<String?> uploadImage() async {
    try {
      if (_selectedImage == null) return null;

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bytes = await _selectedImage!.readAsBytes();
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      print('Uploading image with fileName: $fileName'); // Debug log

      // Upload file to storage
      await SupabaseConfig.client.storage
          .from('transaction-documents')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from('transaction-documents')
          .getPublicUrl(fileName);

      print('Image uploaded successfully. URL: $publicUrl'); // Debug log
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // Text editing controllers for form inputs
  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController disclosureController = TextEditingController();

  // UI styling constants
  static const double inputFontSize = 14.0; // Consistent font size for all input fields

  // State variables for dropdown selections
  String? selectedActivity;      // Stores the selected activity type
  String? selectedNoteTitle;     // Stores the selected note title/event name
  File? _imageFile;            // Holds the selected image file for document upload (mobile/desktop)
  XFile? _selectedImage;       // Holds the selected image for all platforms
  
  // State variables for noteTitle dropdown
  List<String> noteTitleOptions = [];
  bool isLoadingNoteTitles = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user profile when page loads
  }

  // Method to fetch unique noteTitles from current user's organization
  Future<void> _fetchNoteTitles() async {
    if (userProfile?.orgID == null) return;
    
    setState(() {
      isLoadingNoteTitles = true;
    });
    
    try {
      final response = await SupabaseConfig.client
          .from('transactions')
          .select('noteTitle')
          .eq('orgID', userProfile!.orgID!)
          .not('noteTitle', 'is', null);
      
      // Extract unique noteTitle values
      Set<String> uniqueNoteTitles = {};
      for (var item in response) {
        final noteTitle = item['noteTitle'] as String?;
        if (noteTitle != null && noteTitle.isNotEmpty) {
          uniqueNoteTitles.add(noteTitle);
        }
      }
      
      if (mounted) {
        setState(() {
          noteTitleOptions = uniqueNoteTitles.toList()..sort();
          noteTitleOptions.add('Add New...'); // Add option to create new noteTitle
          isLoadingNoteTitles = false;
        });
      }
    } catch (e) {
      print('Error fetching noteTitles: $e');
      if (mounted) {
        setState(() {
          noteTitleOptions = ['Add New...'];
          isLoadingNoteTitles = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    dateController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    disclosureController.dispose();
    super.dispose();
  }

  // Method to show dialog for adding new noteTitle
  void _showAddNoteTitleDialog() {
    final TextEditingController newNoteTitleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add New Note Title',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: newNoteTitleController,
            decoration: const InputDecoration(
              hintText: 'Enter new note title/event name',
              hintStyle: TextStyle(
                fontFamily: 'Space Grotesk',
                color: Color(0xFF757575),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  color: Color(0xFF4F4F4F),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = newNoteTitleController.text.trim();
                if (newTitle.isNotEmpty && !noteTitleOptions.contains(newTitle)) {
                  setState(() {
                    noteTitleOptions.insert(noteTitleOptions.length - 1, newTitle); // Insert before 'Add New...'
                    selectedNoteTitle = newTitle;
                  });
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with back button and title
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: const [
            Icon(Icons.add_circle_rounded, color: Color(0xFF64B5F6)),
            SizedBox(width: 8),
            Text(
              "Add New Transaction",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show loading indicator while fetching user profile
            if (isLoadingUser)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF64B5F6),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Loading user profile...",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Page description
            const Text(
              "Enter the details for your new financial transaction.",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF4F4F4F),
              ),
            ),
            
            // Show user organization info when loaded
            if (!isLoadingUser && userProfile != null)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF64B5F6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF64B5F6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Creating transaction for: ${userProfile!.username ?? 'Unknown User'} (Org ID: ${userProfile!.orgID})",
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 12,
                          color: Color(0xFF64B5F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),

            // === ATTACHED DOCUMENT SECTION ===
            // Allows users to upload or take a photo of transaction receipt/document
            const Text(
              "Attached Document",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F4F4F),
              ),
            ),
            const SizedBox(height: 10),
            // Clickable container for document upload
            _selectedImage != null 
            ? GestureDetector(
                onTap: _pickImage,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7, // Max 70% of screen height
                    minHeight: 120,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF64B5F6), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path, 
                            fit: BoxFit.contain, // Show full image
                            width: double.infinity,
                          )
                        : Image.file(
                            _imageFile!, 
                            fit: BoxFit.contain, // Show full image
                            width: double.infinity,
                          ),
                  ),
                ),
              )
            : GestureDetector(
              onTap: _pickImage, 
              child: Container(
                height: 120,
                width: double.infinity,
                // Styled container with border and shadow for upload area
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFBDBDBD),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                // Upload area content with icon and instruction text
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    // Upload icon
                    Icon(
                      Icons.upload_file,
                      size: 40,
                      color: Color(0xFF757575),
                    ),
                    SizedBox(height: 8),
                    // Instruction text for users
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Click to upload or take image here",
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === TYPE OF ACTIVITY SECTION ===
            // Dropdown for selecting the type of financial activity
            const Text(
              "Type of Activity",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F4F4F),
              ),
            ),
            const SizedBox(height: 10),
            // Full-width dropdown
            Container(
              width: double.infinity,
              // Styled container for dropdown
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              // Dropdown for activity selection
              child: DropdownButtonFormField<String>(
                value: selectedActivity,
                isExpanded: true,
                menuMaxHeight: 200,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                hint: const Text(
                  "Select activity",
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: inputFontSize,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF757575),
                  ),
                ),
                items: ["Receipt", "Disbursement"]
                    .map(
                      (choice) => DropdownMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice, // Removed .toUpperCase()
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: inputFontSize,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                // Update selected activity when user makes a choice
                onChanged: (value) {
                  setState(() {
                    selectedActivity = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // === DATE & AMOUNT SECTION ===
            // Vertically stacked date and amount input fields
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DATE INPUT FIELD
                const Text(
                  "Date",
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F4F4F),
                  ),
                ),
                const SizedBox(height: 10),
                // Date input container with date picker functionality
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  // Read-only text field that opens date picker when tapped
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      hintText: "Select date",
                      hintStyle: TextStyle(
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.normal,
                      fontSize: inputFontSize,
                    ),
                    readOnly: true, // Prevents keyboard input, only allows date picker
                    // Show date picker when field is tapped
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000), // Minimum selectable date
                        lastDate: DateTime(2101),  // Maximum selectable date
                      );
                      // Update the text field with selected date in ISO format
                      if (pickedDate != null) {
                        dateController.text = pickedDate.toIso8601String().substring(0, 10);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // AMOUNT INPUT FIELD
                const Text(
                  "Amount",
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F4F4F),
                  ),
                ),
                const SizedBox(height: 10),
                // Amount input container with peso currency prefix
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  // Numeric input field for transaction amount
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number, // Show numeric keyboard
                    decoration: const InputDecoration(
                      prefixText: "₱ ", // Philippine peso currency symbol
                      prefixStyle: TextStyle(
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.normal,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      hintText: "Enter amount",
                      hintStyle: TextStyle(
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.normal,
                      fontSize: inputFontSize,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // === DESCRIPTION SECTION ===
            // Text field for transaction description/details
            const Text(
              "Description",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F4F4F),
              ),
            ),
            const SizedBox(height: 10),
            // Description input container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              // Single-line text field for brief transaction description
              child: TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  hintText: "e.g., Materials for booth design",
                  hintStyle: TextStyle(
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.normal,
                  fontSize: inputFontSize,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Note Title/Event Name
            const Text(
              "Note Title/Event Name",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F4F4F),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: selectedNoteTitle,
                isExpanded: true,
                menuMaxHeight: 200,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                hint: Text(
                  isLoadingNoteTitles ? "Loading..." : "Select note title/event name",
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: inputFontSize,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF757575),
                  ),
                ),
                items: noteTitleOptions
                    .map(
                      (choice) => DropdownMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice,
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: inputFontSize,
                            fontWeight: FontWeight.normal,
                            color: choice == 'Add New...' ? const Color(0xFF64B5F6) : const Color(0xFF757575),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == 'Add New...') {
                    _showAddNoteTitleDialog();
                  } else {
                    setState(() {
                      selectedNoteTitle = value;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // Disclosure
            const Text(
              "Disclosure",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F4F4F),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: disclosureController,
                maxLines: 4,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  hintText:
                      "Describe who benefited, the purpose, details of items, and how the transaction occurred.",
                  hintStyle: TextStyle(
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.normal,
                  fontSize: inputFontSize,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Action buttons at the bottom
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF64B5F6)),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: Color(0xFF64B5F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Save button
                Expanded(
                  child: ElevatedButton(
                    // Disable button while loading user profile or if user profile failed to load
                    onPressed: (isLoadingUser || userProfile == null) ? null : () async {
                      // Get current user ID from Supabase
                      final user = SupabaseConfig.client.auth.currentUser;
                      
                      if (user == null) {
                        // Show error if user is not logged in
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to save transactions'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Validate required fields
                      if (dateController.text.isEmpty || amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in date and amount'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        final currentUserID = user.id;
                        final now = DateTime.now();
                        
                        // Upload image if one is selected
                        String? uploadedImageUrl;
                        if (_selectedImage != null) {
                          print('Image selected, starting upload...'); // Debug log
                          uploadedImageUrl = await uploadImage();
                          print('Upload result: $uploadedImageUrl'); // Debug log
                        } else {
                          print('No image selected'); // Debug log
                        }
                        
                        // Parse date safely (date only, no time)
                        DateTime? transactionDate;
                        try {
                          final parsed = DateTime.parse(dateController.text);
                          // Create date with only year, month, day (no time)
                          transactionDate = DateTime(parsed.year, parsed.month, parsed.day);
                        } catch (e) {
                          // If parsing fails, show error and return
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid date format. Please select a date again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Check if user profile is loaded and has orgID
                        if (userProfile?.orgID == null) {
                          print('DEBUG: userProfile is null: ${userProfile == null}');
                          print('DEBUG: userProfile.orgID is null: ${userProfile?.orgID == null}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User organization not found. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Debug logging before transaction creation
                        print('DEBUG: About to create transaction with:');
                        print('  - userProfile: ${userProfile != null ? "loaded" : "null"}');
                        print('  - orgID: ${userProfile?.orgID}');
                        print('  - currentUserID: $currentUserID');

                        Transaction newTransaction = Transaction(
                          userID: currentUserID,
                          typeOfActivity: selectedActivity ?? '',
                          date: transactionDate,
                          amount: double.tryParse(amountController.text) ?? 0.0,
                          description: descriptionController.text,
                          noteTitle: selectedNoteTitle ?? '',
                          disclosure: disclosureController.text,
                          createdBy: userProfile?.username ?? currentUserID,
                          updatedBy: userProfile?.username ?? currentUserID,
                          createdAt: now,
                          updatedAt: now,
                          imageUrl: uploadedImageUrl ?? '',
                          isUpdated: false,
                          orgID: userProfile!.orgID!, // Use actual orgID from user profile
                        );

                        // Save transaction to database
                        await db.createTransaction(newTransaction);
                        
                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction saved successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        // Show error message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving transaction: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isLoadingUser || userProfile == null) 
                          ? Colors.grey[400] 
                          : const Color(0xFF64B5F6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isLoadingUser 
                          ? "Loading..."
                          : userProfile == null 
                              ? "User Profile Required"
                              : "Save Transaction",
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}