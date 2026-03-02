import 'package:cloud_firestore/cloud_firestore.dart';

/// Seed data for the Cultural Exchange feature.
/// Contains dating etiquette for 20+ countries, sample spotlights, and sample tips.
class CulturalExchangeSeedData {
  CulturalExchangeSeedData._();

  /// Seeds Firestore with initial data if the collections are empty.
  static Future<void> seedIfNeeded(FirebaseFirestore firestore) async {
    await Future.wait([
      _seedDatingEtiquette(firestore),
      _seedCountrySpotlights(firestore),
      _seedCulturalTips(firestore),
    ]);
  }

  // ==================== Dating Etiquette ====================

  static Future<void> _seedDatingEtiquette(FirebaseFirestore firestore) async {
    final collection = firestore.collection('dating_etiquette');
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already seeded

    final batch = firestore.batch();

    for (final entry in _datingEtiquetteData.entries) {
      batch.set(collection.doc(entry.key), {
        'country': entry.key,
        'sections': entry.value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static final Map<String, List<Map<String, dynamic>>> _datingEtiquetteData = {
    'Japan': [
      {
        'title': 'First Dates',
        'content':
            'First dates in Japan tend to be casual and low-pressure. Common first dates include visiting a cafe, going to a theme park, or walking through a scenic area. Group dates (goukon) are also popular as a way to meet potential partners.',
        'doList': [
          'Be punctual - arriving late is considered very rude',
          'Dress neatly and conservatively',
          'Split the bill or offer to pay for the whole thing',
          'Show genuine interest in their hobbies and work',
          'Be polite and use appropriate honorifics',
        ],
        'dontList': [
          'Avoid excessive physical contact on the first date',
          'Do not talk about salary or money',
          'Do not be overly forward or aggressive',
          'Avoid loud or boisterous behavior in public',
          'Do not assume exclusivity after one date',
        ],
      },
      {
        'title': 'Communication Style',
        'content':
            'Japanese dating culture emphasizes indirect communication. Reading between the lines is important. Confessing feelings (kokuhaku) is a significant step that formally starts a relationship.',
        'doList': [
          'Pay attention to subtle cues and body language',
          'Respond to messages promptly but not obsessively',
          'Use LINE (messaging app) as the primary communication tool',
          'Be patient and allow the relationship to develop naturally',
        ],
        'dontList': [
          'Do not be too direct about your feelings early on',
          'Avoid excessive texting or calling',
          'Do not pressure for a quick response',
          'Avoid oversharing personal information too early',
        ],
      },
      {
        'title': 'Relationship Milestones',
        'content':
            'Japanese relationships often progress through specific stages. The kokuhaku (confession) officially starts a relationship. Meeting friends, then family, marks deepening commitment. White Day (March 14) is when men reciprocate Valentine\'s gifts.',
        'doList': [
          'Celebrate monthly anniversaries (especially early on)',
          'Exchange thoughtful gifts on special occasions',
          'Respect the pace your partner is comfortable with',
          'Show affection privately rather than publicly',
        ],
        'dontList': [
          'Do not rush physical intimacy',
          'Do not forget important dates and anniversaries',
          'Avoid comparing your relationship to Western norms',
          'Do not pressure to meet family too early',
        ],
      },
    ],
    'Brazil': [
      {
        'title': 'First Dates',
        'content':
            'Brazilian dating culture is warm, passionate, and expressive. First dates often involve food and drinks at a lively restaurant or bar. Brazilians are known for their warmth and physical expressiveness.',
        'doList': [
          'Greet with a kiss on the cheek (common in Brazil)',
          'Be open and expressive with your feelings',
          'Compliment your date sincerely',
          'Be prepared for a lively and animated conversation',
          'Dress well - Brazilians appreciate good style',
        ],
        'dontList': [
          'Do not be reserved or overly formal',
          'Avoid being stiff or emotionally distant',
          'Do not criticize Brazilian culture or customs',
          'Do not refuse physical affection if offered warmly',
          'Avoid arriving exactly on time - slight lateness is normal',
        ],
      },
      {
        'title': 'Communication Style',
        'content':
            'Brazilians communicate with warmth and directness. WhatsApp is the primary messaging platform. Video calls and voice messages are common. Expressing affection openly is expected and valued.',
        'doList': [
          'Send good morning and goodnight messages',
          'Use voice messages and video calls',
          'Be open about your feelings and intentions',
          'Share your daily life through messages and photos',
        ],
        'dontList': [
          'Do not be cold or distant in messaging',
          'Avoid being overly formal in texts',
          'Do not ignore messages for long periods',
          'Avoid being too mysterious or playing hard to get',
        ],
      },
    ],
    'France': [
      {
        'title': 'First Dates',
        'content':
            'French dating is famously relaxed and sophisticated. There is no formal "dating" concept - instead, people spend time together and things develop naturally. A coffee or wine at a cafe is a classic first date.',
        'doList': [
          'Be yourself and show your personality',
          'Engage in intellectual conversation',
          'Appreciate good food and wine',
          'Be well-groomed and dress with style',
          'Show cultural awareness and open-mindedness',
        ],
        'dontList': [
          'Do not define the relationship too early',
          'Avoid being overly enthusiastic or intense',
          'Do not talk about money or material possessions',
          'Avoid rushing physical intimacy',
          'Do not be too casual in appearance',
        ],
      },
      {
        'title': 'Relationship Culture',
        'content':
            'In France, relationships tend to evolve organically without labels. The concept of "exclusivity talk" is less common - if you are dating someone regularly, exclusivity is often assumed. Public displays of affection are natural and welcome.',
        'doList': [
          'Let the relationship unfold naturally',
          'Show affection openly in public',
          'Be intellectually stimulating',
          'Appreciate art, culture, and cuisine together',
        ],
        'dontList': [
          'Do not have "the talk" about being exclusive too soon',
          'Avoid playing games or being manipulative',
          'Do not be possessive or jealous without reason',
          'Avoid being loud or overly dramatic in public',
        ],
      },
    ],
    'India': [
      {
        'title': 'First Dates',
        'content':
            'Dating in India varies significantly by region, religion, and family background. Urban dating has become more modern, but traditional values still play a significant role. Coffee dates and casual outings are popular in cities.',
        'doList': [
          'Be respectful of their cultural and religious background',
          'Dress modestly and appropriately',
          'Show genuine interest in their family and traditions',
          'Be patient - relationships often progress slowly',
          'Choose public, well-known venues for dates',
        ],
        'dontList': [
          'Do not pressure for physical intimacy',
          'Avoid criticizing their family or traditions',
          'Do not discuss marriage or long-term plans too early',
          'Avoid excessive drinking on dates',
          'Do not assume all Indians have the same dating norms',
        ],
      },
      {
        'title': 'Family Involvement',
        'content':
            'Family plays a central role in Indian relationships. Meeting the family is a significant milestone and often happens earlier than in Western cultures. Family approval is highly valued and can influence the relationship\'s progression.',
        'doList': [
          'Show respect to elders in the family',
          'Be open about your intentions and background',
          'Participate in family gatherings when invited',
          'Learn about their family customs and traditions',
        ],
        'dontList': [
          'Do not disregard family opinions entirely',
          'Avoid being disrespectful to parents or elders',
          'Do not hide the relationship from family for too long',
          'Avoid making promises you cannot keep to the family',
        ],
      },
    ],
    'South Korea': [
      {
        'title': 'First Dates',
        'content':
            'Korean dating culture involves a lot of cute and romantic gestures. Couple culture is strong - matching outfits, couple rings, and celebrating every 100 days are common. Meeting through friends or apps is popular.',
        'doList': [
          'Plan creative and fun date activities',
          'Celebrate couple milestones (100 days, 200 days, etc.)',
          'Show affection through small gifts and gestures',
          'Pay attention to your appearance and fashion',
          'Be caring and attentive to your date\'s needs',
        ],
        'dontList': [
          'Do not be too independent or aloof',
          'Avoid being late without a good reason',
          'Do not forget important couple dates',
          'Avoid being overly jealous or controlling',
          'Do not ignore their friend group dynamics',
        ],
      },
      {
        'title': 'Communication & Expectations',
        'content':
            'Frequent communication is expected in Korean relationships. "Good morning" and "good night" texts are standard. Couples often check in with each other throughout the day. KakaoTalk is the primary messaging platform.',
        'doList': [
          'Send regular check-in messages throughout the day',
          'Use KakaoTalk for communication',
          'Share your daily life through photos and updates',
          'Be responsive and communicative',
        ],
        'dontList': [
          'Do not go long periods without contacting your partner',
          'Avoid being emotionally unavailable',
          'Do not hide your phone or be secretive',
          'Avoid being too casual about couple anniversaries',
        ],
      },
    ],
    'Italy': [
      {
        'title': 'Romance & Dating',
        'content':
            'Italy is synonymous with romance. Italian dating is passionate, expressive, and food-centered. Dates often involve long dinners with wine and animated conversation. Italians appreciate confidence and charm.',
        'doList': [
          'Be confident and expressive with compliments',
          'Appreciate and enjoy good food and wine',
          'Dress impeccably - style matters in Italy',
          'Be romantic and attentive',
          'Show passion for life and conversation',
        ],
        'dontList': [
          'Do not be shy or reserved with your feelings',
          'Avoid being rude to restaurant staff',
          'Do not rush through meals',
          'Avoid criticizing Italian cuisine or culture',
          'Do not be stingy with compliments',
        ],
      },
    ],
    'Germany': [
      {
        'title': 'Dating Culture',
        'content':
            'German dating is known for its directness and practicality. Germans value honesty and straightforwardness. Splitting the bill is common. Dates tend to be more low-key and activity-based.',
        'doList': [
          'Be direct and honest about your intentions',
          'Be punctual - it is very important in German culture',
          'Offer to split the bill unless you explicitly offered to pay',
          'Show genuine interest in meaningful conversation',
          'Suggest active dates like hiking or museum visits',
        ],
        'dontList': [
          'Do not play games or be indirect',
          'Avoid excessive flattery or insincere compliments',
          'Do not be late without informing your date',
          'Avoid being superficial in conversation',
          'Do not assume gender roles in paying for dates',
        ],
      },
    ],
    'Mexico': [
      {
        'title': 'Dating & Romance',
        'content':
            'Mexican dating culture is warm, family-oriented, and romantic. Courtship is valued, and men are often expected to be chivalrous. Dates typically involve food, music, and vibrant social settings.',
        'doList': [
          'Be chivalrous and romantic in your gestures',
          'Show respect for their family and traditions',
          'Be prepared for lively and expressive conversations',
          'Enjoy authentic Mexican food together',
          'Learn some Spanish phrases to show effort',
        ],
        'dontList': [
          'Do not disrespect their family or cultural traditions',
          'Avoid being cold or emotionally distant',
          'Do not refuse food that is offered to you',
          'Avoid stereotyping Mexican culture',
          'Do not rush the courtship process',
        ],
      },
    ],
    'Thailand': [
      {
        'title': 'Dating Norms',
        'content':
            'Thai dating culture balances modernity with traditional Buddhist values. Respect and politeness (known as "kreng jai") are paramount. Public displays of affection are generally minimal.',
        'doList': [
          'Show respect through polite language and behavior',
          'Be gentle and patient in your approach',
          'Show interest in Thai culture and food',
          'Respect Buddhist customs and temple etiquette',
          'Be generous without being flashy',
        ],
        'dontList': [
          'Do not touch anyone\'s head - it is considered sacred',
          'Avoid showing anger or frustration publicly',
          'Do not disrespect the monarchy',
          'Avoid excessive public displays of affection',
          'Do not point your feet at anyone',
        ],
      },
    ],
    'Australia': [
      {
        'title': 'Dating Culture',
        'content':
            'Australian dating is casual, laid-back, and egalitarian. Australians value authenticity and a good sense of humor. Outdoor activities and BBQs are popular date ideas.',
        'doList': [
          'Be genuine and down-to-earth',
          'Have a good sense of humor',
          'Suggest outdoor activities like beach walks or hikes',
          'Be comfortable with splitting the bill',
          'Show interest in sports and outdoor culture',
        ],
        'dontList': [
          'Do not be pretentious or overly serious',
          'Avoid bragging about wealth or status',
          'Do not be too clingy or intense early on',
          'Avoid complaining about the heat or wildlife',
          'Do not take jokes too personally',
        ],
      },
    ],
    'Turkey': [
      {
        'title': 'Dating & Relationships',
        'content':
            'Turkish dating blends modern and traditional values. Family approval is important, and relationships are often viewed with long-term intentions. Turkish hospitality extends to dating with generous and warm gestures.',
        'doList': [
          'Show genuine respect for their family',
          'Be generous and hospitable',
          'Dress well and make a good impression',
          'Learn about Turkish tea and coffee customs',
          'Show you are serious about your intentions',
        ],
        'dontList': [
          'Do not disrespect their family or religion',
          'Avoid being overly casual about the relationship',
          'Do not refuse Turkish hospitality (tea, food, etc.)',
          'Avoid discussing controversial political topics',
          'Do not be dishonest about your intentions',
        ],
      },
    ],
    'Nigeria': [
      {
        'title': 'Dating Culture',
        'content':
            'Nigerian dating culture is vibrant, expressive, and family-centered. Respect for elders and family values is deeply embedded. Relationships often progress with the involvement of extended family.',
        'doList': [
          'Show respect to elders and family members',
          'Be confident and direct about your intentions',
          'Dress well and present yourself neatly',
          'Be genuinely interested in their cultural background',
          'Participate in social and community events',
        ],
        'dontList': [
          'Do not disrespect elders or family customs',
          'Avoid being passive or indecisive',
          'Do not ignore the importance of community',
          'Avoid making assumptions based on stereotypes',
          'Do not be dishonest or unreliable',
        ],
      },
    ],
    'Colombia': [
      {
        'title': 'Dating & Romance',
        'content':
            'Colombian dating culture is warm, passionate, and social. Dancing, especially salsa, plays a big role in socializing and dating. Colombians are expressive and value genuine connections.',
        'doList': [
          'Learn to dance (salsa basics go a long way)',
          'Be warm, open, and expressive',
          'Compliment your date genuinely',
          'Show interest in their culture and music',
          'Be punctual (though slight lateness is acceptable)',
        ],
        'dontList': [
          'Do not be cold or emotionally distant',
          'Avoid stereotyping Colombian culture',
          'Do not refuse to dance when music is playing',
          'Avoid being possessive or jealous',
          'Do not rush physical boundaries',
        ],
      },
    ],
    'Sweden': [
      {
        'title': 'Dating Norms',
        'content':
            'Swedish dating is egalitarian, casual, and low-pressure. The concept of "fika" (coffee date) is the most common first date. Gender equality is deeply ingrained, and both parties are expected to contribute equally.',
        'doList': [
          'Suggest a fika (coffee meeting) as a first date',
          'Be genuine and authentic in conversation',
          'Support gender equality in dating dynamics',
          'Be comfortable with silence - it is not awkward',
          'Respect personal space and boundaries',
        ],
        'dontList': [
          'Do not be overly aggressive or forward',
          'Avoid grand romantic gestures on the first date',
          'Do not assume you should pay for everything',
          'Avoid small talk without substance',
          'Do not invade personal space too quickly',
        ],
      },
    ],
    'Egypt': [
      {
        'title': 'Dating Customs',
        'content':
            'Dating in Egypt is heavily influenced by Islamic values and family expectations. Relationships are typically pursued with marriage in mind. Public behavior between couples is expected to be modest.',
        'doList': [
          'Be respectful of religious and cultural values',
          'Show serious long-term intentions',
          'Dress modestly and appropriately',
          'Seek to meet the family relatively early',
          'Be generous and show you can provide',
        ],
        'dontList': [
          'Do not engage in public displays of affection',
          'Avoid disrespecting religious customs',
          'Do not date casually without serious intentions',
          'Avoid being alone together in private too early',
          'Do not rush physical intimacy',
        ],
      },
    ],
    'Philippines': [
      {
        'title': 'Dating & Courtship',
        'content':
            'Filipino dating culture involves a traditional courtship period called "ligawan." The man is expected to woo the woman with consistent effort and sincerity. Family is central to Filipino relationships.',
        'doList': [
          'Show consistent effort and dedication during courtship',
          'Be respectful to her family, especially parents',
          'Bring small gifts when visiting her home',
          'Attend family gatherings and community events',
          'Learn basic Filipino phrases and customs',
        ],
        'dontList': [
          'Do not be disrespectful to her family',
          'Avoid being impatient with the courtship process',
          'Do not make empty promises',
          'Avoid public confrontation or arguments',
          'Do not ignore the importance of religion and faith',
        ],
      },
    ],
    'Morocco': [
      {
        'title': 'Dating Etiquette',
        'content':
            'Moroccan dating is influenced by Islamic traditions and strong family ties. Relationships in Morocco are typically expected to lead to marriage. Respect, modesty, and family involvement are key aspects.',
        'doList': [
          'Show respect for Islamic customs and traditions',
          'Express serious intentions early on',
          'Dress conservatively and neatly',
          'Be warm and hospitable',
          'Learn about Moroccan tea ceremony customs',
        ],
        'dontList': [
          'Do not engage in public displays of affection',
          'Avoid criticizing religious practices',
          'Do not drink alcohol excessively',
          'Avoid being alone together in private settings early on',
          'Do not disregard family expectations',
        ],
      },
    ],
    'Argentina': [
      {
        'title': 'Dating & Romance',
        'content':
            'Argentinian dating is passionate, intellectual, and deeply romantic. Tango culture influences the expressiveness of relationships. Long dinners with wine and deep conversation are typical dates.',
        'doList': [
          'Be confident and expressive in conversation',
          'Learn to appreciate tango and Argentine culture',
          'Enjoy long dinners with good wine and conversation',
          'Be romantic and attentive',
          'Show intellectual curiosity',
        ],
        'dontList': [
          'Do not be reserved or emotionally distant',
          'Avoid criticizing Argentine beef or wine',
          'Do not rush through meals or dates',
          'Avoid being overly practical about romance',
          'Do not confuse Argentine and Brazilian culture',
        ],
      },
    ],
    'China': [
      {
        'title': 'Dating Culture',
        'content':
            'Chinese dating culture has evolved rapidly with modernization but still values tradition. Family approval remains important. Dates often include meals, movies, or visits to parks and scenic areas.',
        'doList': [
          'Show respect for their family and elders',
          'Be financially responsible and stable',
          'Plan thoughtful and considerate dates',
          'Use WeChat for communication',
          'Show genuine interest in long-term commitment',
        ],
        'dontList': [
          'Do not rush physical intimacy',
          'Avoid disrespecting their parents or family',
          'Do not be wasteful with food or money',
          'Avoid overly casual attitudes toward the relationship',
          'Do not ignore important Chinese holidays',
        ],
      },
    ],
    'Spain': [
      {
        'title': 'Dating & Social Life',
        'content':
            'Spanish dating is social, relaxed, and centered around shared meals and nightlife. Spaniards tend to go out in large groups, and relationships often develop within social circles. Late nights and long dinners are the norm.',
        'doList': [
          'Embrace the late dinner and nightlife culture',
          'Be social and comfortable in group settings',
          'Show affection openly and confidently',
          'Enjoy tapas and wine together',
          'Be spontaneous and fun-loving',
        ],
        'dontList': [
          'Do not expect early dinners (8 PM is early in Spain)',
          'Avoid being too reserved or formal',
          'Do not rush the relationship definition',
          'Avoid being clingy or possessive',
          'Do not insist on strict plans and schedules',
        ],
      },
    ],
    'United Kingdom': [
      {
        'title': 'Dating Culture',
        'content':
            'British dating is known for being polite, understated, and often involves humor. Pub culture plays a significant role in dating. The British tend to be more reserved initially but warm up over time.',
        'doList': [
          'Have a good sense of humor, especially dry wit',
          'Suggest a pub or cocktail bar for a first date',
          'Be polite and well-mannered',
          'Be comfortable with banter and light teasing',
          'Respect personal boundaries and take things slowly',
        ],
        'dontList': [
          'Do not be too forward or aggressive initially',
          'Avoid being overly emotional on early dates',
          'Do not talk about money or salary',
          'Avoid being too loud or boisterous',
          'Do not ignore the art of queuing and British politeness',
        ],
      },
    ],
    'Russia': [
      {
        'title': 'Dating Traditions',
        'content':
            'Russian dating has a more traditional dynamic. Chivalry is expected, and men are typically expected to pay for dates, open doors, and bring flowers. Russians value sincerity and depth in relationships.',
        'doList': [
          'Bring an odd number of flowers on dates (even numbers are for funerals)',
          'Be chivalrous - open doors, pull out chairs',
          'Pay for the date as a man',
          'Dress well and make a strong first impression',
          'Be sincere and show depth of character',
        ],
        'dontList': [
          'Do not bring an even number of flowers',
          'Avoid being cheap or splitting the bill',
          'Do not smile excessively without reason (seen as insincere)',
          'Avoid being superficial in conversation',
          'Do not refuse vodka if offered at a family gathering',
        ],
      },
    ],
    'Kenya': [
      {
        'title': 'Dating Culture',
        'content':
            'Kenyan dating blends modern urban culture with traditional values. In cities like Nairobi, dating apps and social media play a growing role. Respect, community ties, and family values remain central.',
        'doList': [
          'Be respectful and show genuine interest',
          'Be willing to meet their community and friends',
          'Show ambition and purpose in life',
          'Appreciate diverse cultural backgrounds within Kenya',
          'Be open to trying Kenyan cuisine',
        ],
        'dontList': [
          'Do not be disrespectful to elders',
          'Avoid being unreliable or inconsistent',
          'Do not make assumptions about cultural norms',
          'Avoid being overly materialistic',
          'Do not ignore the role of community in relationships',
        ],
      },
    ],
  };

  // ==================== Country Spotlights ====================

  static Future<void> _seedCountrySpotlights(
      FirebaseFirestore firestore) async {
    final collection = firestore.collection('country_spotlights');
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already seeded

    final now = DateTime.now();
    final batch = firestore.batch();

    final spotlights = [
      {
        'country': 'Japan',
        'title': 'Discover the Land of the Rising Sun',
        'imageUrl': '',
        'weekOf': Timestamp.fromDate(now),
        'isActive': true,
        'sections': [
          {
            'title': 'Japanese Cuisine',
            'content':
                'Japan\'s cuisine is a harmonious blend of tradition and innovation. From the delicate art of sushi to the hearty warmth of ramen, each dish tells a story. Seasonal ingredients (shun) are deeply valued, and presentation is considered as important as taste. Must-try experiences include an authentic kaiseki dinner and fresh sushi at Tsukiji Outer Market.',
            'type': 'cuisine',
            'imageUrl': '',
          },
          {
            'title': 'Japanese Customs',
            'content':
                'Japanese society values harmony (wa), respect, and attention to detail. Bowing is the standard greeting, with the depth indicating the level of respect. Removing shoes before entering a home is essential. Gift-giving follows specific rules: always present and receive with both hands, and avoid wrapping in white (associated with funerals).',
            'type': 'customs',
            'imageUrl': '',
          },
          {
            'title': 'Dating in Japan',
            'content':
                'Japanese dating revolves around the concept of kokuhaku (confession), where one person formally declares their feelings. Until this happens, the relationship status remains ambiguous. Couples celebrate monthly anniversaries and exchange gifts on Valentine\'s Day (women give) and White Day (men reciprocate). Public displays of affection are minimal.',
            'type': 'datingEtiquette',
            'imageUrl': '',
          },
          {
            'title': 'Essential Japanese Phrases',
            'content':
                'Konnichiwa (Hello) | Arigatou gozaimasu (Thank you very much) | Sumimasen (Excuse me / Sorry) | Kawaii (Cute) | Oishii (Delicious) | Suki desu (I like you) | Ai shiteru (I love you) | Ganbatte (Good luck / Do your best) | Kanpai (Cheers) | Yoroshiku onegaishimasu (Nice to meet you / Please take care of me)',
            'type': 'keyPhrases',
            'imageUrl': '',
          },
        ],
      },
      {
        'country': 'Brazil',
        'title': 'Explore the Heart of South America',
        'imageUrl': '',
        'weekOf':
            Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'isActive': false,
        'sections': [
          {
            'title': 'Brazilian Cuisine',
            'content':
                'Brazilian food is as diverse as its people. Feijoada (black bean stew with pork) is the national dish, while churrasco (barbecue) is a weekend tradition. Acai bowls originated here, and pao de queijo (cheese bread) is an addictive snack. Each region has distinct flavors, from the seafood moqueca of Bahia to the German-influenced cuisine of the south.',
            'type': 'cuisine',
            'imageUrl': '',
          },
          {
            'title': 'Brazilian Customs',
            'content':
                'Brazilians are known for their warmth and openness. Greetings involve kisses on the cheek (one in Sao Paulo, two in Rio). Personal space is smaller than in many cultures, and conversations are animated and expressive. Carnival is the ultimate expression of Brazilian joy, but year-round, music and dance are woven into daily life.',
            'type': 'customs',
            'imageUrl': '',
          },
          {
            'title': 'Dating in Brazil',
            'content':
                'Brazilian dating is passionate and expressive. "Ficar" (hooking up) is a common starting point, which may or may not lead to "namorar" (dating seriously). Brazilians are affectionate and open about their feelings. Jealousy is sometimes seen as a sign of caring. Meeting the family is a significant step.',
            'type': 'datingEtiquette',
            'imageUrl': '',
          },
          {
            'title': 'Essential Portuguese Phrases',
            'content':
                'Oi / Ola (Hi / Hello) | Tudo bem? (How are you?) | Obrigado/Obrigada (Thank you - male/female) | Por favor (Please) | Voce e muito bonita/bonito (You are very beautiful/handsome) | Te amo (I love you) | Beijo (Kiss) | Saudade (Missing someone - untranslatable feeling) | Legal (Cool) | Valeu (Thanks/Cheers)',
            'type': 'keyPhrases',
            'imageUrl': '',
          },
        ],
      },
      {
        'country': 'France',
        'title': 'The Art of Living and Loving',
        'imageUrl': '',
        'weekOf':
            Timestamp.fromDate(now.subtract(const Duration(days: 14))),
        'isActive': false,
        'sections': [
          {
            'title': 'French Cuisine',
            'content':
                'French cuisine is a UNESCO-recognized cultural heritage. From croissants and cafe au lait for breakfast to multi-course dinners with wine pairings, food is central to French life. The art of the boulangerie (bakery), patisserie, and fromagerie is celebrated daily. Regional specialties range from Provencal ratatouille to Alsatian choucroute.',
            'type': 'cuisine',
            'imageUrl': '',
          },
          {
            'title': 'French Customs',
            'content':
                'French culture emphasizes the art of living (art de vivre). Greetings involve la bise (cheek kisses), the number varying by region. Conversation is an art form, and intellectual discussion is valued. The French take their lunch breaks seriously, and eating at your desk is frowned upon. Style and presentation matter in every aspect of life.',
            'type': 'customs',
            'imageUrl': '',
          },
          {
            'title': 'Dating a la Francaise',
            'content':
                'There is no formal "dating" in France. Instead, people spend time together and let things develop naturally. The concept of "the talk" about exclusivity does not really exist - if you are seeing each other regularly, you are together. French people value intellectual connection and the art of seduction through conversation.',
            'type': 'datingEtiquette',
            'imageUrl': '',
          },
          {
            'title': 'Essential French Phrases',
            'content':
                'Bonjour (Hello) | Merci beaucoup (Thank you very much) | S\'il vous plait (Please) | Comment allez-vous? (How are you?) | Tu es tres belle/beau (You are very beautiful/handsome) | Je t\'aime (I love you) | Bisou (Kiss) | Mon coeur (My heart) | C\'est magnifique (It\'s magnificent) | A bientot (See you soon)',
            'type': 'keyPhrases',
            'imageUrl': '',
          },
        ],
      },
      {
        'country': 'India',
        'title': 'A Tapestry of Cultures and Traditions',
        'imageUrl': '',
        'weekOf':
            Timestamp.fromDate(now.subtract(const Duration(days: 21))),
        'isActive': false,
        'sections': [
          {
            'title': 'Indian Cuisine',
            'content':
                'Indian cuisine is a universe of flavors. Each state has its own culinary identity, from the rich Mughlai dishes of the north to the coconut-based curries of the south. Spices are used with expert precision, and vegetarian food reaches its peak in India. Street food culture is vibrant - try chaat, dosa, and biryani for an unforgettable experience.',
            'type': 'cuisine',
            'imageUrl': '',
          },
          {
            'title': 'Indian Customs',
            'content':
                'India\'s customs reflect its incredible diversity. The namaste greeting (palms together with a slight bow) is universal. Removing shoes before entering homes and temples is standard. Eating with the right hand is customary in traditional settings. Festivals like Diwali, Holi, and Eid are celebrated with remarkable energy and community spirit.',
            'type': 'customs',
            'imageUrl': '',
          },
          {
            'title': 'Dating in India',
            'content':
                'Indian dating is evolving rapidly, especially in urban areas where apps like Bumble and Hinge are popular. However, family approval remains important across most communities. Arranged marriages are still common but increasingly involve the couple\'s input. When dating, respect for cultural boundaries and patience are essential.',
            'type': 'datingEtiquette',
            'imageUrl': '',
          },
          {
            'title': 'Essential Hindi Phrases',
            'content':
                'Namaste (Hello / Greetings) | Dhanyavaad (Thank you) | Kripya (Please) | Aap kaise hain? (How are you?) | Bahut sundar (Very beautiful) | Main tumse pyar karta/karti hoon (I love you - male/female speaker) | Accha (Good/OK) | Shukriya (Thanks) | Chalo (Let\'s go) | Phir milenge (We\'ll meet again)',
            'type': 'keyPhrases',
            'imageUrl': '',
          },
        ],
      },
      {
        'country': 'South Korea',
        'title': 'Where Tradition Meets Pop Culture',
        'imageUrl': '',
        'weekOf':
            Timestamp.fromDate(now.subtract(const Duration(days: 28))),
        'isActive': false,
        'sections': [
          {
            'title': 'Korean Cuisine',
            'content':
                'Korean food is bold, fermented, and communal. Kimchi accompanies every meal, and Korean BBQ is a social experience where diners cook at the table. Bibimbap, tteokbokki, and samgyeopsal are must-tries. Korean drinking culture includes soju and beer, with games and shared dishes. Convenience store food culture is also uniquely Korean.',
            'type': 'cuisine',
            'imageUrl': '',
          },
          {
            'title': 'Korean Customs',
            'content':
                'Korean society values respect for elders (using both hands to give/receive, pouring drinks for elders) and group harmony. Bowing is the standard greeting. Age hierarchies influence social dynamics - asking someone\'s age is normal and helps determine the appropriate level of formality. Removing shoes indoors is standard.',
            'type': 'customs',
            'imageUrl': '',
          },
          {
            'title': 'Korean Dating Culture',
            'content':
                'Korean dating is characterized by "couple culture." Matching outfits, couple rings, and celebrating every 100 days are standard. Confessing feelings (gobaek) officially starts a relationship. Skinship (physical affection) progresses gradually. Dating apps and meeting through mutual friends (sogaeting) are popular ways to meet.',
            'type': 'datingEtiquette',
            'imageUrl': '',
          },
          {
            'title': 'Essential Korean Phrases',
            'content':
                'Annyeonghaseyo (Hello) | Gamsahamnida (Thank you) | Juseyo (Please give me) | Jal jinaeseyo? (How are you?) | Neomu yeppeo/meositda (So pretty/handsome) | Saranghae (I love you) | Oppa/Unni (Older brother/sister - also used for partners) | Daebak (Awesome) | Geonbae (Cheers) | Bogoshipeo (I miss you)',
            'type': 'keyPhrases',
            'imageUrl': '',
          },
        ],
      },
    ];

    for (final spotlight in spotlights) {
      final ref = collection.doc();
      batch.set(ref, spotlight);
    }

    await batch.commit();
  }

  // ==================== Cultural Tips ====================

  static Future<void> _seedCulturalTips(FirebaseFirestore firestore) async {
    final collection = firestore.collection('cultural_tips');
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already seeded

    final batch = firestore.batch();

    final tips = [
      {
        'userId': 'seed_user_1',
        'userDisplayName': 'TravelLover',
        'country': 'Japan',
        'title': 'Chopstick Etiquette That Saved Me',
        'content':
            'Never stick your chopsticks vertically in a bowl of rice - it resembles incense sticks at funerals and is considered very disrespectful. Also, never pass food from chopstick to chopstick, as this mimics a funeral ritual.',
        'category': 'customs',
        'likes': 42,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'userId': 'seed_user_2',
        'userDisplayName': 'FoodieExplorer',
        'country': 'Thailand',
        'title': 'Street Food Safety Tips',
        'content':
            'Always look for stalls with high turnover - fresh food means safer food. The best street food vendors usually have long queues of locals. In Bangkok, Yaowarat (Chinatown) has some of the best street food in the world.',
        'category': 'food',
        'likes': 35,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      },
      {
        'userId': 'seed_user_3',
        'userDisplayName': 'CultureBuff',
        'country': 'South Korea',
        'title': 'The 100-Day Anniversary is Real',
        'content':
            'In Korea, couples celebrate every 100 days together, not just yearly anniversaries. Missing the 100-day mark can be a big deal! Set a reminder and plan something special - even a simple couple ring exchange means a lot.',
        'category': 'dating',
        'likes': 67,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'userId': 'seed_user_4',
        'userDisplayName': 'GlobeTrotter',
        'country': 'Italy',
        'title': 'Coffee Culture Rules',
        'content':
            'In Italy, cappuccino is only for breakfast. Ordering one after lunch or dinner is a tourist giveaway. After meals, order an espresso instead. Also, standing at the bar is cheaper than sitting at a table in most Italian cafes.',
        'category': 'food',
        'likes': 51,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
      },
      {
        'userId': 'seed_user_5',
        'userDisplayName': 'SafetyFirst',
        'country': 'Colombia',
        'title': 'Safe Transportation in Bogota',
        'content':
            'Always use official taxi apps or ride-sharing services in Bogota. Never hail a cab on the street at night. The TransMilenio bus system is efficient but can be crowded during rush hours. Uber and Beat are widely used and reliable.',
        'category': 'transportation',
        'likes': 28,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      },
      {
        'userId': 'seed_user_6',
        'userDisplayName': 'LinguistAbroad',
        'country': 'France',
        'title': 'Always Say Bonjour First',
        'content':
            'In France, always greet with "Bonjour" before asking anything - in shops, restaurants, or even asking for directions. Not saying bonjour first is considered rude and will affect how people treat you. It is the golden rule of French social interaction.',
        'category': 'language',
        'likes': 73,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6))),
      },
      {
        'userId': 'seed_user_7',
        'userDisplayName': 'DateNightPro',
        'country': 'Brazil',
        'title': 'Brazilian Greetings Are Physical',
        'content':
            'Be prepared for cheek kisses when meeting people in Brazil. In Sao Paulo it is one kiss, in Rio it is two, and in some regions it is three! This applies even in professional settings. When in doubt, follow the local\'s lead.',
        'category': 'customs',
        'likes': 39,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
      },
      {
        'userId': 'seed_user_8',
        'userDisplayName': 'WanderlustSoul',
        'country': 'India',
        'title': 'Left Hand Etiquette',
        'content':
            'In India, the left hand is considered unclean. Always use your right hand to eat, hand things to people, and especially to receive food. This is especially important in traditional settings and when eating street food.',
        'category': 'customs',
        'likes': 45,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8))),
      },
    ];

    for (final tip in tips) {
      final ref = collection.doc();
      batch.set(ref, tip);
    }

    await batch.commit();
  }
}
