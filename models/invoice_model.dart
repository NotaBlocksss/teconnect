class InvoiceModel {
  final String id;
  final String userId; // ID del usuario/cliente
  final String invoiceNumber; // Número de factura único
  final String customerName;
  final String? customerLastName;
  final String? customerAddress;
  final String? customerPhone;
  final String? customerEmail;
  final String internetPlan; // Plan de internet
  final double amount; // Monto de la factura
  final DateTime issueDate; // Fecha de emisión
  final DateTime dueDate; // Fecha de vencimiento
  final DateTime? sendDate; // Fecha programada para enviar
  final String status; // 'Pendiente', 'Pagada', 'Corte de Servicio'
  final String? notes; // Notas adicionales
  final DateTime createdAt;
  final DateTime? paidAt; // Fecha de pago
  final DateTime? sentAt; // Fecha en que se envió
  final bool autoSend; // Si se envía automáticamente
  final String? paymentMethod; // Método de pago
  final String? paymentReference; // Referencia de pago

  InvoiceModel({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerLastName,
    this.customerAddress,
    this.customerPhone,
    this.customerEmail,
    required this.internetPlan,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    this.sendDate,
    this.status = 'Pendiente',
    this.notes,
    required this.createdAt,
    this.paidAt,
    this.sentAt,
    this.autoSend = false,
    this.paymentMethod,
    this.paymentReference,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      userId: map['userId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerName: map['customerName'] ?? '',
      customerLastName: map['customerLastName'],
      customerAddress: map['customerAddress'],
      customerPhone: map['customerPhone'],
      customerEmail: map['customerEmail'],
      internetPlan: map['internetPlan'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      issueDate: map['issueDate']?.toDate() ?? DateTime.now(),
      dueDate: map['dueDate']?.toDate() ?? DateTime.now(),
      sendDate: map['sendDate']?.toDate(),
      status: map['status'] ?? 'Pendiente',
      notes: map['notes'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      paidAt: map['paidAt']?.toDate(),
      sentAt: map['sentAt']?.toDate(),
      autoSend: map['autoSend'] ?? false,
      paymentMethod: map['paymentMethod'],
      paymentReference: map['paymentReference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerLastName': customerLastName,
      'customerAddress': customerAddress,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'internetPlan': internetPlan,
      'amount': amount,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'sendDate': sendDate,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'sentAt': sentAt,
      'autoSend': autoSend,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? userId,
    String? invoiceNumber,
    String? customerName,
    String? customerLastName,
    String? customerAddress,
    String? customerPhone,
    String? customerEmail,
    String? internetPlan,
    double? amount,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? sendDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? sentAt,
    bool? autoSend,
    String? paymentMethod,
    String? paymentReference,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerLastName: customerLastName ?? this.customerLastName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      internetPlan: internetPlan ?? this.internetPlan,
      amount: amount ?? this.amount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      sendDate: sendDate ?? this.sendDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      sentAt: sentAt ?? this.sentAt,
      autoSend: autoSend ?? this.autoSend,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
    );
  }

  bool get isOverdue => 
      status != 'Pagada' && 
      status != 'Corte de Servicio' && 
      DateTime.now().isAfter(dueDate);

  bool get isPending => status == 'Pendiente';
  bool get isPaid => status == 'Pagada';
  bool get isServiceCut => status == 'Corte de Servicio';

  // Obtener el precio del plan desde el string del plan guardado
  static double getPlanPrice(String planString) {
    if (planString.isEmpty) {
      return 50000.0; // Valor por defecto
    }

    // Intentar extraer el precio del string (formato: "Plan... - XX.XXX COP")
    final priceMatch = RegExp(r'-\s*([\d.]+)\s*COP').firstMatch(planString);
    if (priceMatch != null) {
      final priceStr = priceMatch.group(1)?.replaceAll('.', '') ?? '';
      final price = double.tryParse(priceStr);
      if (price != null && price > 0) {
        return price;
      }
    }

    // Si no se puede extraer el precio, calcular basado en el plan detectado
    return _calculatePlanPriceFromString(planString);
  }

  // Calcular precio basado en el tipo de plan detectado en el string
  static double _calculatePlanPriceFromString(String planString) {
    final planLower = planString.toLowerCase();

    // Plan básico: 8 Mbps = 50,000
    if (planLower.contains('plan residencial básico') || 
        planLower.contains('plan_basico') ||
        planLower.contains('básico')) {
      return 50000.0;
    }

    // Plan estándar: 10 Mbps = 70,000
    if (planLower.contains('plan residencial standar') || 
        planLower.contains('plan_standar') ||
        planLower.contains('standar') ||
        planLower.contains('estandar')) {
      return 70000.0;
    }

    // Plan personalizado: calcular basado en Mbps
    if (planLower.contains('plan personalizado') || planLower.contains('personalizado')) {
      // Extraer Mbps del string
      final mbpsMatch = RegExp(r'(\d+)\s*mbps').firstMatch(planLower);
      if (mbpsMatch != null) {
        final mbps = double.tryParse(mbpsMatch.group(1) ?? '8') ?? 8.0;
        return _calculateCustomPlanPrice(mbps);
      }
    }

    // Si contiene un número de Mbps, calcular precio personalizado
    final mbpsMatch = RegExp(r'(\d+)\s*mbps').firstMatch(planLower);
    if (mbpsMatch != null) {
      final mbps = double.tryParse(mbpsMatch.group(1) ?? '8') ?? 8.0;
      return _calculateCustomPlanPrice(mbps);
    }

    // Valor por defecto
    return 50000.0;
  }

  // Calcular precio para plan personalizado basado en Mbps
  static double _calculateCustomPlanPrice(double mbps) {
    if (mbps <= 8) {
      return 50000.0;
    }
    // Precio base (8 mbps) + incremento proporcional
    const basePrice = 50000.0;
    final additionalMbps = mbps - 8;
    const pricePerMbps = 10000.0;
    return basePrice + (additionalMbps * pricePerMbps);
  }

  // Obtener el nombre del plan desde el string
  static String getPlanName(String planString) {
    if (planString.isEmpty) {
      return 'Plan no especificado';
    }

    // Extraer solo el nombre del plan (antes del guion)
    final nameMatch = RegExp(r'^([^-]+)').firstMatch(planString);
    if (nameMatch != null) {
      return nameMatch.group(1)?.trim() ?? planString;
    }

    return planString;
  }
}

