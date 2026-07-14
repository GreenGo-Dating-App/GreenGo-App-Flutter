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

  /// The same 50 categories organised into user-facing sections, used to render
  /// an easy grouped-chip picker (instead of a long flat dropdown). Every value
  /// here also appears in [all]; section names are organisational labels.
  static const Map<String, List<String>> grouped = <String, List<String>>{
    'Food & Drink': [
      'Restaurant', 'Bar', 'Cafe', 'Bakery', 'Food Truck',
      'Coffee Roastery', 'Winery', 'Brewery', 'Distillery',
    ],
    'Nightlife': ['Nightclub', 'Lounge', 'Live Music Venue'],
    'Stay': ['Hotel', 'Hostel', 'Guesthouse', 'Resort', 'Bed & Breakfast'],
    'Wellness': [
      'Gym', 'Yoga Studio', 'Fitness Studio', 'Spa', 'Wellness Center',
      'Beauty Salon', 'Barbershop',
    ],
    'Culture': [
      'Museum', 'Art Gallery', 'Theater', 'Cinema', 'Cultural Center',
    ],
    'Travel & Tours': [
      'Tour Operator', 'Travel Agency', 'Adventure & Outdoor', 'Diving Center',
    ],
    'Learn & Work': [
      'Language School', 'Cooking School', 'Dance Studio', 'Coworking Space',
      'Photography Studio', 'Coaching & Consulting',
    ],
    'Events': ['Event Venue', 'Conference Center'],
    'Retail': ['Shop / Retail', 'Boutique', 'Bookstore', 'Market'],
    'Community & Services': [
      'Sports Club', 'Nonprofit & NGO', 'Community Center',
      'Transportation Service', 'Other',
    ],
  };
}
