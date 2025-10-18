import 'package:flutter/material.dart';
import 'package:fund_buddy/entity/transaction_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_toggle.dart';
import 'update_transaction.dart';


/// A custom widget that displays transaction information in an expandable card format
/// Shows transaction details with expand/collapse functionality and action buttons
class TransactionBox extends StatefulWidget {
  // The main transaction title/description text
  final String text;
  // The transaction object containing all transaction data
  final dynamic transaction; // You can replace 'dynamic' with your Transaction class type
  final ThemeController themeController;
  // Callback function to refresh parent widget when transaction is updated or deleted
  final VoidCallback? onTransactionChanged;

  const TransactionBox({
    Key? key, 
    required this.text, 
    required this.transaction, 
    required this.themeController,
    this.onTransactionChanged,
  }) : super(key: key);
  

  @override
  State<TransactionBox> createState() => _TransactionBoxState();
}

class _TransactionBoxState extends State<TransactionBox> {
  // Controls whether the detailed transaction information is expanded or collapsed
  bool _isExpanded = false;
  
  // Database instance for transaction operations
  final TransactionDatabase _transactionDb = TransactionDatabase();

  // Variables for transaction
  String? typeOfActivity; // Determine if receipt or disbursement
  int? amount;
  String? date;
  String? description; // e.g. Materials, stickers, food, etc.
  String? noteTitle; // e.g. Freshmen Orientation and Student Activity Festival, Merch, Team Building, etc.
  String? disclosure; // Detailed explanation or notes about the transaction
  String? createdBy; // User who created the transaction
  String? updatedBy; // User who last updated the transaction
  String? createdAt; // Date of creation
  String? updatedAt; // Date of last update
  bool? isUpdated; // Whether the transaction has been updated since creation
  String? documentType; // e.g. Service Invoice, Official Receipt, etc.
  String? imageUrl; // URL to the attached document (if any)

  //Dark Mode 
  ThemeController get themeController => widget.themeController;

