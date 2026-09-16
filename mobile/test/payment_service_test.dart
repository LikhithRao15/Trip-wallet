import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/payment_order.dart';

void main() {
  group('PaymentOrder Model Tests', () {
    test('PaymentOrder.fromJson parses backend order response correctly', () {
      final json = {
        'payment_id': 'c8a32a67-62aa-4b09-ba2a-a92c0d8f07b1',
        'razorpay_order_id': 'order_QweRty123456',
        'amount_paise': 50000,
        'currency': 'INR',
        'razorpay_key_id': 'rzp_test_mockKey123',
        'status': 'CREATED',
      };

      final order = PaymentOrder.fromJson(json);

      expect(order.paymentId, 'c8a32a67-62aa-4b09-ba2a-a92c0d8f07b1');
      expect(order.razorpayOrderId, 'order_QweRty123456');
      expect(order.amountPaise, 50000);
      expect(order.currency, 'INR');
      expect(order.razorpayKeyId, 'rzp_test_mockKey123');
      expect(order.status, 'CREATED');

      final serialized = order.toJson();
      expect(serialized['amount_paise'], 50000);
      expect(serialized['currency'], 'INR');
      expect(serialized['razorpay_key_id'], 'rzp_test_mockKey123');
    });

    test('PaymentVerificationResult.fromJson parses verification response correctly', () {
      final json = {
        'payment_id': 'c8a32a67-62aa-4b09-ba2a-a92c0d8f07b1',
        'razorpay_payment_id': 'pay_mockPayment999',
        'razorpay_order_id': 'order_QweRty123456',
        'status': 'SUCCESS',
      };

      final result = PaymentVerificationResult.fromJson(json);

      expect(result.paymentId, 'c8a32a67-62aa-4b09-ba2a-a92c0d8f07b1');
      expect(result.razorpayPaymentId, 'pay_mockPayment999');
      expect(result.razorpayOrderId, 'order_QweRty123456');
      expect(result.status, 'SUCCESS');
    });

    test('Integer paise conversion prevents floating point inaccuracies', () {
      // Simulates converting rupees from user input to integer paise
      const inputRupees = '100.50';
      final parts = inputRupees.split('.');
      final rupees = int.parse(parts[0]);
      final paise = int.parse(parts[1].padRight(2, '0'));
      final totalPaise = rupees * 100 + paise;

      expect(totalPaise, 10050);
    });
  });
}
