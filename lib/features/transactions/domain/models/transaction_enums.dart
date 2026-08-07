enum TransactionType {
  sale,
  repair,
  trade,
  disposal,
  consignment,
  askingPriceChange,
}

enum PaymentMethod { cash, card, venmo, paypal, zelle }

extension TransactionTypeLabel on TransactionType {
  String get label {
    return switch (this) {
      TransactionType.sale => 'Sale',
      TransactionType.repair => 'Repair',
      TransactionType.trade => 'Trade',
      TransactionType.disposal => 'Disposal',
      TransactionType.consignment => 'Consignment',
      TransactionType.askingPriceChange => 'Asking Price Change',
    };
  }
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    return switch (this) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.venmo => 'Venmo',
      PaymentMethod.paypal => 'PayPal',
      PaymentMethod.zelle => 'Zelle',
    };
  }
}