  @override
  Widget build(BuildContext context) {
    // helper to extract filename from a URL and truncate long names
    String _filenameFromUrl(String? url, {int maxLength = 30}) {
      if (url == null || url.isEmpty) return 'No file';
      try {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        String name = segments.isNotEmpty ? segments.last : url;

        // If name is short enough, return as-is
        if (name.length <= maxLength) return name;

        // Preserve file extension when possible
        final lastDot = name.lastIndexOf('.');
        if (lastDot > 0 && lastDot < name.length - 1) {
          final ext = name.substring(lastDot); // includes dot
          final baseMax = maxLength - ext.length - 3; // reserve for '...'
          if (baseMax > 0) {
            final base = name.substring(0, baseMax);
            return '$base...$ext';
          }
        }

        // Fallback: simple truncate with ellipsis
        return '${name.substring(0, maxLength - 3)}...';
      } catch (_) {
        // If parsing fails, truncate the raw URL
        if (url.length <= maxLength) return url;
        return '${url.substring(0, maxLength - 3)}...';
      }
    }

    // helper to open url
    Future<void> _openUrl(String? url) async {
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No file URL available'),
        ));
        return;
      }
      final uri = Uri.parse(url);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open URL'),
          ));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error opening URL: $e'),
        ));
      }
    }
    // Consistent text style for section headings in the expanded view
    TextStyle headingStyle = TextStyle(
      fontSize: 12,
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      color: themeController.header2Color,
    );

    // Main transaction card container with styling and shadow
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.boxColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
            blurRadius: 4,
            offset: Offset(2, 2), // Shadow positioned below
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Main transaction information (title, description, amount, date)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Transaction title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description 
                    Text(
                      widget.transaction?.description ?? 'No description',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w700,
                        color: themeController.header2Color,
                      ),
                    ),
                    // Note title or event name
                    Text(
                      widget.transaction?.noteTitle ?? 'No title',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w400,
                        color: themeController.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Transaction amount and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Transaction amount with currency symbol
                    Text(
                      "₱ ${widget.transaction?.amount ?? '0.00'}",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w700,
                        color: (widget.transaction?.typeOfActivity == 'Receipt') ? const Color(0xFF2E7D32) : const Color(0xD3D32F2F),
                      ),
                    ),
                    // Transaction date
                    Text(
                      widget.transaction?.formattedDate ?? 'No date',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w400,
                        color: themeController.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Expandable section: Shows detailed transaction information when expanded
          if (_isExpanded) ...[
            Divider(color: themeController.navColor),
            const SizedBox(height: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attached Document: ",
                  style: headingStyle
                ),
                // Document preview container with download functionality
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    width: double.infinity,
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: themeController.transactionBox,
                      border: Border.all(
                        color: themeController.logtextColor, 
                        width: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: File icon and filename
                        Row(
                          children: [
                            // Document file icon
                            Icon(
                              Icons.file_copy,  
                              color: themeController.textColor,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            // Document filename (show filename extracted from URL)
                            Text(
                              _filenameFromUrl(widget.transaction?.imageUrl),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'SpaceGrotesk',
                                fontWeight: FontWeight.w400,
                                color: themeController.textColor,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                        // Right side: Download button (open URL)
                        GestureDetector(
                          onTap: () => _openUrl(widget.transaction?.imageUrl),
                          child: Icon(
                            Icons.download,
                            color: themeController.textColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Seller Name section (if available)
                if (widget.transaction?.sellerName != null && widget.transaction?.sellerName != '')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seller Name:",
                        style: headingStyle
                      ),
                      SizedBox(height: 5),
                      Text(
                        widget.transaction?.sellerName ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w400,
                          color: themeController.textColor,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                // Receipt Control Number section (if available)
                if (widget.transaction?.receiptControlNum != null && widget.transaction?.receiptControlNum != '')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Receipt Control Number:",
                        style: headingStyle
                      ),
                      SizedBox(height: 5),
                      Text(
                        widget.transaction?.receiptControlNum ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w400,
                          color: themeController.textColor,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                // Disclosure/additional information section
                Text(
                  "Disclosure:",
                  style: headingStyle
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  width: double.infinity,
                  padding: const EdgeInsets.all(8), 
                  decoration: BoxDecoration(
                    color: themeController.transactionBox, // background
                    border: Border.all(
                      color: themeController.logtextColor, 
                      width: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  // Detailed disclosure/explanation text
                  child: Text(
                    widget.transaction?.disclosure ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w400,
                      color: themeController.textColor,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.fade,
                  ),
                ),
                // Last updated information section
                  Text(
                    (widget.transaction?.isUpdated == true) ? "Last updated by:" : "Created by:",
                    style: headingStyle
                  ),
                  SizedBox(height: 5),
                  // User information and last update date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: User who last updated the transaction
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (widget.transaction?.isUpdated == true)
                                  ? (widget.transaction?.updatedBy ?? '')
                                  : (widget.transaction?.createdBy ?? ''),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'SpaceGrotesk', 
                                fontWeight: FontWeight.w400,
                                color: themeController.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Right side: Last update date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (widget.transaction?.isUpdated == true)
                                ? (widget.transaction?.formattedUpdatedAt ?? '')
                                : (widget.transaction?.formattedCreatedAt ?? ''),
                            style: TextStyle(
                              fontSize: 12, 
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.w400,
                              color: themeController.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Footer row: Expand/collapse toggle and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Expand/collapse toggle button
              GestureDetector(
                onTap: () {
                  // Toggle the expanded state to show/hide detailed information
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? 'Less info...' : 'More info...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64B5F6),
                  ),
                ),
              ),
              // Right side: Action buttons (Edit and Delete)
              Row(
                children: [
                  // Edit button
                  Container(
                    width: MediaQuery.of(context).size.width * 0.23,
                    height: 30,
                    decoration: BoxDecoration(
                     boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                          blurRadius: 4,
                          offset: Offset(2, 2), // Shadow positioned below
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F3F5),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        // Navigate to update transaction page and wait for result
                        final updatedTransaction = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UpdateTransactionPage(
                              transaction: widget.transaction,
                              themeController: widget.themeController,
                              onThemeChanged: () {
                                        setState(() {});
                                      },
                            ),
                          ),
                        );
                        
                        // If transaction was updated, notify parent to refresh
                        if (updatedTransaction != null && mounted) {
                          widget.onTransactionChanged?.call();
                        }
                      },
                      child: Text(
                        "Edit",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4F4F4F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete button
                  Container(
                    width: MediaQuery.of(context).size.width * 0.23,
                    height: 30,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                          blurRadius: 4,
                          offset: Offset(2, 2), // Shadow positioned below
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD32F2F),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () {
                        _showDeleteConfirmation();
                      },
                      child: Text(
                        "Delete",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeController.boxColor,
          title: Text(
            'Delete Transaction',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              color: themeController.header2Color
            ),
          ),
          content: Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: themeController.logtextColor
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: themeController.logtextColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _deleteTransaction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to delete the transaction
  Future<void> _deleteTransaction() async {
    try {
      // Check if transaction has an ID
      if (widget.transaction?.transactionID == null) {
        throw Exception('Transaction ID is null');
      }
      
      // Delete the transaction from the database
      await _transactionDb.deleteTransaction(widget.transaction);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Transaction deleted successfully',
              style: TextStyle(fontFamily: 'SpaceGrotesk'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent to refresh the transaction list
        widget.onTransactionChanged?.call();
      }
    } catch (e) {
      // Show error message with more details
      print('Delete transaction error: $e'); // For debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting transaction: $e',
              style: const TextStyle(fontFamily: 'SpaceGrotesk'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Show error longer
          ),
        );
      }
    }
  }
}
