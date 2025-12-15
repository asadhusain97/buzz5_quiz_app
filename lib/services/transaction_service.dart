import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buzz5_quiz_app/models/transaction_model.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:uuid/uuid.dart';

/// Service for managing marketplace transactions.
///
/// This service handles creating and retrieving transaction records
/// for set downloads from the marketplace.
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Creates a new transaction record in Firestore.
  ///
  /// This is called whenever a user downloads a set from the marketplace.
  ///
  /// Parameters:
  /// - buyerId: The UID of the user downloading the set
  /// - sellerId: The UID of the original set creator
  /// - setId: The ID of the set being downloaded
  /// - amount: The transaction amount (currently 0 for free downloads)
  ///
  /// Returns: The ID of the created transaction
  Future<String> createTransaction({
    required String buyerId,
    required String sellerId,
    required String setId,
    double amount = 0.0,
  }) async {
    try {
      final String transactionId = _uuid.v4();

      final transaction = TransactionModel(
        id: transactionId,
        buyerId: buyerId,
        sellerId: sellerId,
        setId: setId,
        timestamp: DateTime.now(),
        amount: amount,
      );

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .set(transaction.toJson());

      AppLogger.i(
        'Transaction created successfully: $transactionId '
        '(buyer: $buyerId, seller: $sellerId, set: $setId, amount: $amount)',
      );

      return transactionId;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error creating transaction: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Retrieves all transactions for a specific user as a buyer.
  ///
  /// Parameters:
  /// - buyerId: The UID of the user
  ///
  /// Returns: List of transactions where the user was the buyer
  Future<List<TransactionModel>> getUserPurchases(String buyerId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error fetching user purchases: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Retrieves all transactions for a specific user as a seller.
  ///
  /// Parameters:
  /// - sellerId: The UID of the user
  ///
  /// Returns: List of transactions where the user was the seller
  Future<List<TransactionModel>> getUserSales(String sellerId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error fetching user sales: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Retrieves all transactions for a specific set.
  ///
  /// Parameters:
  /// - setId: The ID of the set
  ///
  /// Returns: List of all transactions involving this set
  Future<List<TransactionModel>> getSetTransactions(String setId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('setId', isEqualTo: setId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error fetching set transactions: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
