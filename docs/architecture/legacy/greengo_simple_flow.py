"""
GreenGo App - Simplified Architecture Flow
Clear visualization of Clean Architecture layers and data flow

Requirements:
pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.programming.framework import Flutter
from diagrams.programming.language import Dart
from diagrams.firebase import Firebase
from diagrams.onprem.inmemory import Redis

graph_attr = {
    "fontsize": "13",
    "bgcolor": "white",
    "pad": "1.0",
    "splines": "ortho",
    "rankdir": "TB"
}

with Diagram(
    "GreenGo App - Clean Architecture Data Flow",
    filename="greengo_simple_flow",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
    outformat="png"
):

    # User
    user = Flutter("User Interface\n(17 Feature Screens)")

    # ==================== PRESENTATION LAYER ====================
    with Cluster("PRESENTATION LAYER"):
        with Cluster("BLoC State Management"):
            events = Dart("Events\n(User Actions)")
            bloc = Dart("BLoC\n(Business Logic Component)")
            states = Dart("States\n(UI State)")

        # Flow within presentation
        events >> Edge(label="1. receives") >> bloc
        bloc >> Edge(label="8. emits") >> states

    # ==================== DOMAIN LAYER ====================
    with Cluster("DOMAIN LAYER (Pure Business Logic)"):
        with Cluster("Business Logic"):
            usecases = Dart("Use Cases\n(Single Responsibility)\n\nExamples:\n• SignInWithEmail\n• GetUserProfile\n• SendMessage\n• SwipeRight")

        with Cluster("Business Objects"):
            entities = Dart("Entities\n(Plain Dart Objects)\n\nExamples:\n• User\n• Profile\n• Message\n• Match")

        with Cluster("Contracts"):
            repositories = Dart("Repository Interfaces\n(Abstract Classes)\n\nDefine contracts for:\n• Data operations\n• Return Either<Failure, T>")

        # Flow within domain
        usecases >> Edge(label="uses") >> repositories
        usecases >> Edge(label="returns") >> entities

    # ==================== DATA LAYER ====================
    with Cluster("DATA LAYER (Data Management)"):
        with Cluster("Repository Implementation"):
            repo_impl = Dart("Repository Implementations\n\n• Implements interfaces\n• Converts Exceptions → Failures\n• Returns Either<Failure, Entity>")

        with Cluster("Data Transfer Objects"):
            models = Dart("Models\n(DTOs)\n\n• Extends Entities\n• JSON/Firestore serialization\n• fromJson() / toJson()\n• fromFirestore() / toFirestore()")

        with Cluster("Data Sources"):
            remote = Dart("Remote Data Source\n\n• Firebase API calls\n• REST API calls\n• Real-time listeners")
            local = Dart("Local Data Source\n\n• SharedPreferences\n• Hive database\n• Offline cache")

        # Flow within data
        repo_impl >> Edge(label="uses") >> remote
        repo_impl >> Edge(label="uses") >> local
        repo_impl >> Edge(label="serializes") >> models

    # ==================== EXTERNAL LAYER ====================
    with Cluster("EXTERNAL SERVICES"):
        with Cluster("Firebase Backend"):
            firebase_auth = Firebase("Firebase Auth")
            firestore = Firebase("Firestore DB")
            storage = Firebase("Storage")
            messaging = Firebase("Messaging")

        with Cluster("Other Services"):
            maps = Dart("Google Maps")
            mlkit = Dart("ML Kit")
            iap = Dart("In-App Purchase")

        with Cluster("Local Storage"):
            prefs = Redis("Shared\nPreferences")
            hive = Redis("Hive DB")

    # ==================== CROSS-CUTTING CONCERNS ====================
    with Cluster("DEPENDENCY INJECTION (GetIt)"):
        di = Dart("""
        Service Locator Pattern:

        Factory → BLoCs (new instance per screen)
        LazySingleton → Use Cases, Repositories, Data Sources
        External → Firebase, APIs, Storage
        """)

    with Cluster("ERROR HANDLING"):
        error_handling = Dart("""
        Functional Error Handling (dartz):

        Data Layer: throw Exception
                    ↓
        Repository: catch → return Left(Failure)
                    ↓
        Use Case:   return Either<Failure, Entity>
                    ↓
        BLoC:       emit ErrorState or SuccessState
        """)

    # ==================== MAIN DATA FLOW ====================

    # User interaction
    user >> Edge(label="interacts", color="blue", style="bold") >> events

    # Presentation to Domain
    bloc >> Edge(label="2. calls", color="green", style="bold") >> usecases

    # Domain to Data (through interface)
    repositories >> Edge(label="3. contract", color="purple", style="dashed") >> repo_impl

    # Data to External
    remote >> Edge(label="4. API call", color="red") >> firebase_auth
    remote >> Edge(label="4. API call", color="red") >> firestore
    remote >> Edge(label="4. API call", color="red") >> storage
    local >> Edge(label="4. read/write", color="brown") >> prefs
    local >> Edge(label="4. read/write", color="brown") >> hive

    # Return path
    repo_impl >> Edge(label="5. Either<Failure, T>", color="orange", style="bold") >> repositories
    repositories >> Edge(label="6. Either<Failure, T>", color="orange", style="bold") >> usecases
    usecases >> Edge(label="7. Either<Failure, Entity>", color="orange", style="bold") >> bloc

    # State to UI
    states >> Edge(label="9. rebuilds", color="blue", style="bold") >> user

    # Dependency Injection
    di >> Edge(label="provides", color="darkgreen", style="dotted") >> bloc
    di >> Edge(color="darkgreen", style="dotted") >> usecases
    di >> Edge(color="darkgreen", style="dotted") >> repo_impl

    # Error handling flow
    error_handling >> Edge(style="dotted", color="red") >> repo_impl

print("\n" + "="*80)
print("✅ SIMPLIFIED ARCHITECTURE FLOW DIAGRAM GENERATED!")
print("="*80)
print("\n📄 Output: greengo_simple_flow.png")
print("\n🔄 DATA FLOW SEQUENCE:")
print("-" * 80)
print("1️⃣  User interacts with UI → Event dispatched")
print("2️⃣  BLoC receives event → Calls Use Case")
print("3️⃣  Use Case executes → Calls Repository Interface")
print("4️⃣  Repository Implementation → Calls Data Source")
print("5️⃣  Data Source → Makes API/DB calls to Firebase/Local Storage")
print("6️⃣  Data returns → Repository converts Model to Entity")
print("7️⃣  Repository → Returns Either<Failure, Entity> to Use Case")
print("8️⃣  Use Case → Returns Either<Failure, Entity> to BLoC")
print("9️⃣  BLoC → Emits new State (Success/Error)")
print("🔟 State change → UI rebuilds automatically")
print("\n🎯 KEY PRINCIPLES:")
print("-" * 80)
print("✓ Dependency Rule:     Inner layers don't know about outer layers")
print("✓ Dependency Inversion: Presentation depends on Domain abstractions, not Data")
print("✓ Single Responsibility: Each Use Case does ONE thing")
print("✓ Open/Closed:         Easy to add new features without modifying existing")
print("✓ Testability:         Each layer can be tested independently")
print("✓ Framework Independence: Domain layer has no Flutter/Firebase dependencies")
print("\n💡 ERROR HANDLING:")
print("-" * 80)
print("• Data Layer:         Throws Exceptions (ServerException, CacheException)")
print("• Repository Layer:   Catches → Converts to Failures (ServerFailure, CacheFailure)")
print("• Domain Layer:       Returns Either<Failure, T> (no exceptions thrown)")
print("• Presentation Layer: BLoC emits ErrorState or SuccessState")
print("• UI Layer:           BlocBuilder rebuilds based on state")
print("\n🔧 STATE MANAGEMENT:")
print("-" * 80)
print("• BLoC Pattern:  Event → BLoC → State (predictable, testable)")
print("• Provider:      Global app state (language, theme)")
print("• Equatable:     Value equality for states and entities")
print("\n📦 17 FEATURE MODULES:")
print("-" * 80)
print("Each feature follows same 3-layer pattern:")
print("  1. Authentication    7. Coins            13. Safety")
print("  2. Profile           8. Gamification     14. Localization")
print("  3. Discovery         9. Subscription     15. Admin")
print("  4. Matching         10. Video Calling    16. Main")
print("  5. Chat             11. Analytics        17. Settings")
print("  6. Notifications    12. Accessibility")
print("="*80)
print("\n💡 To generate diagram: python greengo_simple_flow.py")
print("📚 Requirements: pip install diagrams")
print("="*80 + "\n")
