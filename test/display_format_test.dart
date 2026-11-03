import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/utils/display_format.dart';

void main() {
  test('clock times read like a person would say them', () {
    expect(formatClockTime('16:00:34'), '4:00 PM');
    expect(formatClockTime('08:30'), '8:30 AM');
    expect(formatClockTime('00:05:00'), '12:05 AM');
    expect(formatClockTime('4:00 PM'), '4:00 PM');
    expect(formatClockTime(''), '');
    expect(formatClockTime('soon'), 'soon');
  });

  test('statuses become words', () {
    expect(humanizeStatus('PaymentPending'), 'Payment pending');
    expect(humanizeStatus('PAYMENT_PENDING'), 'Payment pending');
    expect(humanizeStatus('confirmed'), 'Confirmed');
    expect(humanizeStatus('In Progress'), 'In progress');
  });

  test('status keys group spellings of the same status', () {
    expect(statusKey('PaymentPending'), statusKey('Payment pending'));
    expect(statusKey('PAYMENT_PENDING'), statusKey('paymentpending'));
    expect(statusKey('Confirmed') == statusKey('Completed'), isFalse);
  });
}
