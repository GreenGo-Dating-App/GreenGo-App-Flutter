import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/safety_lesson.dart';
import '../../domain/entities/safety_module.dart';
import '../../domain/entities/safety_quiz.dart';
import '../models/safety_lesson_model.dart';
import '../models/safety_module_model.dart';

/// Static seed data for the Safety Academy.
///
/// Contains complete content for all 5 modules (15 lessons total),
/// each with structured content sections and end-of-lesson quizzes.
///
/// Call [seedIfNeeded] to write this data to Firestore if it has not
/// been seeded yet.
///
/// The English text here is the source/fallback only: the UI displays the
/// translations from the ARB files, looked up by module/lesson id and
/// section/question/option index in
/// `presentation/l10n/safety_academy_content_l10n.dart`. Never change ids
/// (stored progress references them); when changing text or the order of
/// sections/questions/options, update the ARB keys and that lookup too.
class SafetyAcademySeedData {
  SafetyAcademySeedData._();

  // ===========================================================================
  // Module Definitions
  // ===========================================================================

  static const List<SafetyModule> modules = [
    SafetyModule(
      id: 'module_online_safety',
      title: 'Online Safety 101', // i18n-ignore: localized by id
      description:
          'Learn to protect your identity and spot potential scams while meeting people online.', // i18n-ignore: localized by id
      iconName: 'shield',
      lessons: [
        'lesson_profile_protection',
        'lesson_scam_recognition',
        'lesson_red_flags',
      ],
      order: 1,
      xpReward: 150,
    ),
    SafetyModule(
      id: 'module_first_meeting',
      title: 'First Meeting Guide', // i18n-ignore: localized by id
      description:
          'Essential tips for safe, confident first meetings with people you meet online.', // i18n-ignore: localized by id
      iconName: 'location_on',
      lessons: [
        'lesson_public_places',
        'lesson_sharing_plans',
        'lesson_transport_safety',
      ],
      order: 2,
      xpReward: 150,
    ),
    SafetyModule(
      id: 'module_communication',
      title: 'Communication Skills', // i18n-ignore: localized by id
      description:
          'Build healthy communication habits including consent, boundaries, and active listening.', // i18n-ignore: localized by id
      iconName: 'chat_bubble',
      lessons: [
        'lesson_active_listening',
        'lesson_boundaries',
        'lesson_consent',
      ],
      order: 3,
      xpReward: 150,
    ),
    SafetyModule(
      id: 'module_cultural_sensitivity',
      title: 'Cultural Sensitivity', // i18n-ignore: localized by id
      description:
          'Navigate cross-cultural friendships with respect, curiosity, and awareness.', // i18n-ignore: localized by id
      iconName: 'public',
      lessons: [
        'lesson_cultural_dos',
        'lesson_cultural_donts',
        'lesson_cultural_communication',
      ],
      order: 4,
      xpReward: 150,
    ),
    SafetyModule(
      id: 'module_emotional_intelligence',
      title: 'Emotional Intelligence', // i18n-ignore: localized by id
      description:
          'Understand attachment styles, appreciation languages, and build emotional awareness.', // i18n-ignore: localized by id
      iconName: 'psychology',
      lessons: [
        'lesson_attachment_styles',
        'lesson_love_languages',
        'lesson_emotional_awareness',
      ],
      order: 5,
      xpReward: 150,
    ),
  ];

  // ===========================================================================
  // Module 1: Online Safety 101
  // ===========================================================================

