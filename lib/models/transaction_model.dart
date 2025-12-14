/// A class representing a transaction when a user downloads a set.
///
/// This tracks all marketplace transactions, preparing for future payment integration.
/// Currently, all transactions have amount = 0 (free downloads).
class TransactionModel {
  /// Unique transaction ID
  final String id;

  /// User ID of the buyer (person downloading the set)
  final String buyerId;

  /// User ID of the seller (original creator of the set)
  final String sellerId;

  /// ID of the set being downloaded
  final String setId;

  /// Timestamp when the transaction occurred
  final DateTime timestamp;

  /// Transaction amount (currently 0 for free downloads, prepared for future payments)
  final double amount;

  TransactionModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.setId,
    required this.timestamp,
    this.amount = 0.0,
  });

  /// Factory constructor to create a TransactionModel from a JSON object
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      setId: json['setId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Method to convert a TransactionModel object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'setId': setId,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
    };
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, buyerId: $buyerId, sellerId: $sellerId, '
        'setId: $setId, timestamp: $timestamp, amount: $amount)';
  }
}
