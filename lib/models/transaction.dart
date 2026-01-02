class BuyerInfo {
  BuyerInfo({
    required this.name,
    required this.phone,
    required this.address,
    this.quantity = 1,
    this.note,
    this.paymentMethod = 'cash_on_delivery',
  });

  final String name;
  final String phone;
  final String address;
  final int quantity;
  final String? note;
  final String paymentMethod; // cash_on_delivery | bank_transfer
}

class BankTransferInfo {
  BankTransferInfo({
    required this.accountNumber,
    required this.bankName,
    required this.accountHolder,
    this.shippingFee = 0,
    this.totalAmount = 0,
    this.qrImageData,
  });

  final String accountNumber;
  final String bankName;
  final String accountHolder;
  final double shippingFee;
  final double totalAmount;
  final String? qrImageData; // base64 or url
}

class PurchaseTransaction {
  PurchaseTransaction({
    required this.id,
    required this.postId,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.timestamp,
    required this.status,
    required this.buyerInfo,
    this.sellerAvatar,
    this.buyerAvatar,
    this.cancelReason,
    this.bankTransferInfo,
  });

  final String id;
  final String postId;
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final String? sellerAvatar;
  final String? buyerAvatar;
  final DateTime timestamp;
  String status; // pending | approved | cancelled | awaiting_payment | completed
  final BuyerInfo buyerInfo;
  String? cancelReason;
  BankTransferInfo? bankTransferInfo;
}
