import 'package:flutter/material.dart';
import 'widgets/transaction_box.dart';
import 'package:fund_buddy/supabase_config.dart';
import 'package:fund_buddy/entity/user_profile.dart';
import 'package:fund_buddy/entity/transaction.dart';
import 'widgets/theme_toggle.dart';

/// TransactionsPage - Main page for displaying and managing financial transactions
/// Features:
/// - Search functionality for filtering transactions
/// - Sort dropdown with multiple sorting options
/// - Header with page title and description
class TransactionsPage extends StatefulWidget {
  final ThemeController themeController;
  
  const TransactionsPage({super.key, required this.themeController});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // State variables for user data
  UserProfile? userProfile;
  bool isLoadingUser = true;
  
  // State variables for transactions
  List<Transaction> transactions = [];
  List<Transaction> filteredTransactions = [];
  bool isLoadingTransactions = false;
  
  // State variables for search and filtering
  final TextEditingController _searchController = TextEditingController();

  // State variables for dropdown functionality
  String? selected; // Currently selected sort option (null means no selection)
  bool sortAscending = true; // Controls sort direction (true = ascending, false = descending)
  bool isDropdownVisible = false; // Controls visibility of dropdown options
  final LayerLink _layerLink = LayerLink(); // Link for overlay positioning
  OverlayEntry? _overlayEntry; // Reference to active overlay dropdown
  
  // Available sorting options for transactions
  List<String> sortOptions = [
    'Note Title', 
    'Amount', 
    'Date', 
    'Description', 
    'Type of Activity', 
    'Seller Name'
  ];

