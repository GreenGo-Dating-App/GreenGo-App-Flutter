/// Canonical business/venue categories used across the Business feature
/// (business account editor + storefront editor).
///
/// Stored on `profiles/{uid}.businessCategory` as the raw English string — this
/// is a canonical data value (like a country code), so it is intentionally NOT
/// localized; the surrounding labels/hints are localized as usual.
///
/// Keep this list stable and append-only where possible: changing an existing
/// entry would orphan businesses already saved under the old string.
class BusinessCategories {
  const BusinessCategories._();

  /// 50 curated categories spanning food, nightlife, hospitality, culture,
  /// wellness, travel, retail and services — the segments GreenGo businesses
  /// actually operate in.
  static const List<String> all = <String>[
    'Restaurant',
    'Bar',
    'Cafe',
    'Nightclub',
    'Lounge',
    'Hotel',
    'Hostel',
    'Guesthouse',
    'Resort',
    'Bed & Breakfast',
    'Gym',
    'Yoga Studio',
    'Fitness Studio',
    'Spa',
    'Wellness Center',
    'Beauty Salon',
    'Barbershop',
    'Museum',
    'Art Gallery',
    'Theater',
    'Cinema',
    'Live Music Venue',
    'Cultural Center',
    'Tour Operator',
    'Travel Agency',
    'Language School',
    'Cooking School',
    'Dance Studio',
    'Coworking Space',
    'Event Venue',
    'Conference Center',
    'Shop / Retail',
    'Boutique',
    'Bookstore',
    'Market',
    'Winery',
    'Brewery',
    'Distillery',
    'Food Truck',
    'Bakery',
    'Coffee Roastery',
    'Sports Club',
    'Adventure & Outdoor',
    'Diving Center',
    'Photography Studio',
    'Coaching & Consulting',
    'Nonprofit & NGO',
    'Community Center',
    'Transportation Service',
    'Other',
  ];
}
