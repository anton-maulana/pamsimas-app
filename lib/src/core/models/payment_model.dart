// ─── Payment Model ────────────────────────────────────────────────────────────

class PaymentCreate {
  final int billId;
  final double amountPaid;
  final String paymentMethod;
  final String? referenceNumber;
  final String status;
  final String? notes;

  const PaymentCreate({
    required this.billId,
    required this.amountPaid,
    required this.paymentMethod,
    this.referenceNumber,
    this.status = 'completed',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'bill_id': billId,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
        if (referenceNumber != null) 'reference_number': referenceNumber,
        'status': status,
        if (notes != null) 'notes': notes,
      };
}

class PaymentRead {
  final int id;
  final int billId;
  final double amountPaid;
  final String paymentMethod;
  final String? referenceNumber;
  final String status;
  final String? notes;
  final DateTime paymentDate;

  const PaymentRead({
    required this.id,
    required this.billId,
    required this.amountPaid,
    required this.paymentMethod,
    this.referenceNumber,
    required this.status,
    this.notes,
    required this.paymentDate,
  });

  factory PaymentRead.fromJson(Map<String, dynamic> json) => PaymentRead(
        id: json['id'] as int,
        billId: json['bill_id'] as int,
        amountPaid: (json['amount_paid'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        referenceNumber: json['reference_number'] as String?,
        status: json['status'] as String,
        notes: json['notes'] as String?,
        paymentDate: DateTime.parse(json['payment_date'] as String),
      );
}
