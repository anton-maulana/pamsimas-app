// ─── Bill Model ───────────────────────────────────────────────────────────────

class BillCreate {
  final int customerId;
  final int billingMonth;
  final int billingYear;
  final int meterStart;
  final int meterEnd;
  final int usage;
  final double amount;
  final String status;
  final String? notes;

  const BillCreate({
    required this.customerId,
    required this.billingMonth,
    required this.billingYear,
    required this.meterStart,
    required this.meterEnd,
    required this.usage,
    required this.amount,
    this.status = 'unpaid',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'billing_month': billingMonth,
        'billing_year': billingYear,
        'meter_start': meterStart,
        'meter_end': meterEnd,
        'usage': usage,
        'amount': amount,
        'status': status,
        if (notes != null) 'notes': notes,
      };
}

class BillRead {
  final int id;
  final int customerId;
  final int billingMonth;
  final int billingYear;
  final int meterStart;
  final int meterEnd;
  final int usage;
  final double amount;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const BillRead({
    required this.id,
    required this.customerId,
    required this.billingMonth,
    required this.billingYear,
    required this.meterStart,
    required this.meterEnd,
    required this.usage,
    required this.amount,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory BillRead.fromJson(Map<String, dynamic> json) => BillRead(
        id: json['id'] as int,
        customerId: json['customer_id'] as int,
        billingMonth: json['billing_month'] as int,
        billingYear: json['billing_year'] as int,
        meterStart: json['meter_start'] as int,
        meterEnd: json['meter_end'] as int,
        usage: json['usage'] as int,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
