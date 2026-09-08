import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/wallet.dart';
import '../models/wallet_summary.dart';
import '../models/wallet_transaction.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    return token;
  }

  Future<Wallet> getWallet(String tripId) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/wallet',
      token: token,
    );

    return Wallet.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<WalletSummary> getWalletSummary(
    String tripId,
  ) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/wallet/summary',
      token: token,
    );

    return WalletSummary.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<List<WalletTransaction>> getTransactions(
    String tripId, {
    String? transactionType,
    String? sort,
    String? startDate,
    String? endDate,
  }) async {
    final token = await _getToken();

    final queryParams = <String, String>{};
    if (transactionType != null && transactionType.isNotEmpty) {
      queryParams['transaction_type'] = transactionType;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final uri = Uri.parse('${ApiConstants.trips}/$tripId/wallet/transactions').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    final transactions = response as List;

    return transactions
        .map(
          (transaction) => WalletTransaction.fromJson(
            Map<String, dynamic>.from(transaction),
          ),
        )
        .toList();
  }
}