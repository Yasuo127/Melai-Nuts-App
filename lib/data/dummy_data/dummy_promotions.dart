import '../models/promotion.dart';

/// Real, staff/owner-managed promo banners for the customer Home dashboard
/// (`promotions` table — see `lib/data/repositories/products_repository.dart`).
///
/// Starts empty and stays empty until the fetch resolves. Unlike
/// [kProductCategories]/[kProducts] there is deliberately NO placeholder
/// content here: a promo banner is a claim about a real, current offer, so
/// showing a made-up one (even briefly) would be misleading. The Home
/// screen simply omits the promo section while this list is empty.
final List<Promotion> kPromotions = <Promotion>[];
