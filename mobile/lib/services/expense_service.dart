import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/expense.dart';

class ExpenseService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    return token;
  }

  Future<Expense> addExpense({
    required String tripId,
    required int amountPaise,
    required String category,
    String? description,
    required List<String> memberIds,
    String splitMode = 'EQUAL',
    List<Map<String, dynamic>>? splits,
  }) async {
    final token = await _getToken();

    final idempotencyKey = '${DateTime.now().microsecondsSinceEpoch}-expense';

    final payload = <String, dynamic>{
      'amount_paise': amountPaise,
      'category': category,
      'description': description,
      'member_ids': memberIds,
      'split_mode': splitMode,
    };
    if (splits != null && splits.isNotEmpty) {
      payload['splits'] = splits;
    }

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/expenses',
      payload,
      token: token,
      headers: {'Idempotency-Key': idempotencyKey},
    );

    return Expense.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<Expense>> getExpenses(
    String tripId, {
    String? category,
    String? memberId,
    String? search,
    String? sort,
  }) async {
    final token = await _getToken();

    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (memberId != null && memberId.isNotEmpty) {
      queryParams['member_id'] = memberId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    final uri = Uri.parse('${ApiConstants.trips}/$tripId/expenses').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    final expenses = response as List;

    return expenses
        .map((item) => Expense.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Expense> getExpense({
    required String tripId,
    required String expenseId,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/expenses/$expenseId',
      token: token,
    );

    return Expense.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Expense> cancelExpense(
  String tripId,
  String expenseId,
) async {
  final token = await _getToken();

  final response = await _apiClient.post(
    '${ApiConstants.trips}/$tripId/expenses/$expenseId/cancel',
    {},
    token: token,
  );

  return Expense.fromJson(
    Map<String, dynamic>.from(response),
  );
}

Future<Expense> updateExpense({
  required String tripId,
  required String expenseId,
  required int amountPaise,
  required String category,
  String? description,
  required List<String> memberIds,
  String splitMode = 'EQUAL',
  List<Map<String, dynamic>>? splits,
}) async {
  final token = await _getToken();

  final payload = <String, dynamic>{
    'amount_paise': amountPaise,
    'category': category,
    'description': description,
    'member_ids': memberIds,
    'split_mode': splitMode,
  };
  if (splits != null && splits.isNotEmpty) {
    payload['splits'] = splits;
  }

  final response = await _apiClient.put(
    '${ApiConstants.trips}/$tripId/expenses/$expenseId',
    payload,
    token: token,
  );

  return Expense.fromJson(
    Map<String, dynamic>.from(response),
  );
}
}
