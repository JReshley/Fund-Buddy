import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import 'package:image_picker/image_picker.dart';
import '../../entity/transaction.dart';
import '../../entity/transaction_database.dart';
import '../../entity/user_profile.dart';
import '../../supabase_config.dart';
import 'dart:io';

class UpdateTransactionPage extends StatefulWidget {
  final Transaction transaction;
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  
  const UpdateTransactionPage({Key? key, required this.transaction, required this.themeController, this.onThemeChanged,}) : super(key: key);

  @override
  State<UpdateTransactionPage> createState() => _UpdateTransactionPageState();
}

class _UpdateTransactionPageState extends State<UpdateTransactionPage> {
  TransactionDatabase db = TransactionDatabase();
  
  // User profile state variables
  UserProfile? userProfile;
  String? orgAbbreviation;
  bool isLoadingUser = true;
  // Image picker instance for document upload
  Future<void> _handleImageTap() async {
    // Check if there's an existing image (either selected or from transaction)
    bool hasExistingImage = _selectedImage != null || 
                           (widget.transaction.imageUrl != null && widget.transaction.imageUrl!.isNotEmpty);
    
    if (hasExistingImage) {
      // Show dialog to choose between view or change
      final choice = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF64B5F6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Receipt Image',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'What would you like to do?',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                color: Color(0xFF4F4F4F),
                fontSize: 14,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop('view'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF64B5F6)),
                        ),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: Color(0xFF64B5F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop('change'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
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
          );
        },
      );

      if (choice == 'view') {
        // Show full image in a dialog
        String? imageToShow;
        if (_selectedImage != null) {
          imageToShow = _selectedImage!.path;
        } else if (widget.transaction.imageUrl != null && widget.transaction.imageUrl!.isNotEmpty) {
          imageToShow = widget.transaction.imageUrl;
        }

        if (imageToShow != null) {
          final String displayImage = imageToShow;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb || displayImage.startsWith('http')
                            ? Image.network(
                                displayImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    color: Colors.black54,
                                    child: const Text(
                                      'Error loading image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(displayImage),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    color: Colors.black54,
                                    child: const Text(
                                      'Error loading image',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      } else if (choice == 'change') {
        await _pickImage();
      }
    } else {
      // No existing image, directly pick image
      await _pickImage();
    }
  }

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
        
        // Fetch organization abbreviation if user has orgID
        String? orgAbbr;
        if (profile?.orgID != null) {
          try {
            final orgDataList = await SupabaseConfig.client
                .from('organization')
                .select('abbreviation')
                .eq('orgID', profile!.orgID!);
            
            if (orgDataList.isNotEmpty) {
              orgAbbr = orgDataList[0]['abbreviation'] as String?;
            }
          } catch (e) {
            print('Error fetching organization: $e');
            orgAbbr = 'Unknown Org';
          }
        }
        
        if (mounted) {
          setState(() {
            userProfile = profile;
            orgAbbreviation = orgAbbr;
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

  // Upload image to Supabase Storage
  Future<String?> uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      // Get current user ID for unique file naming
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return null;
      }

      // Store old image URL to delete later
      String? oldImageUrl = widget.transaction.imageUrl;

      // Generate unique file name with timestamp and user ID
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'samples/$fileName';

      // Get image bytes for upload (works on all platforms)
      final bytes = await _selectedImage!.readAsBytes();
      print('Image bytes length: ${bytes.length}');

      // Upload image to Supabase storage using bytes
      await SupabaseConfig.client.storage
          .from('receipts-files')
          .uploadBinary(path, bytes);

      // Get the public URL of the uploaded file
      final imageUrl = SupabaseConfig.client.storage
          .from('receipts-files')
          .getPublicUrl(path);

      print('Image uploaded successfully. URL: $imageUrl');

      // Delete old image from storage if it exists and is different
      if (oldImageUrl != null && oldImageUrl.isNotEmpty && oldImageUrl != imageUrl) {
        try {
          // Extract the path from the old URL
          // URL format: https://[project].supabase.co/storage/v1/object/public/receipts-files/samples/filename.jpg
          final uri = Uri.parse(oldImageUrl);
          final pathSegments = uri.pathSegments;
          
          // Find the index of 'receipts-files' in the path
          final bucketIndex = pathSegments.indexOf('receipts-files');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            // Get everything after 'receipts-files/' as the file path
            final oldFilePath = pathSegments.sublist(bucketIndex + 1).join('/');
            print('Attempting to delete old image: $oldFilePath');
            
            await SupabaseConfig.client.storage
                .from('receipts-files')
                .remove([oldFilePath]);
            
            print('Old image deleted successfully');
          }
        } catch (e) {
          print('Error deleting old image: $e');
          // Continue even if deletion fails
        }
      }

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // State variables for dropdown selections
  String? selectedActivity;      // Stores the selected activity type
  String? selectedNoteTitle;     // Stores the selected note title/event name
  File? _imageFile;            // Holds the selected image file for document upload (mobile/desktop)
  XFile? _selectedImage;       // Holds the selected image for all platforms
  
  // State variables for noteTitle dropdown
  List<String> noteTitleOptions = ["Select Note Title"];
  bool isLoadingNoteTitles = false;
  
  // Text controllers for managing input field values
  final TextEditingController sellerNameController = TextEditingController();
  final TextEditingController receiptControlNumController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController disclosureController = TextEditingController();

  // Consistent font size for all input fields
  static const double inputFontSize = 14;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user profile when page loads
    _populateFields(); // Pre-populate fields with existing transaction data
  }

  // Method to populate form fields with existing transaction data
  void _populateFields() {
    // Pre-populate text controllers with existing data
    sellerNameController.text = widget.transaction.sellerName ?? '';
    receiptControlNumController.text = widget.transaction.receiptControlNum ?? '';
    dateController.text = widget.transaction.date?.toIso8601String().substring(0, 10) ?? '';
    amountController.text = widget.transaction.amount?.toString() ?? '';
    descriptionController.text = widget.transaction.description ?? '';
    disclosureController.text = widget.transaction.disclosure ?? '';
    
    // Set dropdown values
    selectedActivity = widget.transaction.typeOfActivity;
    selectedNoteTitle = widget.transaction.noteTitle;
    
    // Note: We'll handle the existing image URL separately since it's already uploaded
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
      
      // Ensure the current transaction's noteTitle is included if it exists
      if (selectedNoteTitle != null && selectedNoteTitle!.isNotEmpty) {
        uniqueNoteTitles.add(selectedNoteTitle!);
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
          // Ensure current noteTitle is available even if fetch fails
          noteTitleOptions = [];
          if (selectedNoteTitle != null && selectedNoteTitle!.isNotEmpty) {
            noteTitleOptions.add(selectedNoteTitle!);
          }
          noteTitleOptions.add('Add New...');
          isLoadingNoteTitles = false;
        });
      }
    }
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
  void dispose() {
    // Clean up controllers when the widget is disposed
    sellerNameController.dispose();
    receiptControlNumController.dispose();
    dateController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    disclosureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with back button and title
      appBar: AppBar(
        backgroundColor: widget.themeController.appColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.themeController.header2Color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF64B5F6)),
            SizedBox(width: 8),
            Text(
              "Update Transaction",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.themeController.header2Color
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
                child: Row(
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
                        color: themeController.header2Color,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Page description
            Text(
              "Update the details for this financial transaction.",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: widget.themeController.logtextColor,
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
                        "Updating transaction for: ${userProfile!.firstName ?? ''} ${userProfile!.lastName ?? 'Unknown User'} (${orgAbbreviation ?? 'No Org'})",
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
                    Text(
                      "Attached Document",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Clickable container for document upload
                    _selectedImage != null 
                    ? GestureDetector(
                        onTap: _handleImageTap,
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
                    : (widget.transaction.imageUrl != null && widget.transaction.imageUrl!.isNotEmpty)
                    ? GestureDetector(
                        onTap: _handleImageTap,
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
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  widget.transaction.imageUrl!, 
                                  width: double.infinity,
                                  fit: BoxFit.contain, // Show full image with proper aspect ratio
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Text('Failed to load image', 
                                          style: TextStyle(color: Colors.grey)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Tap to change',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Space Grotesk',
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

                    // === SELLER NAME SECTION ===
                    Text(
                      "Seller Name",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.themeController.boxColor,
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
                        controller: sellerNameController,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.normal,
                          color: widget.themeController.logtextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter seller/store name",
                          hintStyle: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: inputFontSize,
                            fontWeight: FontWeight.normal,
                            color: widget.themeController.hintColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // === RECEIPT CONTROL NUMBER SECTION ===
                    Text(
                      "Receipt Control Number",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.themeController.boxColor,
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
                        controller: receiptControlNumController,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.normal,
                          color: widget.themeController.logtextColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter receipt/transaction number",
                          hintStyle: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: inputFontSize,
                            fontWeight: FontWeight.normal,
                            color: widget.themeController.hintColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // === TYPE OF ACTIVITY SECTION ===
                    // Dropdown for selecting the type of financial activity
                    Text(
                      "Type of Activity",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Selected Activity
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double fieldWidth = constraints.maxWidth;

                        return Center(
                          child: Container(
                            width: fieldWidth,
                            decoration: BoxDecoration(
                              color: widget.themeController.boxColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: DropdownMenu<String>(
                              width: fieldWidth,
                              menuStyle: MenuStyle(
                                backgroundColor: MaterialStatePropertyAll(widget.themeController.boxColor),
                                elevation: const MaterialStatePropertyAll(4),
                                fixedSize: MaterialStatePropertyAll(
                                  Size(fieldWidth, double.infinity),
                                ),
                              ),
                              trailingIcon: Icon(
                                Icons.arrow_drop_down,
                                color: widget.themeController.logtextColor, 
                                size: 24,                    
                              ),
                              selectedTrailingIcon: Icon(
                                Icons.arrow_drop_up,
                                color: widget.themeController.logtextColor, 
                                size: 24,                    
                              ),
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: selectedActivity == null || selectedActivity == 'Select Activity'
                                    ? widget.themeController.hintColor
                                    : widget.themeController.logtextColor,
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: widget.themeController.boxColor,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              initialSelection: (["Receipt", "Disbursement"].contains(selectedActivity))
                                ? selectedActivity
                                : 'Select activity',
                              onSelected: (value) {
                                setState(() {
                                  selectedActivity = value;
                                });
                              },
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                  value: 'Select Activity', 
                                  label: 'Select Activity',
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(widget.themeController.hintColor), 
                                  ),
                                ),
                                DropdownMenuEntry(
                                  value: 'Receipt', 
                                  label: 'Receipt',
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(widget.themeController.hintColor), 
                                  ),
                                ),
                                DropdownMenuEntry(
                                  value: 'Disbursement', 
                                  label: 'Disbursement',
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(widget.themeController.hintColor), 
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // // Full-width dropdown
                    // Container(
                    //   width: double.infinity,
                    //   // Styled container for dropdown
                    //   decoration: BoxDecoration(
                    //     color: widget.themeController.boxColor,
                    //     borderRadius: BorderRadius.circular(8),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(0.1),
                    //         blurRadius: 4,
                    //         offset: const Offset(2, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   // Dropdown for activity selection
                    //   child: DropdownButtonFormField<String>(
                    //     value: (["Receipt", "Disbursement"].contains(selectedActivity)) ? selectedActivity : null,
                    //     isExpanded: true,
                    //     menuMaxHeight: 200,
                    //     decoration: const InputDecoration(
                    //       border: InputBorder.none,
                    //       contentPadding: EdgeInsets.symmetric(
                    //         horizontal: 12,
                    //         vertical: 14,
                    //       ),
                    //     ),
                    //     hint: const Text(
                    //       "Select activity",
                    //       style: TextStyle(
                    //         fontFamily: 'Space Grotesk',
                    //         fontSize: inputFontSize,
                    //         fontWeight: FontWeight.normal,
                    //         color: Color(0xFF757575),
                    //       ),
                    //     ),
                    //     items: ["Receipt", "Disbursement"]
                    //         .map(
                    //           (choice) => DropdownMenuItem<String>(
                    //             value: choice,
                    //             child: Text(
                    //               choice, // Removed .toUpperCase()
                    //               style: TextStyle(
                    //                 fontFamily: 'Space Grotesk',
                    //                 fontSize: inputFontSize,
                    //                 fontWeight: FontWeight.normal,
                    //                 color: widget.themeController.logtextColor,
                    //               ),
                    //             ),
                    //           ),
                    //         )
                    //         .toList(),
                    //     // Update selected activity when user makes a choice
                    //     onChanged: (value) {
                    //       setState(() {
                    //         selectedActivity = value;
                    //       });
                    //     },
                    //   ),
                    // ),

                    const SizedBox(height: 20),

                    // === DATE & AMOUNT SECTION ===
                    // Vertically stacked date and amount input fields
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DATE INPUT FIELD
                        Text(
                          "Date",
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.themeController.loginColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Date input container with date picker functionality
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: widget.themeController.boxColor,
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
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              hintText: "Select date",
                              hintStyle: TextStyle(
                                color: widget.themeController.hintColor,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: widget.themeController.logtextColor,
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
                        Text(
                          "Amount",
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.themeController.loginColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Amount input container with peso currency prefix
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: widget.themeController.boxColor,
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
                            decoration: InputDecoration(
                              prefixText: "₱ ", // Philippine peso currency symbol
                              prefixStyle: TextStyle(
                                color: widget.themeController.logtextColor,
                                fontWeight: FontWeight.normal,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              hintText: "Enter amount",
                              hintStyle: TextStyle(
                                color: widget.themeController.hintColor,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: widget.themeController.logtextColor,
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
                    Text(
                      "Description",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Description input container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.themeController.boxColor,
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
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          hintText: "e.g., Materials for booth design",
                          hintStyle: TextStyle(
                            color: widget.themeController.hintColor,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: widget.themeController.logtextColor,
                          fontWeight: FontWeight.normal,
                          fontSize: inputFontSize,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Note Title/Event Name
                    Text(
                      "Note Title/Event Name",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double fieldWidth = constraints.maxWidth;

                        return Center(
                          child: Container(
                            width: fieldWidth,
                            decoration: BoxDecoration(
                              color: widget.themeController.boxColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: DropdownMenu<String>(
                              width: fieldWidth,
                              menuStyle: MenuStyle(
                                backgroundColor: MaterialStatePropertyAll(widget.themeController.boxColor),
                                elevation: const MaterialStatePropertyAll(4),
                                fixedSize: MaterialStatePropertyAll(
                                  Size(fieldWidth, double.infinity),
                                ),
                              ),
                              trailingIcon: Icon(
                                Icons.arrow_drop_down,
                                color: widget.themeController.logtextColor, 
                                size: 24,                    
                              ),
                              selectedTrailingIcon: Icon(
                                Icons.arrow_drop_up,
                                color: widget.themeController.logtextColor, 
                                size: 24,                    
                              ),
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: selectedNoteTitle == null || selectedNoteTitle == 'Select Note Title'
                                    ? widget.themeController.hintColor
                                    : widget.themeController.logtextColor,
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: widget.themeController.boxColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              initialSelection: noteTitleOptions.contains(selectedNoteTitle)
                                ? selectedNoteTitle
                                : 'Select Note Title',
                              onSelected: (value) {
                                if (value == 'Add New...') {
                                  _showAddNoteTitleDialog();
                                } else {
                                  setState(() {
                                    selectedNoteTitle = value;
                                  });
                                }
                              },
                              dropdownMenuEntries: noteTitleOptions.map((title) {
                                return DropdownMenuEntry<String>(
                                  value: title,
                                  label: title,
                                  style: ButtonStyle(
                                    foregroundColor: MaterialStatePropertyAll(
                                      title == 'Select Note Title'
                                          ? widget.themeController.hintColor
                                          : widget.themeController.hintColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    // Container(
                    //   width: double.infinity,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFF2F3F5),
                    //     borderRadius: BorderRadius.circular(8),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(0.1),
                    //         blurRadius: 4,
                    //         offset: const Offset(2, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   child: DropdownButtonFormField<String>(
                    //     value: (noteTitleOptions.contains(selectedNoteTitle)) ? selectedNoteTitle : null,
                    //     isExpanded: true,
                    //     menuMaxHeight: 200,
                    //     decoration: const InputDecoration(
                    //       border: InputBorder.none,
                    //       contentPadding: EdgeInsets.symmetric(
                    //         horizontal: 12,
                    //         vertical: 14,
                    //       ),
                    //     ),
                    //     hint: Text(
                    //       isLoadingNoteTitles ? "Loading..." : "Select note title/event name",
                    //       style: const TextStyle(
                    //         fontFamily: 'Space Grotesk',
                    //         fontSize: inputFontSize,
                    //         fontWeight: FontWeight.normal,
                    //         color: Color(0xFF757575),
                    //       ),
                    //     ),
                    //     items: noteTitleOptions
                    //         .map(
                    //           (choice) => DropdownMenuItem<String>(
                    //             value: choice,
                    //             child: Text(
                    //               choice,
                    //               style: TextStyle(
                    //                 fontFamily: 'Space Grotesk',
                    //                 fontSize: inputFontSize,
                    //                 fontWeight: FontWeight.normal,
                    //                 color: choice == 'Add New...' ? const Color(0xFF64B5F6) : const Color(0xFF757575),
                    //               ),
                    //             ),
                    //           ),
                    //         )
                    //         .toList(),
                    //     onChanged: (value) {
                    //       if (value == 'Add New...') {
                    //         _showAddNoteTitleDialog();
                    //       } else {
                    //         setState(() {
                    //           selectedNoteTitle = value;
                    //         });
                    //       }
                    //     },
                    //   ),
                    // ),

                    // const SizedBox(height: 20),

                    // // Disclosure
                    // Text(
                    //   "Disclosure",
                    //   style: TextStyle(
                    //     fontFamily: 'Space Grotesk',
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //     color: widget.themeController.loginColor,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // Container(
                    //   width: double.infinity,
                    //   decoration: BoxDecoration(
                    //     color: widget.themeController.boxColor,
                    //     borderRadius: BorderRadius.circular(8),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(0.1),
                    //         blurRadius: 4,
                    //         offset: const Offset(2, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   child: TextField(
                    //     controller: disclosureController,
                    //     maxLines: 4,
                    //     decoration: InputDecoration(
                    //       contentPadding: EdgeInsets.symmetric(
                    //         horizontal: 12,
                    //         vertical: 14,
                    //       ),
                    //       hintText:
                    //           "Describe who benefited, the purpose, details of items, and how the transaction occurred.",
                    //       hintStyle: TextStyle(
                    //         color: widget.themeController.hintColor,
                    //         fontWeight: FontWeight.normal,
                    //       ),
                    //       border: InputBorder.none,
                    //     ),
                    //     style: TextStyle(
                    //       color: widget.themeController.logtextColor,
                    //       fontWeight: FontWeight.normal,
                    //       fontSize: inputFontSize,
                    //     ),
                    //   ),
                    // ),

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

                        // Validate required fields: all fields including receipt image must be filled
                        final missingFields = <String>[];
                        
                        // Check if image/receipt is attached (either new or existing)
                        bool hasImage = _selectedImage != null || 
                                       (widget.transaction.imageUrl != null && widget.transaction.imageUrl!.isNotEmpty);
                        if (!hasImage) missingFields.add('Attached Document/Receipt');
                        
                        if (sellerNameController.text.trim().isEmpty) missingFields.add('Seller Name');
                        if (receiptControlNumController.text.trim().isEmpty) missingFields.add('Receipt Control Number');
                        if ((selectedActivity ?? '').trim().isEmpty) missingFields.add('Type of Activity');
                        if (dateController.text.trim().isEmpty) missingFields.add('Date');
                        if (amountController.text.trim().isEmpty) missingFields.add('Amount');
                        if (descriptionController.text.trim().isEmpty) missingFields.add('Description');
                        if ((selectedNoteTitle ?? '').trim().isEmpty) missingFields.add('Note Title/Event Name');
                        if (disclosureController.text.trim().isEmpty) missingFields.add('Disclosure');

                        if (missingFields.isNotEmpty) {
                          // Show improved alert dialog listing missing fields (matching add_transaction style)
                          await showDialog<void>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
                                contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFF64B5F6),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Missing required fields',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                content: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Please fill out the following before saving:',
                                          style: TextStyle(
                                            fontFamily: 'Space Grotesk',
                                            color: Color(0xFF4F4F4F),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: missingFields.map((f) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.circle, size: 8, color: Color(0xFF64B5F6)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      f,
                                                      style: const TextStyle(
                                                        fontFamily: 'Space Grotesk',
                                                        color: Color(0xFF4F4F4F),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF64B5F6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text(
                                        'OK',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
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

                        // Compute full name for updatedBy
                        final fullName = ((userProfile?.firstName ?? '') + ' ' + (userProfile?.lastName ?? '')).trim();
                        final updatedByValue = fullName.isNotEmpty ? fullName : (userProfile?.username ?? currentUserID);

                        Transaction updatedTransaction = Transaction(
                          transactionID: widget.transaction.transactionID, // Preserve original ID
                          userID: widget.transaction.userID, // Preserve original user ID
                          sellerName: sellerNameController.text,
                          receiptControlNum: receiptControlNumController.text,
                          typeOfActivity: selectedActivity ?? '',
                          date: transactionDate,
                          amount: double.tryParse(amountController.text) ?? 0.0,
                          description: descriptionController.text,
                          noteTitle: selectedNoteTitle ?? '',
                          disclosure: disclosureController.text,
                          createdBy: widget.transaction.createdBy, // Preserve original creator
                          updatedBy: updatedByValue,
                          createdAt: widget.transaction.createdAt, // Preserve original creation date
                          updatedAt: now, // Update the modification date
                          imageUrl: uploadedImageUrl ?? widget.transaction.imageUrl ?? '', // Use new image or keep existing
                          isUpdated: true, // Mark as updated
                          orgID: widget.transaction.orgID, // Preserve original org ID
                        );

                        // Update transaction in database
                        await db.updateTransaction(widget.transaction, updatedTransaction);
                        
                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Pop with the updated transaction data to refresh the parent widget
                          Navigator.of(context).pop(updatedTransaction);
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
                              : "Update Transaction",
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
