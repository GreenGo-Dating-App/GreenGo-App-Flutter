"""
GreenGo App - Microservices & Functions Architecture Diagram
160+ Cloud Functions + Django Backend + Docker Services

Requirements:
pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.programming.framework import Flutter
from diagrams.programming.language import Dart, TypeScript, Python
from diagrams.firebase import Firebase
from diagrams.gcp.compute import Functions, Run
from diagrams.gcp.storage import Storage
from diagrams.gcp.analytics import Bigquery
from diagrams.gcp.ml import VisionAPI, NaturalLanguageAPI, SpeechToText, TranslationAPI
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.queue import Celery
from diagrams.onprem.network import Nginx
from diagrams.saas.cdn import Cloudflare
from diagrams.programming.framework import Django

# Graph attributes
graph_attr = {
    "fontsize": "11",
    "bgcolor": "white",
    "pad": "1.0",
    "splines": "spline",
    "nodesep": "0.8",
    "ranksep": "1.5"
}

with Diagram(
    "GreenGo App - Microservices Architecture (160+ Functions)",
    filename="greengo_microservices_architecture",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
    outformat="png"
):

    # Client
    client = Flutter("Flutter App\n(Mobile Client)")

    # API Gateway
    nginx = Nginx("Nginx\nAPI Gateway\nReverse Proxy")

    # ==================== FIREBASE CLOUD FUNCTIONS ====================
    with Cluster("FIREBASE CLOUD FUNCTIONS (160+ Serverless Functions)"):

        # Media Processing Service
        with Cluster("1. Media Processing (10 functions)"):
            media_service = Functions("Media Service")
            media_funcs = TypeScript("""
            • compressUploadedImage (trigger)
            • compressImage (callable)
            • processUploadedVideo (trigger)
            • generateVideoThumbnail (callable)
            • transcribeVoiceMessage (trigger)
            • transcribeAudio (callable)
            • batchTranscribe (callable)
            • cleanupDisappearingMedia (scheduled)
            • markMediaAsDisappearing (callable)
            """)

        # Messaging Service
        with Cluster("2. Messaging (8 functions)"):
            messaging_service = Functions("Messaging Service")
            messaging_funcs = TypeScript("""
            • translateMessage (callable)
            • autoTranslateMessage (trigger)
            • batchTranslateMessages (callable)
            • getSupportedLanguages (callable)
            • scheduleMessage (callable)
            • sendScheduledMessages (scheduled)
            • cancelScheduledMessage (callable)
            • getScheduledMessages (callable)
            """)

        # Backup & Export Service
        with Cluster("3. Backup & Export (8 functions)"):
            backup_service = Functions("Backup Service")
            backup_funcs = TypeScript("""
            • backupConversation (callable)
            • restoreConversation (callable)
            • listBackups (callable)
            • deleteBackup (callable)
            • autoBackupConversations (scheduled)
            • exportConversationToPDF (callable)
            • listPDFExports (callable)
            • cleanupExpiredExports (scheduled)
            """)

        # Subscription Service
        with Cluster("4. Subscription (4 functions)"):
            subscription_service = Functions("Subscription Service")
            subscription_funcs = TypeScript("""
            • handlePlayStoreWebhook (webhook)
            • handleAppStoreWebhook (webhook)
            • checkExpiringSubscriptions (scheduled)
            • handleExpiredGracePeriods (scheduled)

            Tiers: Basic, Silver ($9.99), Gold ($19.99)
            """)

        # Coin Service
        with Cluster("5. Coin Service (6 functions)"):
            coin_service = Functions("Coin Service")
            coin_funcs = TypeScript("""
            • verifyGooglePlayCoinPurchase (callable)
            • verifyAppStoreCoinPurchase (callable)
            • grantMonthlyAllowances (scheduled)
            • processExpiredCoins (scheduled)
            • sendExpirationWarnings (scheduled)
            • claimReward (callable)

            365-day expiration, FIFO spending
            """)

        # Analytics Service
        with Cluster("6. Analytics (20+ functions)"):
            analytics_service = Functions("Analytics Service")
            analytics_funcs = TypeScript("""
            • getRevenueDashboard (callable)
            • exportRevenueData (callable)
            • getCohortAnalysis (callable)
            • trainChurnModel (callable)
            • predictChurnDaily (scheduled)
            • getUserChurnPrediction (callable)
            • getAtRiskUsers (callable)
            • createABTest (callable)
            • recordConversion (callable)
            • getABTestResults (callable)
            • detectFraud (callable)
            • forecastMRR (callable)
            • getARPU (callable)
            • calculateUserSegment (callable)
            + 10 more analytics functions
            """)

        # Gamification Service
        with Cluster("7. Gamification (8 functions)"):
            gamification_service = Functions("Gamification Service")
            gamification_funcs = TypeScript("""
            • grantXP (callable)
            • trackAchievementProgress (callable)
            • unlockAchievementReward (callable)
            • claimLevelRewards (callable)
            • trackChallengeProgress (callable)
            • claimChallengeReward (callable)
            • resetDailyChallenges (scheduled)
            • updateLeaderboardRankings (scheduled)
            """)

        # Safety & Moderation Service
        with Cluster("8. Safety & Moderation (11 functions)"):
            safety_service = Functions("Safety Service")
            safety_funcs = TypeScript("""
            • moderatePhoto (callable)
            • moderateText (callable)
            • detectSpam (callable)
            • detectFakeProfile (callable)
            • detectScam (callable)
            • submitReport (callable)
            • reviewReport (callable)
            • submitAppeal (callable)
            • blockUser (callable)
            • verifyPhotoSelfie (callable)
            • calculateTrustScore (callable)
            """)

        # Admin Service
        with Cluster("9. Admin Panel (25+ functions)"):
            admin_service = Functions("Admin Service")
            admin_funcs = TypeScript("""
            Dashboard (9):
            • getUserActivityMetrics
            • getRevenueMetrics
            • getSystemHealthMetrics

            Role Management (6):
            • createAdminUser
            • updateAdminRole
            • updateAdminPermissions

            User Management (12):
            • searchUsers
            • suspendUserAccount
            • deleteUserAccount
            • executeMassAction
            """)

        # Notification Service
        with Cluster("10. Notification (8 functions)"):
            notification_service = Functions("Notification Service")
            notification_funcs = TypeScript("""
            • sendPushNotification (callable)
            • sendBundledNotifications (callable)
            • trackNotificationOpened (callable)
            • sendTransactionalEmail (callable)
            • startWelcomeEmailSeries (callable)
            • processWelcomeEmailSeries (scheduled)
            • sendWeeklyDigestEmails (scheduled)
            • sendReEngagementCampaign (scheduled)
            """)

        # Video Calling Service
        with Cluster("11. Video Calling (21 functions)"):
            video_service = Functions("Video Service")
            video_funcs = TypeScript("""
            Core (6):
            • initiateVideoCall, answerVideoCall
            • endVideoCall, handleCallSignal
            • updateCallQuality, startCallRecording

            Features (13):
            • enableVirtualBackground, applyARFilter
            • toggleBeautyMode, startScreenSharing
            • sendInCallReaction, getCallHistory

            Group Calls (8):
            • createGroupVideoCall (up to 8 users)
            • createBreakoutRoom, joinBreakoutRoom

            WebRTC + Agora.io SDK
            """)

        # Security Service
        with Cluster("12. Security (5 functions)"):
            security_service = Functions("Security Service")
            security_funcs = TypeScript("""
            • runSecurityAudit (callable)
            • scheduledSecurityAudit (scheduled)
            • getSecurityAuditReport (callable)
            • listSecurityAuditReports (callable)
            • cleanupOldAuditReports (scheduled)
            """)

    # ==================== DJANGO REST BACKEND ====================
    with Cluster("DJANGO REST BACKEND (Python)"):

        with Cluster("Django Services"):
            django_app = Django("Django 4.2.7\nDRF 3.14.0")

            auth_service = Python("Auth Service\n(JWT, OAuth)")
            user_service = Python("User Service\n(CRUD)")
            matching_service = Python("Matching Service\n(Algorithm)")
            messaging_service_django = Python("Messaging Service\n(WebSockets)")
            payment_service = Python("Payment Service\n(Stripe)")

        with Cluster("Background Tasks"):
            celery_worker = Celery("Celery Worker\nBackground Jobs")
            celery_beat = Celery("Celery Beat\nScheduled Tasks")

    # ==================== DOCKER SERVICES ====================
    with Cluster("CONTAINERIZED INFRASTRUCTURE (Docker)"):

        with Cluster("Databases"):
            postgres = PostgreSQL("PostgreSQL 15\ngreengo_db")
            redis_db = Redis("Redis 7\nCache & Sessions")

        with Cluster("Firebase Emulators (Dev)"):
            firebase_emu = Firebase("Firebase Emulator\nAuth, Firestore,\nStorage, Functions")

    # ==================== GOOGLE CLOUD PLATFORM ====================
    with Cluster("GOOGLE CLOUD PLATFORM SERVICES"):

        with Cluster("Firebase Services"):
            firebase_auth = Firebase("Firebase Auth")
            firestore = Firebase("Cloud Firestore\nNoSQL Database")
            firebase_storage = Storage("Firebase Storage\nFile Storage")
            firebase_hosting = Firebase("Firebase Hosting")

        with Cluster("AI/ML APIs"):
            vision_api = VisionAPI("Vision API\nPhoto Moderation")
            translation_api = TranslationAPI("Translation API\n20+ Languages")
            speech_api = SpeechToText("Speech-to-Text\n6 Languages")
            nlp_api = NaturalLanguageAPI("Natural Language\nSentiment Analysis")

        with Cluster("Data & Analytics"):
            bigquery = Bigquery("BigQuery\nData Warehouse")
            cloud_storage = Storage("Cloud Storage\nMedia Buckets")

    # ==================== EXTERNAL SERVICES ====================
    with Cluster("THIRD-PARTY SERVICES"):

        with Cluster("Payment Providers"):
            stripe = Python("Stripe\nPayments")
            google_play = Python("Google Play\nBilling")
            app_store = Python("App Store\nIAP")

        with Cluster("Communication"):
            sendgrid = Python("SendGrid\nEmail Delivery")
            twilio = Python("Twilio\nSMS")
            fcm = Firebase("FCM\nPush Notifications")

        with Cluster("Video Infrastructure"):
            agora = Python("Agora.io SDK\nVideo Calling")
            webrtc = Python("WebRTC\nSignaling")

    # ==================== DATA FLOW CONNECTIONS ====================

    # Client to API Gateway
    client >> Edge(label="HTTPS/WSS", color="blue", style="bold") >> nginx

    # API Gateway routing
    nginx >> Edge(label="/functions", color="green") >> media_service
    nginx >> Edge(label="/api", color="purple") >> django_app

    # Firebase Functions to Firebase Services
    media_service >> Edge(label="store", color="red") >> firestore
    media_service >> Edge(label="upload", color="red") >> firebase_storage

    messaging_service >> Edge(label="translate", color="orange") >> translation_api
    messaging_service >> Edge(label="write", color="red") >> firestore

    subscription_service >> Edge(label="subscriptions", color="red") >> firestore
    subscription_service >> Edge(label="verify", color="brown") >> google_play
    subscription_service >> Edge(label="verify", color="brown") >> app_store

    analytics_service >> Edge(label="query", color="darkblue") >> bigquery
    analytics_service >> Edge(label="read", color="red") >> firestore

    safety_service >> Edge(label="moderate", color="orange") >> vision_api
    safety_service >> Edge(label="analyze", color="orange") >> nlp_api

    video_service >> Edge(label="tokens", color="darkgreen") >> agora
    video_service >> Edge(label="signaling", color="red") >> firestore

    notification_service >> Edge(label="send", color="purple") >> fcm
    notification_service >> Edge(label="email", color="purple") >> sendgrid
    notification_service >> Edge(label="SMS", color="purple") >> twilio

    # Django to Data Stores
    django_app >> Edge(label="SQL queries", color="darkblue") >> postgres
    django_app >> Edge(label="cache", color="darkred") >> redis_db
    django_app >> Edge(label="read/write", color="red") >> firestore

    # Django services connections
    django_app >> Edge(label="manages", style="dotted") >> auth_service
    django_app >> Edge(label="manages", style="dotted") >> user_service
    django_app >> Edge(label="manages", style="dotted") >> matching_service
    django_app >> Edge(label="manages", style="dotted") >> messaging_service_django
    django_app >> Edge(label="manages", style="dotted") >> payment_service

    # Celery connections
    celery_worker >> Edge(label="broker", color="darkred") >> redis_db
    celery_worker >> Edge(label="tasks", style="dashed") >> django_app
    celery_beat >> Edge(label="schedule", style="dashed") >> celery_worker

    # Payment service
    payment_service >> Edge(label="process", color="brown") >> stripe

    # Client authentication
    client >> Edge(label="auth", color="lightblue") >> firebase_auth

print("\n" + "="*80)
print("SUCCESS: Microservices Architecture Diagram Generated!")
print("="*80)
print("\nOutput: greengo_microservices_architecture.png")
print("\n" + "="*80)
print("MICROSERVICES SUMMARY")
print("="*80)
print("\nFIREBASE CLOUD FUNCTIONS (160+ Serverless Functions):")
print("  1. Media Processing Service       - 10 functions")
print("  2. Messaging Service              -  8 functions")
print("  3. Backup & Export Service        -  8 functions")
print("  4. Subscription Service           -  4 functions")
print("  5. Coin Service                   -  6 functions")
print("  6. Analytics Service              - 20+ functions")
print("  7. Gamification Service           -  8 functions")
print("  8. Safety & Moderation Service    - 11 functions")
print("  9. Admin Panel Service            - 25+ functions")
print(" 10. Notification Service           -  8 functions")
print(" 11. Video Calling Service          - 21 functions")
print(" 12. Security Service               -  5 functions")
print("\nDJANGO REST BACKEND:")
print("  - Authentication Service (JWT, OAuth)")
print("  - User Management Service")
print("  - Matching Algorithm Service")
print("  - Real-time Messaging (WebSockets)")
print("  - Payment Processing (Stripe)")
print("  - Celery Background Workers")
print("\nDATABASES:")
print("  - Cloud Firestore (NoSQL)")
print("  - PostgreSQL 15 (Relational)")
print("  - Redis 7 (Cache)")
print("  - BigQuery (Analytics)")
print("\nEXTERNAL SERVICES:")
print("  - Firebase (Auth, Firestore, Storage, Hosting)")
print("  - GCP AI APIs (Vision, Translation, Speech, NLP)")
print("  - Agora.io (Video calling)")
print("  - SendGrid (Email)")
print("  - Twilio (SMS)")
print("  - Stripe (Payments)")
print("  - Google Play & App Store (IAP)")
print("\nINFRASTRUCTURE:")
print("  - Nginx API Gateway")
print("  - Docker Compose (Dev environment)")
print("  - Firebase Emulators (Local testing)")
print("="*80)
