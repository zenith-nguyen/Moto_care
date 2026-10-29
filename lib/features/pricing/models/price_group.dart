enum PriceCategory { rescue, tire, battery }

typedef PriceItem = (String name, String price);
typedef PriceGroup = (
  String title,
  PriceCategory category,
  List<PriceItem> items,
);
