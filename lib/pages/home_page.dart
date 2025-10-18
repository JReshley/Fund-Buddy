import 'package:flutter/material.dart';
import 'package:fund_buddy/supabase_config.dart';
import 'package:fund_buddy/entity/user_profile.dart';
import 'widgets/add_transaction.dart';
import 'widgets/theme_toggle.dart';

class HomePage extends StatefulWidget {
  final ThemeController themeController;

  const HomePage({super.key, required this.themeController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dynamic data
  String userName = 'Loading...';
  String orgName = 'Loading...';
  int noOfReceipts = 0;
  int noOfDisbursements = 0;
  double totalReceipts = 0.0;
  double totalDisbursements = 0.0;
  bool isLoading = true;
  bool hasOrganization = false;

  // Computed properties
  int get totalTrans => noOfDisbursements + noOfReceipts;
  double get netBalance => totalReceipts - totalDisbursements;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get current user ID
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        setState(() => isLoading = false); // stop loading
        return;
      }

      // Fetch user profile
      final userProfile = await UserProfile.getCurrentUser(currentUser.id);
      if (userProfile == null) {
        print('User profile not found');
        setState(() => isLoading = false); // stop loading
        return;
      }

      // Set user name (Full Name)
      final fullName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

      // Check if user has an organization
      if (userProfile.orgID == null) {
        setState(() {
          userName = fullName.isNotEmpty ? fullName : 'User';
          hasOrganization = false;
          isLoading = false;
        });
        return;
      }

      // Fetch organization abbreviation
      String orgAbbreviation = 'Unknown';
      final orgData = await SupabaseConfig.client
          .from('organization')
          .select('abbreviation')
          .eq('orgID', userProfile.orgID!)
          .single();

      orgAbbreviation = orgData['abbreviation'] ?? 'Unknown';

      // Fetch transactions for the user's organization
      final transactions = await SupabaseConfig.client
          .from('transactions')
          .select('typeOfActivity, amount')
          .eq('orgID', userProfile.orgID!);

      // Calculate receipts
      int receiptsCount = 0;
      double receiptsSum = 0.0;

      // Calculate disbursements
      int disbursementsCount = 0;
      double disbursementsSum = 0.0;

      for (var transaction in transactions) {
        final type = transaction['typeOfActivity'] as String?;
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'Receipt') {
          receiptsCount++;
          receiptsSum += amount;
        } else if (type == 'Disbursement') {
          disbursementsCount++;
          disbursementsSum += amount;
        }
      }

      setState(() {
        userName = fullName.isNotEmpty ? fullName : 'User';
        orgName = orgAbbreviation;
        noOfReceipts = receiptsCount;
        noOfDisbursements = disbursementsCount;
        totalReceipts = receiptsSum;
        totalDisbursements = disbursementsSum;
        hasOrganization = true;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
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
                    'Loading dashboard...',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      color: widget.themeController.headerColor,
                    ),
                  ),
                ],
              ),
            )
          : !hasOrganization
              ? _buildNoOrganizationUI(context)
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: ListView(
                    padding: const EdgeInsets.all(25),
                    children: [
                      _buildDashboardHeader(context),
                      _buildFinancialCard(
                        context,
                        title: 'Total Receipts',
                        amount: totalReceipts,
                        transactionCount: noOfReceipts,
                        icon: Icons.price_check_outlined,
                        iconColor: const Color(0xFF2E7D32),
                        headerColor: widget.themeController.header2Color,
                        textColor: widget.themeController.textColor,
                      ),
                      _buildFinancialCard(
                        context,
                        title: 'Total Disbursements',
                        amount: totalDisbursements,
                        transactionCount: noOfDisbursements,
                        icon: Icons.low_priority_rounded,
                        iconColor: const Color(0xFFD32F2F),
                        headerColor: widget.themeController.header2Color,
                        textColor: widget.themeController.textColor,
                      ),
                      _buildFinancialCard(
                        context,
                        title: 'Net Balance',
                        amount: netBalance,
                        transactionCount: totalTrans,
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFF64B5F6),
                        headerColor: widget.themeController.header2Color,
                        textColor: widget.themeController.textColor,
                      ),
                      const SizedBox(height: 20),
                      _buildAddTransactionButton(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoOrganizationUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Building icon
            Icon(
              Icons.business_outlined,
              size: 100,
              color: widget.themeController.textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 30),
            
            // Main heading
            Text(
              'No Organization Assigned',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.themeController.headerColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            
            // Description text
            Text(
              'You are not currently assigned to any organization.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                color: widget.themeController.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            
            Text(
              'Please contact your organization administrator to be added to an organization.',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 13,
                color: widget.themeController.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
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
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF64B5F6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Once added, you will be able to view and manage your organization\'s transactions.',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        color: widget.themeController.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dashboard_rounded, color: Color(0xFF64B5F6)),
              const SizedBox(width: 8),
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 28,
                  color: widget.themeController.headerColor,
                ),
              ),
            ],
          ),
          Text(
            "Hey $userName! Here's a quick overview of $orgName's finances.",
            textAlign: TextAlign.left,
            style: TextStyle(color: widget.themeController.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
    BuildContext context, {
    required String title,
    required double amount,
    required int transactionCount,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Color headerColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Container(
        width: 355,
        padding: const EdgeInsets.all(20),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: headerColor, // now dynamic
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₱ ${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 24,
                    color: textColor,
                  ),
                ),
                Text(
                  'Based on $transactionCount recorded transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            Icon(icon, color: iconColor, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTransactionButton(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionPage(themeController: widget.themeController),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64B5F6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Add Transaction',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