  //Dark Mode 
  ThemeController get themeController => widget.themeController;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterTransactions);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Initialize user data and transactions
  Future<void> _initializeData() async {
    await _fetchUserProfile();
    if (userProfile != null) {
      await _fetchTransactions();
    }
  }

  // Method to fetch user profile data
  Future<void> _fetchUserProfile() async {
    try {
      final authUser = SupabaseConfig.client.auth.currentUser;
      if (authUser != null) {
        final userData = await SupabaseConfig.client
            .from('user') // Fixed: using correct table name from schema
            .select('*')
            .eq('id', authUser.id)
            .single();
        
        print('DEBUG: Raw user data: $userData');
        
        if (mounted) {
          setState(() {
            userProfile = UserProfile(id: userData['id'])
              ..username = userData['username']
              ..email = userData['email']
              ..orgID = userData['orgID']
              ..firstName = userData['firstName']
              ..lastName = userData['lastName']
              ..profileImageUrl = userData['profileImageUrl'];
            isLoadingUser = false;
          });
          
          print('DEBUG: UserProfile created with orgID: ${userProfile?.orgID}');
          print('DEBUG: UserProfile username: ${userProfile?.username}');
        }
      }
    } catch (e) {
      print('Error fetching user: $e');
      if (mounted) {
        setState(() {
          isLoadingUser = false;
        });
      }
    }
  }

  // Fetch transactions from supabase based on the current user's organization
  Future<void> _fetchTransactions() async {
    print('DEBUG: Starting to fetch transactions');
    print('DEBUG: User profile orgID: ${userProfile?.orgID}');
    
    if (userProfile?.orgID == null) {
      print('DEBUG: No orgID found, cannot fetch transactions');
      return;
    }
    
    setState(() {
      isLoadingTransactions = true;
    });
    
    try {
      print('DEBUG: Querying transactions for orgID: ${userProfile!.orgID}');
      print('DEBUG: orgID type: ${userProfile!.orgID.runtimeType}');
      
      // First, let's see all transactions in the database
      final allTransactions = await SupabaseConfig.client
          .from('transactions')
          .select('orgID, userID, description')
          .limit(10);
      print('DEBUG: All transactions sample: $allTransactions');
      
      final response = await SupabaseConfig.client
          .from('transactions')
          .select('*') // Select all fields explicitly
          .eq('orgID', userProfile!.orgID!);
      
      print('DEBUG: Raw response: $response');
      print('DEBUG: Response length: ${response.length}');
      
      if (mounted) {
        setState(() {
          transactions = response.map<Transaction>((json) {
            print('DEBUG: Processing transaction: $json');
            return Transaction.fromMap(json);
          }).toList();
          filteredTransactions = List.from(transactions);
          isLoadingTransactions = false;
        });
        
        // Apply sorting if a sort option is already selected
        if (selected != null) {
          _sortTransactions();
        }
        
        print('DEBUG: Final transactions count: ${transactions.length}');
      }
    } catch (e) {
      print('ERROR: Failed to fetch transactions: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          isLoadingTransactions = false;
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Filter transactions based on search query
  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTransactions = List.from(transactions);
      } else {
        filteredTransactions = transactions.where((transaction) {
          return transaction.description?.toLowerCase().contains(query) == true ||
                 transaction.sellerName?.toLowerCase().contains(query) == true ||
                 transaction.noteTitle?.toLowerCase().contains(query) == true ||
                 transaction.createdBy?.toLowerCase().contains(query) == true ||
                 transaction.updatedBy?.toLowerCase().contains(query) == true;
        }).toList();
      }
      // Apply sorting after filtering
      _sortTransactions();
    });
  }

  // Sort transactions based on selected sort option and sort direction
  void _sortTransactions() {
    if (selected == null) return;
    
    setState(() {
      switch (selected) {
        case 'Note Title':
          filteredTransactions.sort((a, b) {
            final aTitle = a.noteTitle?.toLowerCase() ?? '';
            final bTitle = b.noteTitle?.toLowerCase() ?? '';
            return sortAscending ? aTitle.compareTo(bTitle) : bTitle.compareTo(aTitle);
          });
          break;
        case 'Amount':
          filteredTransactions.sort((a, b) {
            final aAmount = a.amount ?? 0.0;
            final bAmount = b.amount ?? 0.0;
            return sortAscending ? aAmount.compareTo(bAmount) : bAmount.compareTo(aAmount);
          });
          break;
        case 'Date':
          filteredTransactions.sort((a, b) {
            final aDate = a.date ?? DateTime(1900);
            final bDate = b.date ?? DateTime(1900);
            return sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          });
          break;
        case 'Description':
          filteredTransactions.sort((a, b) {
            final aDesc = a.description?.toLowerCase() ?? '';
            final bDesc = b.description?.toLowerCase() ?? '';
            return sortAscending ? aDesc.compareTo(bDesc) : bDesc.compareTo(aDesc);
          });
          break;
        case 'Type of Activity':
          filteredTransactions.sort((a, b) {
            final aType = a.typeOfActivity?.toLowerCase() ?? '';
            final bType = b.typeOfActivity?.toLowerCase() ?? '';
            return sortAscending ? aType.compareTo(bType) : bType.compareTo(aType);
          });
          break;
        case 'Seller Name':
          filteredTransactions.sort((a, b) {
            final aSeller = a.sellerName?.toLowerCase() ?? '';
            final bSeller = b.sellerName?.toLowerCase() ?? '';
            return sortAscending ? aSeller.compareTo(bSeller) : bSeller.compareTo(aSeller);
          });
          break;
        default:
          break;
      }
    });
  }

  // Refresh transactions after update or delete
  Future<void> _refreshTransactions() async {
    if (userProfile != null) {
      await _fetchTransactions();
    }
  }

  void _toggleDropdown() {
    if (isDropdownVisible) {
      _removeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
  final overlay = Overlay.of(context);
  _overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _removeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          width: MediaQuery.of(context).size.width * 0.35,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 55),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: themeController.boxColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: sortOptions.map((String option) {
                  bool isSelected = selected == option;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        // If same option is selected, toggle sort direction
                        if (selected == option) {
                          sortAscending = !sortAscending;
                        } else {
                          // If different option, set it and reset to ascending
                          selected = option;
                          sortAscending = true;
                        }
                      });
                      _sortTransactions(); // Apply sorting immediately
                      _removeDropdown();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF64B5F6).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? const Color(0xFF64B5F6) : themeController.textColor,
                          fontFamily: 'Space Grotesk',
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  overlay.insert(_overlayEntry!);
  setState(() => isDropdownVisible = true);
}

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => isDropdownVisible = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(25), // Consistent padding around the entire page
        children: [
          // Page header section with title and description
          _buildTransactionsHeader(context),

          // Search bar and sort dropdown section
          _buildSearchAndSortBar(context),
          
          // Transactions list section
          _buildTransactionsList(),
        ],
      ),
    );
  }

  /// Builds the search and sort bar section
  /// Contains:
  /// - Search field (3/5 of width) for filtering transactions by description
  /// - Sort dropdown (2/5 of width) with toggle visibility and selection options
  Widget _buildSearchAndSortBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to top when dropdown expands
      children: [
        // Search Field Section (takes 60% of available width)
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 50, // Fixed height to match sort button
            child: Container(
              decoration: BoxDecoration(
                color: themeController.boxColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                    blurRadius: 4,
                    offset: Offset(2, 2), // Shadow positioned below
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: themeController.header2Color,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search description',
                  suffixIcon: Icon(Icons.search, color: themeController.header2Color), // Search icon for UX clarity
                  border: InputBorder.none, // Remove default border
                  contentPadding: EdgeInsets.all(12), // Internal spacing
                  hintStyle: TextStyle(
                    color: themeController.hintColor, // Gray color for hint text
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10), // Spacing between search and sort sections

        // Sort Dropdown Section (takes 40% of available width)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Main sort button - shows selected value and toggles dropdown
              CompositedTransformTarget(
                link: _layerLink,
                child: GestureDetector(
                  onTap: _toggleDropdown,
                  child: Container(
                    height: 50, // Match search field height
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: themeController.boxColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                          blurRadius: 4,
                          offset: Offset(2, 2), // Shadow positioned below
                        ),
                      ],
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display selected sort option or default text
                          Expanded(
                            child: Text(
                              selected ?? 'Sort By', // Show selection or placeholder
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // Truncate with ...
                              style: TextStyle(
                                fontSize: 14, 
                                // Dynamic color based on selection state
                                color: selected != null ? themeController.header2Color : themeController.hintColor, 
                                fontFamily: 'Space Grotesk',
                                // Bold text when item is selected
                                fontWeight: selected != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Dropdown arrow - stays aligned to the right
                          Icon(
                            isDropdownVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: themeController.header2Color,
                          ),
                        ],
                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the header section of the transactions page
  /// Contains:
  /// - Page title with receipt icon
  /// - Descriptive subtitle explaining the page functionality
  Widget _buildTransactionsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25), // Space between header and content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left-align all text
        children: [
          // Page title with icon
          Row(
            mainAxisSize: MainAxisSize.min, // Don't take full width
            children: [
              // Receipt icon with blue color matching app theme
              const Icon(Icons.receipt_rounded, color: Color(0xFF64B5F6)),
              const SizedBox(width: 8), // Small gap between icon and text
              // Main page title
              Text(
                'Transactions',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 28, // Large font for emphasis
                  color: themeController.headerColor, // dynamic color
                ),
              ),
            ],
          ),
          
          // Descriptive subtitle explaining page purpose
         Text(
          "Record, view, and manage all your financial transactions.",
          textAlign: TextAlign.left,
          style: TextStyle(
            color: themeController.textColor, // dynamic color
            fontSize: 14, // optional, for consistency
          ),
        ),
        ],
      ),
    );
  }

  /// Builds the transactions list section
  /// Shows loading indicator, empty state, or list of transactions
  Widget _buildTransactionsList() {
    // Show loading indicator while fetching user data
    if (isLoadingUser) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(
            color: Color(0xFF64B5F6),
          ),
        ),
      );
    }
    
    // Show loading indicator while fetching transactions
    if (isLoadingTransactions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF64B5F6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading transactions...',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                  color: themeController.headerColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show empty state if no transactions
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                transactions.isEmpty ? 'No transactions found' : 'No transactions match your search',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Space Grotesk',
                ),
              )
            ],
          ),
        ),
      );
    }
    
    // Build the list of transactions
    return Column(
      children: [
        const SizedBox(height: 16),
        // Transaction count info
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '${filteredTransactions.length} transaction${filteredTransactions.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: themeController.headerColor,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (filteredTransactions.length != transactions.length) ...[
                Text(
                  ' of ${transactions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontFamily: 'Space Grotesk',
                  ),
                ),
              ],
            ],
          ),
        ),
        // Transactions list
        ...filteredTransactions.map((transaction) => TransactionBox(
          text: transaction.description ?? 'No description',
          transaction: transaction,
          themeController: themeController,
          onTransactionChanged: _refreshTransactions, // Add callback to refresh data
        )).toList(),
      ],
    );
  }
}
