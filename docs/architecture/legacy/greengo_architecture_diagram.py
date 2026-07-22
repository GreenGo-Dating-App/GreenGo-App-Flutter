"""
GreenGo App - Flutter Architecture Diagram Generator
Clean Architecture + BLoC Pattern Visualization

Requirements:
pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.custom import Custom
from diagrams.programming.framework import Flutter
from diagrams.programming.language import Dart
from diagrams.firebase import Firebase
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis

# Graph attributes for better layout
graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho",
    "nodesep": "0.8",
    "ranksep": "1.2"
}

with Diagram(
    "GreenGo App - Clean Architecture + BLoC Pattern",
    filename="greengo_mvp_architecture",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
    outformat="png"
):

    # ==================== PRESENTATION LAYER ====================
    with Cluster("PRESENTATION LAYER (UI & State Management)"):

        with Cluster("BLoC Pattern"):
            # Core BLoC components
            ui = Dart("UI Widgets\n(Screens)")
            events = Dart("Events\n(User Actions)")
            bloc = Dart("BLoC\n(Business Logic)")
            states = Dart("States\n(UI States)")

            # BLoC flow
            ui >> Edge(label="dispatch") >> events
            events >> Edge(label="process") >> bloc
            bloc >> Edge(label="emit") >> states
            states >> Edge(label="rebuild") >> ui

        with Cluster("Feature Screens (17 Modules)"):
            auth_screen = Flutter("Authentication")
            profile_screen = Flutter("Profile")
            discovery_screen = Flutter("Discovery\n(Swipe)")
            chat_screen = Flutter("Chat")
            match_screen = Flutter("Matching")

            other_screens = Flutter("+ 12 more features\n(Coins, Gamification,\nSubscription, etc.)")

        with Cluster("Shared Widgets"):
            shared_widgets = Dart("Reusable\nComponents")

    # ==================== DOMAIN LAYER ====================
    with Cluster("DOMAIN LAYER (Business Logic - Framework Independent)"):

        with Cluster("Entities"):
            user_entity = Dart("User")
            profile_entity = Dart("Profile")
            message_entity = Dart("Message")
            match_entity = Dart("Match")
            entities = Dart("+ Other Entities")

        with Cluster("Use Cases"):
            signin_usecase = Dart("SignInWithEmail")
            getprofile_usecase = Dart("GetProfile")
            sendmessage_usecase = Dart("SendMessage")
            usecases = Dart("+ 50+ Use Cases\n(One action each)")

        with Cluster("Repository Interfaces"):
            auth_repo_interface = Dart("AuthRepository\n(Abstract)")
            profile_repo_interface = Dart("ProfileRepository\n(Abstract)")
            chat_repo_interface = Dart("ChatRepository\n(Abstract)")
            repo_interfaces = Dart("+ Other Interfaces")

    # ==================== DATA LAYER ====================
    with Cluster("DATA LAYER (Data Sources & Repository Implementations)"):

        with Cluster("Models (DTOs)"):
            user_model = Dart("UserModel\n(extends User)")
            profile_model = Dart("ProfileModel\n(JSON/Firestore)")
            message_model = Dart("MessageModel")
            models = Dart("+ Other Models")

        with Cluster("Repository Implementations"):
            auth_repo_impl = Dart("AuthRepositoryImpl")
            profile_repo_impl = Dart("ProfileRepositoryImpl")
            chat_repo_impl = Dart("ChatRepositoryImpl")
            repo_impl = Dart("+ Other Repo Impls")

        with Cluster("Data Sources"):
            remote_ds = Dart("Remote\nData Sources")
            local_ds = Dart("Local\nData Sources")

    # ==================== CORE / INFRASTRUCTURE ====================
    with Cluster("CORE (Cross-Cutting Concerns)"):

        with Cluster("Dependency Injection"):
            getit = Dart("GetIt\nService Locator")
            di_config = Dart("Factory/Singleton\nRegistration")

        with Cluster("Error Handling"):
            failures = Dart("Failures\n(Domain)")
            exceptions = Dart("Exceptions\n(Data)")
            either = Dart("Either<L,R>\n(Dartz)")

        with Cluster("Infrastructure"):
            theme = Dart("Theme\n& Colors")
            constants = Dart("Constants")
            validators = Dart("Validators")
            utils = Dart("Utilities")

        with Cluster("State Providers"):
            language_provider = Dart("LanguageProvider\n(Global State)")

    # ==================== EXTERNAL SERVICES ====================
    with Cluster("EXTERNAL SERVICES & BACKEND"):

        with Cluster("Firebase Services"):
            firebase_auth = Firebase("Firebase\nAuthentication")
            firestore = Firebase("Cloud\nFirestore")
            firebase_storage = Firebase("Firebase\nStorage")
            firebase_messaging = Firebase("Cloud\nMessaging")
            firebase_analytics = Firebase("Analytics")
            firebase_remote = Firebase("Remote Config\n(Feature Flags)")

        with Cluster("Third-Party APIs"):
            google_maps = PostgreSQL("Google Maps\nAPI")
            ml_kit = PostgreSQL("ML Kit\n(Face Detection)")
            iap = PostgreSQL("In-App\nPurchase")

        with Cluster("Local Storage"):
            shared_prefs = Redis("SharedPreferences")
            hive = Redis("Hive\n(NoSQL DB)")

    # ==================== DATA FLOW CONNECTIONS ====================

    # Presentation -> Domain
    bloc >> Edge(label="calls", color="blue", style="bold") >> signin_usecase
    bloc >> Edge(color="blue") >> getprofile_usecase
    bloc >> Edge(color="blue") >> sendmessage_usecase

    # Domain -> Repository Interfaces
    signin_usecase >> Edge(label="uses", color="green") >> auth_repo_interface
    getprofile_usecase >> Edge(color="green") >> profile_repo_interface
    sendmessage_usecase >> Edge(color="green") >> chat_repo_interface

    # Repository Interfaces -> Repository Implementations (Dependency Inversion)
    auth_repo_interface >> Edge(label="implemented by", color="purple", style="dashed") >> auth_repo_impl
    profile_repo_interface >> Edge(color="purple", style="dashed") >> profile_repo_impl
    chat_repo_interface >> Edge(color="purple", style="dashed") >> chat_repo_impl

    # Repository Implementations -> Data Sources
    auth_repo_impl >> Edge(label="fetches", color="orange") >> remote_ds
    profile_repo_impl >> Edge(color="orange") >> remote_ds
    chat_repo_impl >> Edge(color="orange") >> remote_ds

    auth_repo_impl >> Edge(color="orange") >> local_ds
    profile_repo_impl >> Edge(color="orange") >> local_ds

    # Data Sources -> External Services
    remote_ds >> Edge(label="Firebase calls", color="red") >> firebase_auth
    remote_ds >> Edge(color="red") >> firestore
    remote_ds >> Edge(color="red") >> firebase_storage
    remote_ds >> Edge(color="red") >> firebase_messaging

    local_ds >> Edge(color="brown") >> shared_prefs
    local_ds >> Edge(color="brown") >> hive

    # Models relationship
    user_model >> Edge(label="converts to/from", style="dotted") >> user_entity
    profile_model >> Edge(style="dotted") >> profile_entity
    message_model >> Edge(style="dotted") >> message_entity

    # Dependency Injection
    getit >> Edge(label="injects", color="darkgreen", style="bold") >> bloc
    getit >> Edge(color="darkgreen") >> signin_usecase
    getit >> Edge(color="darkgreen") >> auth_repo_impl
    getit >> Edge(color="darkgreen") >> remote_ds

    # Error Handling Flow
    exceptions >> Edge(label="converted to", style="dashed") >> failures
    failures >> Edge(label="Either<Failure,T>") >> either
    either >> Edge() >> bloc

    # Feature Screens to BLoC
    auth_screen >> Edge(color="lightblue") >> bloc
    profile_screen >> Edge(color="lightblue") >> bloc
    discovery_screen >> Edge(color="lightblue") >> bloc
    chat_screen >> Edge(color="lightblue") >> bloc

    # Global State
    language_provider >> Edge(label="provides", style="dotted") >> ui

print("✅ Architecture diagram generated successfully!")
print("📄 Output file: greengo_mvp_architecture.png")
print("\n📋 Architecture Summary:")
print("=" * 60)
print("Pattern: Clean Architecture + BLoC")
print("Layers: 3 (Presentation, Domain, Data)")
print("Features: 17 modular features")
print("State Management: BLoC + Provider")
print("DI: GetIt with Factory/Singleton pattern")
print("Error Handling: Either<Failure, T> (Functional)")
print("Backend: Firebase (Auth, Firestore, Storage, etc.)")
print("=" * 60)
