import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylonow_vendor/core/config/supabase_config.dart';
import 'package:sylonow_vendor/features/wallet/models/wallet.dart';
import 'package:sylonow_vendor/features/wallet/models/wallet_transaction.dart';

final walletServiceProvider = Provider((ref) => WalletService());

class WalletService {
  Future<Wallet> getWalletDetails() async {
    try {
// TODO: Replace with proper logging - print('🔵 WalletService: Fetching wallet details');
      
      final response = await SupabaseConfig.client.rpc('get_vendor_wallet');
      
// TODO: Replace with proper logging - print('🟢 WalletService: Wallet data received: $response');
      
      if (response == null) {
        throw Exception('No wallet data found');
      }
      
      return Wallet.fromJson(response as Map<String, dynamic>);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 WalletService: Error fetching wallet: $e');
// TODO: Replace with proper logging - print('🔴 WalletService: Stack trace: $stackTrace');
      throw Exception('Failed to fetch wallet details: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getBankDetails() async {
    try {
// TODO: Replace with proper logging - print('🔵 WalletService: Fetching bank details');
      
      final response = await SupabaseConfig.client.rpc('get_vendor_bank_details');
      
// TODO: Replace with proper logging - print('🟢 WalletService: Bank details received: $response');
      
      return response as Map<String, dynamic>?;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 WalletService: Error fetching bank details: $e');
// TODO: Replace with proper logging - print('🔴 WalletService: Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<WalletTransaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
// TODO: Replace with proper logging - print('🔵 WalletService: Fetching transactions (limit: $limit, offset: $offset)');
      
      // Use direct table query with RLS - the policy will automatically filter by vendor
      final response = await SupabaseConfig.client
          .from('wallet_transactions')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
// TODO: Replace with proper logging - print('🟢 WalletService: Transactions received: ${response.length} items');
      
      return response
          .map((data) => WalletTransaction.fromJson(data))
          .toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 WalletService: Error fetching transactions: $e');
// TODO: Replace with proper logging - print('🔴 WalletService: Stack trace: $stackTrace');
      throw Exception('Failed to fetch transactions: ${e.toString()}');
    }
  }

  Future<String> createWithdrawalRequest({
    required double amount,
    required String bankAccountNumber,
    required String bankIfscCode,
    required String bankAccountHolderName,
  }) async {
    try {
// TODO: Replace with proper logging - print('🔵 WalletService: Creating withdrawal request for ₹$amount');
      
      final response = await SupabaseConfig.client.rpc(
        'create_withdrawal_request',
        params: {
          'p_amount': amount,
          'p_bank_account_number': bankAccountNumber,
          'p_bank_ifsc_code': bankIfscCode,
          'p_bank_account_holder_name': bankAccountHolderName,
        },
      );
      
// TODO: Replace with proper logging - print('🟢 WalletService: Withdrawal request created: $response');
      
      if (response == null) {
        throw Exception('No response from withdrawal request');
      }
      
      return response.toString();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 WalletService: Error creating withdrawal request: $e');
// TODO: Replace with proper logging - print('🔴 WalletService: Stack trace: $stackTrace');
      
      // Provide user-friendly error messages
      if (e.toString().contains('Insufficient available balance')) {
        throw Exception('Insufficient funds. Please check your available balance.');
      } else if (e.toString().contains('Wallet not found')) {
        throw Exception('Wallet not initialized. Please contact support.');
      }
      
      throw Exception('Failed to create withdrawal request: ${e.toString()}');
    }
  }
} 