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

    test('PaymentHistoryItem.fromJson parses payment history item correctly', () {
      final json = {
        'id': 'a1b2c3d4-0000-0000-0000-000000000001',
        'trip_id': 'a1b2c3d4-0000-0000-0000-000000000002',
        'user_id': 'a1b2c3d4-0000-0000-0000-000000000003',
        'user_name': 'Test Payer',
        'amount_paise': 75000,
        'provider': 'razorpay',
        'provider_order_id': 'order_test_999',
        'provider_payment_id': 'pay_test_888',
        'status': 'SUCCESS',
        'created_at': '2026-09-16T10:00:00.000Z',
      };

      final item = PaymentHistoryItem.fromJson(json);

      expect(item.id, 'a1b2c3d4-0000-0000-0000-000000000001');
      expect(item.userName, 'Test Payer');
      expect(item.amountPaise, 75000);
      expect(item.status, 'SUCCESS');
      expect(item.providerPaymentId, 'pay_test_888');
    });

    test('PaymentRefundResult.fromJson parses refund response correctly', () {
      final json = {
        'refund_id': 'rfnd_uuid_123',
        'payment_id': 'pay_uuid_456',
        'razorpay_refund_id': 'rfnd_rzp_789',
        'amount_paise': 50000,
        'status': 'PROCESSED',
        'created_at': '2026-09-16T12:00:00.000Z',
      };

      final refund = PaymentRefundResult.fromJson(json);

      expect(refund.refundId, 'rfnd_uuid_123');
      expect(refund.razorpayRefundId, 'rfnd_rzp_789');
      expect(refund.amountPaise, 50000);
      expect(refund.status, 'PROCESSED');
    });

    test('PaymentReconcileResult.fromJson parses reconcile response correctly', () {
      final json = {
        'payment_id': 'pay_rec_123',
        'provider_order_id': 'order_rec_456',
        'previous_status': 'CREATED',
        'current_status': 'SUCCESS',
        'reconciled': true,
        'detail': 'Payment captured and credited to wallet',
      };

      final result = PaymentReconcileResult.fromJson(json);

      expect(result.paymentId, 'pay_rec_123');
      expect(result.previousStatus, 'CREATED');
      expect(result.currentStatus, 'SUCCESS');
      expect(result.reconciled, isTrue);
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