  static const _lessonsOnlineSafety = [
    SafetyLesson(
      id: 'lesson_profile_protection',
      moduleId: 'module_online_safety',
      title: 'Profile Protection', // i18n-ignore: localized by id
      order: 1,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Your profile is your first impression, but it can also expose personal information if you are not careful. Learning to share the right amount keeps you safe while still showing your personality.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Use a unique photo that is not on your other social media profiles. Reverse image searches can link accounts together.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Never include your full name, workplace, home address, or phone number in your bio.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Profile Safety Checklist', // i18n-ignore: localized by id
          items: [
            'Remove or crop out identifiable landmarks near your home',
            'Use a first name or nickname only',
            'Disable location metadata on uploaded photos',
            'Avoid photos in work uniforms or with visible ID badges',
            'Review your profile from a stranger\'s perspective',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'A well-crafted profile balances openness with privacy. Share your interests and values, but save specifics like your daily routine or home neighborhood for later conversations.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_profile_protection',
        lessonId: 'lesson_profile_protection',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'Which of the following is safe to include in your profile?', // i18n-ignore: localized by id
            options: [
              'Your home address',
              'Your favorite hobbies',
              'Your workplace name and department',
              'Your phone number',
            ],
            correctIndex: 1,
            explanation:
                'Sharing hobbies is great for conversation starters without revealing personal details that could be used to locate you.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'Why should you use unique photos on your profile?', // i18n-ignore: localized by id
            options: [
              'To get more profile views',
              'Because social apps compress images',
              'To prevent reverse image searches linking to your other accounts',
              'Unique photos get more likes',
            ],
            correctIndex: 2,
            explanation:
                'Reverse image search tools can link your profile to social media, blogs, or professional pages, revealing your full identity.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'What should you check before uploading a photo?', // i18n-ignore: localized by id
            options: [
              'That it has a nice filter',
              'That location metadata is removed and no identifiable landmarks are visible',
              'That it was taken recently',
              'That it is a selfie',
            ],
            correctIndex: 1,
            explanation:
                'Photo metadata (EXIF data) can contain GPS coordinates. Landmarks like street signs or building names can also reveal your location.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_scam_recognition',
      moduleId: 'module_online_safety',
      title: 'Scam Recognition', // i18n-ignore: localized by id
      order: 2,
      xpReward: 30,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Impersonation and money scams cost victims billions worldwide each year. Scammers build emotional connections quickly and then exploit them for money or personal data. Knowing the signs can protect you.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'If someone asks for money, gift cards, cryptocurrency, or financial help soon after you meet online -- no matter how compelling the story -- it is almost certainly a scam.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Do a video call early on. Scammers avoid live video because it exposes fake identities. If someone repeatedly avoids video, be cautious.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Common Scam Red Flags', // i18n-ignore: localized by id
          items: [
            'Profile seems too perfect (model-quality photos, dream career)',
            'Claims to be overseas military, oil rig worker, or international business person',
            'Shows intense attachment or flattery unusually fast',
            'Avoids video calls or meeting in person',
            'Requests money for emergencies, travel, or medical bills',
            'Asks you to move conversation to another platform quickly',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'If you suspect a scam, stop communication immediately. Report the profile to the app and consider filing a report with your local authorities.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_scam_recognition',
        lessonId: 'lesson_scam_recognition',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'Someone you connected with a week ago says you mean everything to them and asks for money to visit you. What should you do?', // i18n-ignore: localized by id
            options: [
              'Send the money -- they seem genuine',
              'Ask for more details about why they need money',
              'Recognize this as a classic money-scam pattern and report them',
              'Offer to buy their plane ticket directly',
            ],
            correctIndex: 2,
            explanation:
                'Building intense emotional attachment very quickly and then requesting money is the hallmark pattern of money scams. Report and block.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'Which profession is commonly used as a cover story by scammers?', // i18n-ignore: localized by id
            options: [
              'Local teacher',
              'Overseas military deployment',
              'Neighborhood barista',
              'Nearby office worker',
            ],
            correctIndex: 1,
            explanation:
                'Scammers often claim military deployment, offshore work, or international business to explain why they cannot meet in person or video call.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'What is a good early step to verify someone is real?', // i18n-ignore: localized by id
            options: [
              'Ask for their home address',
              'Request a video call',
              'Send them money to test their response',
              'Search for them on all social media platforms',
            ],
            correctIndex: 1,
            explanation:
                'A video call is one of the simplest ways to verify someone is who they claim to be. Scammers typically avoid live video at all costs.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_red_flags',
      moduleId: 'module_online_safety',
      title: 'Behavioral Red Flags', // i18n-ignore: localized by id
      order: 3,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Beyond scams, there are behavioral patterns that can indicate controlling, manipulative, or potentially dangerous individuals. Learning to spot these early can save you from harmful situations.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Someone who pressures you to share intimate photos, meet immediately, or isolate from friends is displaying controlling behavior.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Behavioral Red Flags', // i18n-ignore: localized by id
          items: [
            'Excessive jealousy or possessiveness before even meeting',
            'Pressuring for personal information or intimate content',
            'Getting angry when you don\'t respond immediately',
            'Disrespecting your stated boundaries',
            'Making you feel guilty for spending time with others',
            'Inconsistent stories about themselves',
          ],
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Trust your gut. If a conversation makes you uncomfortable, you do not owe anyone an explanation. It is always okay to stop responding, block, or report.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'Healthy connections are built on mutual respect. Someone who truly cares about you will respect your pace, your boundaries, and your autonomy.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_red_flags',
        lessonId: 'lesson_red_flags',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'A new connection gets upset when you take an hour to reply. What does this indicate?', // i18n-ignore: localized by id
            options: [
              'They really like you',
              'They are enthusiastic about the conversation',
              'Potentially controlling behavior',
              'They are just anxious',
            ],
            correctIndex: 2,
            explanation:
                'Getting angry about response times before you have even met is a sign of controlling behavior. Everyone is entitled to their own schedule.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'What is the best response when someone pressures you for intimate photos?', // i18n-ignore: localized by id
            options: [
              'Send them to keep the peace',
              'Firmly decline, and if they persist, block and report them',
              'Ask them to send theirs first',
              'Promise to send them later',
            ],
            correctIndex: 1,
            explanation:
                'You should never feel pressured to share intimate content. A respectful person will accept your decision without pushing.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'Which is a healthy sign in early conversations?', // i18n-ignore: localized by id
            options: [
              'They want to know your exact daily schedule',
              'They respect your pace and boundaries',
              'They declare intense feelings for you within the first few days',
              'They ask you to stop talking to other people on the app',
            ],
            correctIndex: 1,
            explanation:
                'Respect for pace and boundaries is the foundation of a healthy connection. Everything else in this list is a potential red flag.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
  ];

  // ===========================================================================
  // Module 2: First Meeting Guide
  // ===========================================================================

  static const _lessonsFirstMeeting = [
    SafetyLesson(
      id: 'lesson_public_places',
      moduleId: 'module_first_meeting',
      title: 'Meeting in Public Places', // i18n-ignore: localized by id
      order: 1,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Meeting someone from an app for the first time is exciting, but safety should always come first. Choosing the right location sets the foundation for a comfortable experience.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Choose a busy cafe, restaurant, or public park for your first meeting. Familiarity with the venue gives you an advantage -- you know the exits and the staff.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Never agree to meet at someone\'s home, a secluded area, or a place you are unfamiliar with for a first meeting.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'First Meeting Location Checklist', // i18n-ignore: localized by id
          items: [
            'Choose a public, well-lit location',
            'Pick somewhere you are familiar with',
            'Ensure the venue has other people around',
            'Check that you have phone signal at the venue',
            'Have a backup plan if you need to leave quickly',
          ],
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_public_places',
        lessonId: 'lesson_public_places',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'Which is the safest first meeting location?', // i18n-ignore: localized by id
            options: [
              'Their apartment',
              'A busy downtown cafe',
              'A remote hiking trail',
              'Your home',
            ],
            correctIndex: 1,
            explanation:
                'A busy cafe is public, has staff around, and you can leave easily if needed.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'Why should you pick a venue you are familiar with?', // i18n-ignore: localized by id
            options: [
              'So you can impress the other person with recommendations',
              'Because you know the exits, staff, and surroundings',
              'It is cheaper if you know the menu',
              'There is no real advantage',
            ],
            correctIndex: 1,
            explanation:
                'Knowing the venue means you know how to leave quickly and who to ask for help if you feel uncomfortable.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_sharing_plans',
      moduleId: 'module_first_meeting',
      title: 'Sharing Your Plans', // i18n-ignore: localized by id
      order: 2,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Letting someone you trust know about your plans to meet someone new is one of the simplest and most effective safety measures. A safety buddy can check in on you and knows where to look if something goes wrong.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Share the other person\'s profile, the venue, and your expected return time with a trusted friend. Set up a check-in call 30 minutes into the meeting.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Information to Share with Your Safety Buddy', // i18n-ignore: localized by id
          items: [
            'Screenshot of the other person\'s profile',
            'Name (or username) of the person you are meeting',
            'Day, time, and venue of the meeting',
            'Your expected return time',
            'Agreed check-in time (e.g., a call or text)',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'You can also send the meeting details to a trusted contact before you go. There is no shame in being safe -- the person you are meeting should understand.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_sharing_plans',
        lessonId: 'lesson_sharing_plans',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'What should you share with a trusted friend before a first meeting?', // i18n-ignore: localized by id
            options: [
              'Only the venue name',
              'The other person\'s profile, venue, time, and expected return',
              'Nothing -- it is private',
              'Just a text saying "going out"',
            ],
            correctIndex: 1,
            explanation:
                'The more information your safety buddy has, the better they can help if something goes wrong.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'When is a good time to set up a check-in call?', // i18n-ignore: localized by id
            options: [
              'After the meeting is over',
              'About 30 minutes into the meeting',
              'A check-in is not necessary',
              'Before you leave for the meeting',
            ],
            correctIndex: 1,
            explanation:
                'A check-in 30 minutes in gives you enough time to assess the situation and an easy out if you feel uncomfortable.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_transport_safety',
      moduleId: 'module_first_meeting',
      title: 'Transport Safety', // i18n-ignore: localized by id
      order: 3,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'How you get to and from a meetup matters just as much as where you meet. Maintaining control over your transportation ensures you can leave whenever you want.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Never let someone you just met online pick you up from your home for the first meeting. This reveals your address and makes you dependent on them for a ride home.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Drive yourself, use ride-sharing, or take public transport. Keep your phone charged and have enough money for an emergency ride home.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Transport Safety Checklist', // i18n-ignore: localized by id
          items: [
            'Arrange your own transportation',
            'Keep your phone fully charged',
            'Have emergency ride money available',
            'Share your live location with a trusted contact',
            'Park in a well-lit area if driving',
            'Do not leave drinks unattended if you step away',
          ],
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_transport_safety',
        lessonId: 'lesson_transport_safety',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'Why should you arrange your own transportation for a first meeting?', // i18n-ignore: localized by id
            options: [
              'To save money on gas',
              'So you can leave whenever you want and your address stays private',
              'To avoid traffic',
              'Because parking is easier alone',
            ],
            correctIndex: 1,
            explanation:
                'Having your own transport means you are not dependent on the other person and your home address remains private.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'Someone you are about to meet for the first time offers to pick you up from home. What should you do?', // i18n-ignore: localized by id
            options: [
              'Accept -- it is a nice gesture',
              'Politely decline and suggest meeting at the venue instead',
              'Give them a nearby intersection instead of your exact address',
              'Accept but have a friend watch from the window',
            ],
            correctIndex: 1,
            explanation:
                'Meeting at the venue keeps your address private and ensures you have independent transportation.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
  ];

  // ===========================================================================
  // Module 3: Communication Skills
  // ===========================================================================

  static const _lessonsCommunication = [
    SafetyLesson(
      id: 'lesson_active_listening',
      moduleId: 'module_communication',
      title: 'Active Listening', // i18n-ignore: localized by id
      order: 1,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Active listening is the foundation of meaningful connection. It goes beyond hearing words -- it is about fully engaging with your conversation partner and making them feel valued.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Ask follow-up questions based on what they said, not just what you want to talk about. This shows genuine interest.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Active Listening Techniques', // i18n-ignore: localized by id
          items: [
            'Give your full attention (put your phone away)',
            'Use verbal cues ("I see", "That\'s interesting")',
            'Reflect back what you heard ("So you\'re saying...")',
            'Ask open-ended follow-up questions',
            'Avoid interrupting or planning your response while they talk',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'In text conversations, active listening means reading messages carefully, responding to what was actually said, and asking thoughtful questions rather than redirecting every topic to yourself.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_active_listening',
        lessonId: 'lesson_active_listening',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'The person you are meeting shares a story about their recent trip. What is the best active listening response?', // i18n-ignore: localized by id
            options: [
              '"Cool. So anyway, I went to..."',
              '"That sounds amazing! What was the highlight of the trip?"',
              '"I have been there too, let me tell you about it."',
              '"Nice."',
            ],
            correctIndex: 1,
            explanation:
                'Asking a follow-up question about their experience shows genuine interest and keeps the conversation flowing.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'What should you avoid during active listening?', // i18n-ignore: localized by id
            options: [
              'Making eye contact',
              'Planning your response while the other person is still talking',
              'Nodding occasionally',
              'Asking follow-up questions',
            ],
            correctIndex: 1,
            explanation:
                'If you are planning your next response, you are not truly listening. Focus on understanding first, then respond.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_boundaries',
      moduleId: 'module_communication',
      title: 'Setting Boundaries', // i18n-ignore: localized by id
      order: 2,
      xpReward: 30,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Boundaries are the guidelines you set for how you want to be treated. They are essential for healthy relationships and protect your emotional, physical, and mental well-being.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'State boundaries clearly and early. For example: "I prefer to get to know someone through chat before meeting in person" or "I am not comfortable sharing photos right now."', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'If someone repeatedly pushes against a boundary you have set, this is a serious red flag regardless of their excuses.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Healthy Boundary Examples', // i18n-ignore: localized by id
          items: [
            'Deciding when you are ready to share your phone number',
            'Setting limits on how late someone can message you',
            'Being clear about your personal space and comfort levels when meeting up',
            'Saying no to plans that feel rushed or uncomfortable',
            'Taking breaks from conversation when you need space',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'Remember: setting boundaries is not being difficult. It is self-respect. A person who values you will appreciate and honor your boundaries.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_boundaries',
        lessonId: 'lesson_boundaries',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'You tell a new connection you are not comfortable sharing your number yet, and they keep asking. What does this indicate?', // i18n-ignore: localized by id
            options: [
              'They are really interested in you',
              'They are just eager to move the conversation',
              'They are not respecting your stated boundary',
              'It is normal behavior when getting to know someone',
            ],
            correctIndex: 2,
            explanation:
                'Repeatedly pushing against a clearly stated boundary is disrespectful and a red flag, regardless of the reason given.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'When is the best time to communicate a boundary?', // i18n-ignore: localized by id
            options: [
              'After it has been crossed multiple times',
              'Clearly and early, before it becomes an issue',
              'Only if the other person asks',
              'Boundaries are not necessary when meeting new people',
            ],
            correctIndex: 1,
            explanation:
                'Stating boundaries early and clearly prevents misunderstandings and sets the tone for mutual respect.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_consent',
      moduleId: 'module_communication',
      title: 'Understanding Consent', // i18n-ignore: localized by id
      order: 3,
      xpReward: 30,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Consent is a clear, enthusiastic, and ongoing agreement. It applies to every interaction -- from sharing personal information to physical contact.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Consent is not just about physical contact. Sharing someone\'s photos, forwarding their messages, or sharing their personal details without permission also violates consent.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Key Principles of Consent', // i18n-ignore: localized by id
          items: [
            'Freely given -- not pressured, coerced, or manipulated',
            'Reversible -- anyone can change their mind at any time',
            'Informed -- based on honest, complete information',
            'Enthusiastic -- look for active "yes", not just absence of "no"',
            'Specific -- consent to one thing does not mean consent to everything',
          ],
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Silence or a lack of "no" does not equal consent. Always look for clear, positive agreement.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'Asking for consent is not awkward -- it shows maturity and respect. Simple check-ins like "Are you comfortable with this?" or "Would you like to...?" make a big difference.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_consent',
        lessonId: 'lesson_consent',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question: 'Which statement best describes consent?', // i18n-ignore: localized by id
            options: [
              'The absence of "no"',
              'A clear, enthusiastic, and ongoing agreement',
              'Something only needed for physical contact',
              'Agreement given once that covers all future interactions',
            ],
            correctIndex: 1,
            explanation:
                'Consent must be clear, enthusiastic, ongoing, and can be revoked at any time. It applies to all interactions.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'Someone you met on the app agreed to join you at an event but seems uncomfortable after arriving. What should you do?', // i18n-ignore: localized by id
            options: [
              'They agreed already, so continue as planned',
              'Check in with them and offer to go somewhere else',
              'Ignore the discomfort -- it is probably nerves',
              'Tell them they should not have agreed if they did not want to come',
            ],
            correctIndex: 1,
            explanation:
                'Consent is reversible. If someone seems uncomfortable, check in with them. Their well-being is more important than plans.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
  ];

  // ===========================================================================
  // Module 4: Cultural Sensitivity
  // ===========================================================================

  static const _lessonsCultural = [
    SafetyLesson(
      id: 'lesson_cultural_dos',
      moduleId: 'module_cultural_sensitivity',
      title: 'Cross-Cultural Do\'s', // i18n-ignore: localized by id
      order: 1,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Getting to know someone from a different cultural background can be one of the most enriching experiences. Approach it with genuine curiosity, respect, and a willingness to learn.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Ask open-ended questions about their culture with genuine curiosity, not as a quiz. "What traditions are important to your family?" is much better than "Do your people really do X?"', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Do\'s for Cross-Cultural Connections', // i18n-ignore: localized by id
          items: [
            'Research basic cultural customs before meeting up',
            'Show genuine interest in their background and traditions',
            'Be open to trying new foods, activities, and experiences',
            'Respect family dynamics that may differ from yours',
            'Learn a few words or phrases in their language',
            'Ask how they prefer to be addressed or introduced',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'Remember that every person is an individual first. Cultural awareness is a starting point, but get to know the person beyond stereotypes.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_cultural_dos',
        lessonId: 'lesson_cultural_dos',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'What is the best way to learn about a new friend\'s culture?', // i18n-ignore: localized by id
            options: [
              'Make assumptions based on what you have seen in movies',
              'Ask thoughtful, open-ended questions with genuine curiosity',
              'Quiz them on cultural facts you read online',
              'Avoid the topic entirely to prevent offense',
            ],
            correctIndex: 1,
            explanation:
                'Genuine, respectful curiosity is the best approach. Let them share what is meaningful to them.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'A new friend mentions a family tradition you do not understand. What should you do?', // i18n-ignore: localized by id
            options: [
              'Nod along and pretend you understand',
              'Ask them to explain more about it and why it matters',
              'Tell them your traditions are different',
              'Change the subject',
            ],
            correctIndex: 1,
            explanation:
                'Asking them to share more shows respect and genuine interest in their world.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_cultural_donts',
      moduleId: 'module_cultural_sensitivity',
      title: 'Cross-Cultural Don\'ts', // i18n-ignore: localized by id
      order: 2,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Well-intentioned but uninformed comments can feel hurtful or dismissive. Understanding common pitfalls helps you navigate cross-cultural friendships with grace.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Never reduce someone to their ethnicity or nationality. Comments like "I\'ve always wanted a friend from [country]" or "You speak well for a [nationality]" are hurtful, not complimentary.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Don\'ts for Cross-Cultural Connections', // i18n-ignore: localized by id
          items: [
            'Do not fetishize or exoticize their culture or appearance',
            'Do not assume they represent their entire culture',
            'Do not make jokes about their accent or language',
            'Do not pressure them to explain or defend cultural practices',
            'Do not compare them to stereotypes or media portrayals',
            'Do not dismiss cultural differences as unimportant',
          ],
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'If you make a cultural misstep, apologize sincerely, learn from it, and move on. Do not over-apologize to the point of making it about your feelings.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_cultural_donts',
        lessonId: 'lesson_cultural_donts',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'Which comment is culturally insensitive?', // i18n-ignore: localized by id
            options: [
              '"I\'d really like to try the food from your country."',
              '"You are so exotic looking."',
              '"What language do you speak at home?"',
              '"Tell me about a holiday your family celebrates."',
            ],
            correctIndex: 1,
            explanation:
                'Calling someone "exotic" reduces them to their appearance and cultural background. It is objectifying, not complimentary.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'You accidentally say something culturally insensitive. What is the best response?', // i18n-ignore: localized by id
            options: [
              'Pretend it did not happen',
              'Apologize sincerely, learn from it, and move on',
              'Explain that you did not mean it that way',
              'Over-apologize and keep bringing it up',
            ],
            correctIndex: 1,
            explanation:
                'A sincere, brief apology followed by genuine effort to do better is the most mature response.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_cultural_communication',
      moduleId: 'module_cultural_sensitivity',
      title: 'Communication Across Cultures', // i18n-ignore: localized by id
      order: 3,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Communication styles vary significantly across cultures. What feels direct and honest in one culture may come across as rude in another. Understanding these differences prevents misunderstandings.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'If something the other person says or does confuses you, assume positive intent and ask for clarification rather than jumping to conclusions.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Cultural Communication Differences to Be Aware Of', // i18n-ignore: localized by id
          items: [
            'Direct vs. indirect communication styles',
            'Personal space and physical touch norms',
            'Eye contact expectations (some cultures find direct eye contact disrespectful)',
            'Attitudes toward punctuality and time',
            'Gift-giving customs and expectations',
            'The role of humor and what topics are off-limits',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'When in doubt, communicate openly. A simple "I want to make sure I understand you correctly" goes a long way in bridging cultural gaps.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_cultural_communication',
        lessonId: 'lesson_cultural_communication',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'The person you are talking to avoids direct eye contact. What should you think?', // i18n-ignore: localized by id
            options: [
              'They are not interested in you',
              'They are being dishonest',
              'It may be a cultural norm -- do not assume negative intent',
              'They are shy and need more encouragement',
            ],
            correctIndex: 2,
            explanation:
                'In many cultures, avoiding direct eye contact is a sign of respect, not disinterest or dishonesty.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'What is the best approach when cultural communication differences cause confusion?', // i18n-ignore: localized by id
            options: [
              'Assume the worst',
              'Ignore it and hope it resolves',
              'Ask for clarification with an open mind',
              'Tell them to communicate more like you do',
            ],
            correctIndex: 2,
            explanation:
                'Open, non-judgmental communication is the best way to navigate cultural differences.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
  ];

  // ===========================================================================
  // Module 5: Emotional Intelligence
  // ===========================================================================

  static const _lessonsEmotional = [
    SafetyLesson(
      id: 'lesson_attachment_styles',
      moduleId: 'module_emotional_intelligence',
      title: 'Attachment Styles', // i18n-ignore: localized by id
      order: 1,
      xpReward: 30,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Attachment theory explains how our early relationships shape the way we connect with other people as adults. Understanding your attachment style can help you build healthier friendships.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'The four main attachment styles are: Secure, Anxious, Avoidant, and Disorganized. Most people are a mix, and styles can change with awareness and effort.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'The Four Attachment Styles', // i18n-ignore: localized by id
          items: [
            'Secure: Comfortable with closeness, trusting, communicative',
            'Anxious: Craves closeness but fears rejection, may need extra reassurance',
            'Avoidant: Values independence highly, may pull away when things get close',
            'Disorganized: Mix of anxious and avoidant, often from difficult early experiences',
          ],
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'Knowing your style helps you understand your reactions. If you tend toward anxious attachment, you might recognize that your urge to text repeatedly comes from fear, not genuine need. If avoidant, you might notice your tendency to shut down when emotions run high.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Understanding a friend\'s attachment style helps you respond with empathy rather than frustration. An avoidant friend pulling away is not rejection -- it is their coping mechanism.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_attachment_styles',
        lessonId: 'lesson_attachment_styles',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'A friend needs a lot of reassurance and gets anxious when you do not respond quickly. Which attachment style might this reflect?', // i18n-ignore: localized by id
            options: [
              'Secure',
              'Anxious',
              'Avoidant',
              'Disorganized',
            ],
            correctIndex: 1,
            explanation:
                'Anxious attachment is characterized by a strong desire for closeness and fear of rejection, often leading to a need for frequent reassurance.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'What is the healthiest response to recognizing your attachment patterns?', // i18n-ignore: localized by id
            options: [
              'Accept that they cannot change',
              'Blame your parents for your style',
              'Use awareness to communicate better and work toward secure attachment',
              'Only spend time with people who have the same style',
            ],
            correctIndex: 2,
            explanation:
                'Attachment styles can evolve with self-awareness, communication, and sometimes professional support.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'Someone with an avoidant attachment style might:', // i18n-ignore: localized by id
            options: [
              'Send multiple texts if you do not reply quickly',
              'Pull away or shut down when a friendship gets emotionally close',
              'Always want to spend every moment together',
              'Be very open about their feelings from the start',
            ],
            correctIndex: 1,
            explanation:
                'Avoidant attachment often manifests as pulling away when emotional closeness increases, as a self-protection mechanism.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_love_languages',
      moduleId: 'module_emotional_intelligence',
      title: 'Appreciation Languages', // i18n-ignore: localized by id
      order: 2,
      xpReward: 25,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'The concept of appreciation languages, adapted from Dr. Gary Chapman\'s work, suggests that people express and receive appreciation in five primary ways. Understanding yours and your friends\' can strengthen your connections.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'The Five Appreciation Languages', // i18n-ignore: localized by id
          items: [
            'Words of Affirmation: Verbal compliments, encouragement, and expressions of appreciation',
            'Quality Time: Undivided attention and presence',
            'Receiving Gifts: Thoughtful tokens of appreciation (not about cost)',
            'Acts of Service: Actions that make life easier or show care',
            'Friendly Gestures: A handshake, high five, or hug when it is welcome',
          ],
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Pay attention to how someone shows appreciation -- that is likely their appreciation language. If they always compliment you, they probably value words of affirmation.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'Different appreciation languages are common and manageable. The key is communication: tell your friends what makes you feel appreciated, and ask them the same question.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_love_languages',
        lessonId: 'lesson_love_languages',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'A friend always makes time for you and puts their phone away during conversations. Their appreciation language is likely:', // i18n-ignore: localized by id
            options: [
              'Words of Affirmation',
              'Quality Time',
              'Receiving Gifts',
              'Friendly Gestures',
            ],
            correctIndex: 1,
            explanation:
                'Giving undivided attention and prioritizing presence is the hallmark of Quality Time as an appreciation language.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'You value words of affirmation but a friend shows appreciation through acts of service. What should you do?', // i18n-ignore: localized by id
            options: [
              'Accept that you are incompatible',
              'Tell them what you need and learn to recognize how they show appreciation',
              'Change your appreciation language to match theirs',
              'Ignore the difference',
            ],
            correctIndex: 1,
            explanation:
                'Communication is key. Express what you need while also learning to appreciate how your friend shows they care.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
    SafetyLesson(
      id: 'lesson_emotional_awareness',
      moduleId: 'module_emotional_intelligence',
      title: 'Emotional Awareness', // i18n-ignore: localized by id
      order: 3,
      xpReward: 30,
      contentSections: [
        LessonContent(
          type: LessonContentType.text,
          content:
              'Emotional awareness is the ability to recognize, understand, and manage your own emotions while also being attuned to others\'. When meeting new people, this skill prevents reactive decisions and builds deeper connections.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.tip,
          content:
              'Before responding to a frustrating message, pause and identify what you are actually feeling. Are you hurt? Anxious? Disappointed? Naming the emotion reduces its power.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.checklist,
          content: 'Building Emotional Awareness', // i18n-ignore: localized by id
          items: [
            'Practice naming your emotions throughout the day',
            'Notice physical sensations tied to emotions (tight chest = anxiety)',
            'Journal about your social experiences and emotional reactions',
            'Distinguish between reacting (impulsive) and responding (thoughtful)',
            'Develop a pause habit: wait before sending emotional messages',
          ],
        ),
        LessonContent(
          type: LessonContentType.warning,
          content:
              'Emotional awareness does not mean suppressing emotions. It means understanding them well enough to choose how you act on them.', // i18n-ignore: localized by id
        ),
        LessonContent(
          type: LessonContentType.text,
          content:
              'When you can say "I felt hurt when you canceled our plans" instead of "You obviously do not care about me," you transform conflict into connection. That is emotional intelligence in action.', // i18n-ignore: localized by id
        ),
      ],
      quiz: SafetyQuiz(
        id: 'quiz_emotional_awareness',
        lessonId: 'lesson_emotional_awareness',
        passingScore: 80,
        questions: [
          QuizQuestion(
            question:
                'A new friend cancels plans last minute and you feel angry. What is the emotionally aware response?', // i18n-ignore: localized by id
            options: [
              'Send an angry message immediately',
              'Ghost them as punishment',
              'Pause, identify your feelings, then communicate calmly how the cancellation made you feel',
              'Pretend you do not care',
            ],
            correctIndex: 2,
            explanation:
                'Pausing to identify your emotions and then communicating them calmly leads to better outcomes than reacting impulsively.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question: 'What does emotional awareness mean?', // i18n-ignore: localized by id
            options: [
              'Never showing emotions',
              'Always being happy',
              'Recognizing and understanding emotions to choose how to act on them',
              'Expressing every emotion as soon as you feel it',
            ],
            correctIndex: 2,
            explanation:
                'Emotional awareness is about recognition and understanding, which enables thoughtful responses rather than impulsive reactions.', // i18n-ignore: localized by id
          ),
          QuizQuestion(
            question:
                'Which is an example of "responding" versus "reacting"?', // i18n-ignore: localized by id
            options: [
              'Typing an angry reply the moment you feel upset',
              'Waiting, reflecting on your feelings, then crafting a thoughtful message',
              'Ignoring the message entirely',
              'Venting to friends before replying',
            ],
            correctIndex: 1,
            explanation:
                'Responding involves a deliberate pause for reflection, while reacting is driven by immediate emotion.', // i18n-ignore: localized by id
          ),
        ],
      ),
    ),
  ];

  // ===========================================================================
  // All lessons combined
  // ===========================================================================

  static List<SafetyLesson> get allLessons => [
        ..._lessonsOnlineSafety,
        ..._lessonsFirstMeeting,
        ..._lessonsCommunication,
        ..._lessonsCultural,
        ..._lessonsEmotional,
      ];

  // ===========================================================================
  // Seed method
  // ===========================================================================

  /// Seeds safety academy data into Firestore if it has not been done yet.
  ///
  /// Checks for a sentinel document to avoid duplicate seeding.
  /// Writes all modules and lessons in a batched write.
  static Future<void> seedIfNeeded(FirebaseFirestore firestore) async {
    // Check sentinel document
    final sentinel = await firestore
        .collection('app_config')
        .doc('safety_academy_seeded')
        .get();

    if (sentinel.exists) return; // Already seeded

    final batch = firestore.batch();

    // Write modules
    for (final module in modules) {
      final model = SafetyModuleModel.fromEntity(module);
      batch.set(
        firestore.collection('safety_modules').doc(module.id),
        model.toJson(),
      );
    }

    // Write lessons
    for (final lesson in allLessons) {
      final model = SafetyLessonModel.fromEntity(lesson);
      batch.set(
        firestore.collection('safety_lessons').doc(lesson.id),
        model.toJson(),
      );
    }

    // Write sentinel
    batch.set(
      firestore.collection('app_config').doc('safety_academy_seeded'),
      {
        'seededAt': FieldValue.serverTimestamp(),
        'moduleCount': modules.length,
        'lessonCount': allLessons.length,
      },
    );

    await batch.commit();
  }
}
