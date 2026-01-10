"""
GreenGo App - Detailed Architecture Diagram
Complete Feature Module Breakdown with Clean Architecture Layers

Requirements:
pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.programming.framework import Flutter
from diagrams.programming.language import Dart
from diagrams.firebase import Firebase

# Enhanced graph attributes
graph_attr = {
    "fontsize": "12",
    "bgcolor": "white",
    "pad": "0.8",
    "splines": "polyline",
    "concentrate": "false",
    "compound": "true"
}

with Diagram(
    "GreenGo App - Detailed Clean Architecture (17 Features)",
    filename="greengo_detailed_architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    outformat="png"
):

    # ==================== FEATURE MODULES ====================
    with Cluster("FEATURE MODULES (Clean Architecture Per Feature)"):

        # Authentication Feature
        with Cluster("1. Authentication Feature"):
            with Cluster("Presentation"):
                auth_ui = Flutter("Screens:\nLogin, Register,\nForgot Password")
                auth_bloc = Dart("AuthBloc")
            with Cluster("Domain"):
                auth_usecases = Dart("Use Cases:\nSignIn, SignUp,\nSignOut")
                auth_repo = Dart("AuthRepository\n(Interface)")
            with Cluster("Data"):
                auth_impl = Dart("AuthRepoImpl")
                auth_ds = Dart("AuthRemoteDS")

            auth_ui >> auth_bloc >> auth_usecases >> auth_repo
            auth_repo >> Edge(style="dashed") >> auth_impl >> auth_ds

        # Profile Feature
        with Cluster("2. Profile Feature"):
            with Cluster("Presentation"):
                profile_ui = Flutter("Screens:\nProfile, Edit,\nOnboarding")
                profile_bloc = Dart("ProfileBloc")
            with Cluster("Domain"):
                profile_usecases = Dart("Use Cases:\nGetProfile,\nUpdateProfile")
                profile_repo = Dart("ProfileRepository\n(Interface)")
            with Cluster("Data"):
                profile_impl = Dart("ProfileRepoImpl")
                profile_ds = Dart("ProfileRemoteDS")

            profile_ui >> profile_bloc >> profile_usecases >> profile_repo
            profile_repo >> Edge(style="dashed") >> profile_impl >> profile_ds

        # Discovery Feature
        with Cluster("3. Discovery Feature"):
            with Cluster("Presentation"):
                discovery_ui = Flutter("Screens:\nSwipe Cards,\nFilters")
                discovery_bloc = Dart("DiscoveryBloc")
            with Cluster("Domain"):
                discovery_usecases = Dart("Use Cases:\nGetProfiles,\nSwipe")
                discovery_repo = Dart("DiscoveryRepository")
            with Cluster("Data"):
                discovery_impl = Dart("DiscoveryRepoImpl")

            discovery_ui >> discovery_bloc >> discovery_usecases >> discovery_repo
            discovery_repo >> Edge(style="dashed") >> discovery_impl

        # Matching Feature
        with Cluster("4. Matching Feature"):
            with Cluster("Presentation"):
                match_ui = Flutter("Screens:\nMatches List,\nCompatibility")
                match_bloc = Dart("MatchBloc")
            with Cluster("Domain"):
                match_usecases = Dart("Use Cases:\nGetMatches,\nCheckCompatibility")

            match_ui >> match_bloc >> match_usecases

        # Chat Feature
        with Cluster("5. Chat Feature"):
            with Cluster("Presentation"):
                chat_ui = Flutter("Screens:\nChat List,\nConversation")
                chat_bloc = Dart("ChatBloc")
            with Cluster("Domain"):
                chat_usecases = Dart("Use Cases:\nSendMessage,\nGetMessages")
                chat_repo = Dart("ChatRepository")
            with Cluster("Data"):
                chat_impl = Dart("ChatRepoImpl")

            chat_ui >> chat_bloc >> chat_usecases >> chat_repo
            chat_repo >> Edge(style="dashed") >> chat_impl

        # Additional Features
        with Cluster("6-17. Other Features"):
            other_features = Dart("""
            6. Notifications (Push, Preferences)
            7. Coins (Virtual Currency)
            8. Gamification (Achievements)
            9. Subscription (Premium Plans)
            10. Video Calling
            11. Analytics
            12. Accessibility
            13. Safety & Reporting
            14. Localization
            15. Admin Panel
            16. Main Navigation
            17. Settings
            """)

    # ==================== CORE INFRASTRUCTURE ====================
    with Cluster("CORE INFRASTRUCTURE"):

        # Dependency Injection
        with Cluster("Dependency Injection (GetIt)"):
            di_factory = Dart("Factory\n(BLoCs)")
            di_singleton = Dart("Lazy Singleton\n(Repos, UseCases,\nDataSources)")
            di_external = Dart("External\n(Firebase, APIs)")

        # Error Handling
        with Cluster("Error Handling"):
            error_flow = Dart("""
            Data Layer: Exceptions
            ↓ (Repository converts)
            Domain Layer: Failures
            ↓ (Either<Failure, T>)
            Presentation: Error States
            """)

        # State Management
        with Cluster("State Management"):
            bloc_pattern = Dart("""
            BLoC Pattern (Primary):
            UI → Event → BLoC → State → UI

            Provider (Global):
            - Language/Locale
            - Theme
            """)

        # Utilities
        with Cluster("Shared Components"):
            theme = Dart("Theme\n& Styling")
            constants = Dart("Constants\n(Colors, Strings)")
            validators = Dart("Form\nValidators")
            widgets = Dart("Reusable\nWidgets")

    # ==================== BACKEND SERVICES ====================
    with Cluster("BACKEND & EXTERNAL SERVICES"):

        # Firebase Backend
        with Cluster("Firebase Backend"):
            firebase_services = Firebase("""
            Firebase Suite:
            • Authentication
            • Cloud Firestore (Database)
            • Storage (Images/Files)
            • Cloud Messaging (Push)
            • Analytics
            • Crashlytics
            • Performance Monitoring
            • Remote Config (Flags)
            • App Check (Security)
            """)

            firebase_emulator = Dart("""
            Local Development:
            Firebase Emulators (Docker)
            - Auth: :9099
            - Firestore: :8080
            - Storage: :9199
            - Functions: :5001
            """)

        # Third-Party Services
        with Cluster("Third-Party APIs"):
            maps = Dart("Google Maps\n(Location)")
            mlkit = Dart("ML Kit\n(Face Detection,\nTranslation)")
            iap_service = Dart("In-App Purchase\n(Subscriptions)")

        # Local Storage
        with Cluster("Local Persistence"):
            storage = Dart("""
            SharedPreferences: Settings
            Hive: Offline Data Cache
            """)

    # ==================== CONNECTIONS ====================

    # Data Sources to Firebase
    auth_ds >> Edge(label="API", color="red") >> firebase_services
    profile_ds >> Edge(color="red") >> firebase_services
    chat_impl >> Edge(color="red") >> firebase_services
    discovery_impl >> Edge(color="red") >> firebase_services

    # Dependency Injection provides dependencies
    di_factory >> Edge(label="provides", color="green", style="dashed") >> auth_bloc
    di_factory >> Edge(color="green", style="dashed") >> profile_bloc
    di_singleton >> Edge(color="green", style="dashed") >> auth_usecases
    di_singleton >> Edge(color="green", style="dashed") >> auth_impl

    # Error handling flow
    auth_impl >> Edge(label="Either<Failure,T>", style="dotted") >> error_flow

    # Bloc pattern
    auth_bloc >> Edge(label="follows", style="dotted") >> bloc_pattern

    # Shared components used by features
    widgets >> Edge(style="dotted", color="blue") >> auth_ui
    validators >> Edge(style="dotted", color="blue") >> auth_ui

    # Third-party integrations
    discovery_impl >> Edge(color="purple") >> maps
    profile_impl >> Edge(color="purple") >> mlkit

print("\n" + "="*70)
print("✅ DETAILED ARCHITECTURE DIAGRAM GENERATED!")
print("="*70)
print("\n📄 Output: greengo_detailed_architecture.png")
print("\n🏗️  ARCHITECTURE OVERVIEW:")
print("-" * 70)
print("📐 Pattern:        Clean Architecture + BLoC")
print("📦 Total Features: 17 modular features")
print("🎯 Layers:         3-layer per feature (Presentation, Domain, Data)")
print("🔄 State Mgmt:     BLoC (primary) + Provider (global)")
print("💉 DI:             GetIt with Factory/Singleton patterns")
print("🔥 Backend:        Firebase Suite (9 services)")
print("💾 Storage:        SharedPreferences + Hive")
print("🗺️  Maps:          Google Maps API")
print("🤖 ML:             Google ML Kit")
print("💰 Monetization:   In-App Purchase")
print("\n🎨 KEY ARCHITECTURAL PRINCIPLES:")
print("-" * 70)
print("✓ Dependency Inversion (dependencies point inward)")
print("✓ Single Responsibility (one use case = one action)")
print("✓ Separation of Concerns (clear layer boundaries)")
print("✓ Testability (mockable repositories, pure domain logic)")
print("✓ Functional Error Handling (Either<Failure, T>)")
print("✓ Feature-based Modularity (parallel development)")
print("✓ Repository Pattern (data abstraction)")
print("✓ BLoC Pattern (predictable state management)")
print("="*70)
print("\n💡 To generate the diagram, run:")
print("   python greengo_detailed_architecture.py")
print("\n📚 Make sure you have installed: pip install diagrams")
print("="*70 + "\n")
