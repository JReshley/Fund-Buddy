import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fund_buddy/entity/transaction.dart';

class TransactionDatabase {
  // Database to transactions
  final database = Supabase.instance.client.from('transactions');

  // Create
  Future createTransaction(Transaction newTransaction) async {
  final response = await database
      .insert(newTransaction.toMap(includeId: false)) // no transactionID here
      .select()
      .single();

  return Transaction.fromMap(response); // you get the auto-generated ID back
  }

  // Read
  final stream = Supabase.instance.client
      .from('transactions')
      .stream(primaryKey: ['transactionID']).map((data) => data.map((transactionMap) => Transaction.fromMap(transactionMap)).toList());

  // Update
  Future updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    await database
        .update(newTransaction.toMap())
        .eq('transactionID', oldTransaction.transactionID!);
  }

  // Delete
  Future deleteTransaction(Transaction trans) async {
    if (trans.transactionID == null) {
      throw Exception('Cannot delete transaction: transactionID is null');
    }
    
    final response = await database
        .delete()
        .eq('transactionID', trans.transactionID!)
        .select();
    
    // Check if any rows were deleted
    if (response.isEmpty) {
      throw Exception('Transaction not found or already deleted');
    }
    
    print('Successfully deleted transaction with ID: ${trans.transactionID}');
  }

}