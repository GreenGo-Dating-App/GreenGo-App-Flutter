"""
GreenGo App - Detailed Cloud Functions Breakdown
Shows function types, triggers, and data flow

Requirements:
pip install diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.programming.framework import Flutter
from diagrams.programming.language import TypeScript
from diagrams.gcp.compute import Functions
from diagrams.firebase import Firebase
from diagrams.gcp.storage import Storage
from diagrams.gcp.ml import VisionAPI, TranslationAPI, SpeechToText
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis

graph_attr = {
    "fontsize": "10",
    "bgcolor": "white",
    "pad": "1.2",
    "splines": "polyline",
    "nodesep": "0.7",
    "ranksep": "1.2"
}

with Diagram(
    "GreenGo - Cloud Functions Detailed Breakdown",
    filename="greengo_functions_detailed",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    outformat="png"
):

    # Client
    client = Flutter("Flutter\nClient")

    # ==================== FUNCTION TYPES ====================
    with Cluster("FUNCTION TRIGGER TYPES"):

        with Cluster("HTTP Callable (~120 functions)"):
            callable_desc = TypeScript("""
            User-facing functions
            Require authentication
            Input validation
            Return typed responses
            Error handling

            Examples:
            • compressImage()
            • translateMessage()
            • verifyPurchase()
            • sendNotification()
            """)

        with Cluster("Storage Triggered (~10 functions)"):
            storage_desc = TypeScript("""
            Auto-triggered on file upload
            Media processing pipeline

            Examples:
            • compressUploadedImage
            • processUploadedVideo
            • transcribeVoiceMessage
            """)

        with Cluster("Firestore Triggered (~15 functions)"):
            firestore_desc = TypeScript("""
            Document create/update/delete
            Auto-translation
            Notification sending

            Examples:
            • autoTranslateMessage
            • onNewMatch
            • onMessageSent
            """)

        with Cluster("Scheduled/Cron (~15 functions)"):
            scheduled_desc = TypeScript("""
            Pub/Sub triggered
            Background maintenance
            Batch processing

            Examples:
            • sendScheduledMessages (1 min)
            • cleanupDisappearingMedia (hourly)
            • checkExpiringSubscriptions (daily)
            • grantMonthlyAllowances (monthly)
            """)

        with Cluster("Webhooks (~5 functions)"):
            webhook_desc = TypeScript("""
            External service callbacks
            Payment processing

            Examples:
            • handlePlayStoreWebhook
            • handleAppStoreWebhook
            • handleStripeWebhook
            """)

    # ==================== FUNCTION CATEGORIES ====================
    with Cluster("MICROSERVICES BY DOMAIN"):

        # Media Processing
        with Cluster("Media Processing (10 functions)"):
            media_http = Functions("HTTP Callable:\n• compressImage\n• generateVideoThumbnail\n• transcribeAudio\n• batchTranscribe\n• markMediaAsDisappearing")
            media_trigger = Functions("Triggers:\n• compressUploadedImage\n• processUploadedVideo\n• transcribeVoiceMessage")
            media_scheduled = Functions("Scheduled:\n• cleanupDisappearingMedia (hourly)")

        # Subscription Management
        with Cluster("Subscription (4 functions)"):
            sub_webhook = Functions("Webhooks:\n• handlePlayStoreWebhook\n• handleAppStoreWebhook")
            sub_scheduled = Functions("Scheduled:\n• checkExpiringSubscriptions (daily 9am)\n• handleExpiredGracePeriods (hourly)")

        # Coin Management
        with Cluster("Coin Service (6 functions)"):
            coin_http = Functions("HTTP Callable:\n• verifyGooglePlayCoinPurchase\n• verifyAppStoreCoinPurchase\n• claimReward")
            coin_scheduled = Functions("Scheduled:\n• grantMonthlyAllowances (monthly 1st)\n• processExpiredCoins (daily 2am)\n• sendExpirationWarnings (daily 10am)")

        # Analytics
        with Cluster("Analytics (20+ functions)"):
            analytics_http = Functions("HTTP Callable:\n• getRevenueDashboard\n• getCohortAnalysis\n• getUserChurnPrediction\n• createABTest\n• recordConversion\n• getARPU\n• calculateUserSegment")
            analytics_scheduled = Functions("Scheduled:\n• predictChurnDaily")

        # Video Calling
        with Cluster("Video Calling (21 functions)"):
            video_http = Functions("HTTP Callable:\n• initiateVideoCall\n• answerVideoCall\n• endVideoCall\n• handleCallSignal\n• updateCallQuality\n• enableVirtualBackground\n• applyARFilter\n• startScreenSharing\n• createGroupVideoCall\n• joinGroupVideoCall")
            video_scheduled = Functions("Scheduled:\n• cleanupExpiredReactions")

        # Notifications
        with Cluster("Notifications (8 functions)"):
            notif_http = Functions("HTTP Callable:\n• sendPushNotification\n• sendBundledNotifications\n• sendTransactionalEmail\n• startWelcomeEmailSeries")
            notif_scheduled = Functions("Scheduled:\n• processWelcomeEmailSeries\n• sendWeeklyDigestEmails (weekly)\n• sendReEngagementCampaign")

    # ==================== DATA STORES ====================
    with Cluster("DATA LAYER"):

        with Cluster("Firebase"):
            firestore = Firebase("Firestore\nDocument DB")
            firebase_storage = Storage("Cloud Storage\nMedia Files")

        with Cluster("Backend DBs"):
            postgres = PostgreSQL("PostgreSQL\nRelational DB")
            redis = Redis("Redis\nCache")

        with Cluster("AI Services"):
            vision = VisionAPI("Vision API")
            translation = TranslationAPI("Translation API")
            speech = SpeechToText("Speech-to-Text")

    # ==================== CONNECTIONS ====================

    # Client to Functions
    client >> Edge(label="calls", color="blue") >> media_http
    client >> Edge(label="calls", color="blue") >> coin_http
    client >> Edge(label="calls", color="blue") >> analytics_http
    client >> Edge(label="calls", color="blue") >> video_http
    client >> Edge(label="calls", color="blue") >> notif_http

    # Storage triggers
    client >> Edge(label="uploads", color="green") >> firebase_storage
    firebase_storage >> Edge(label="triggers", color="green") >> media_trigger

    # Functions to Data Stores
    media_http >> Edge(label="store", color="red") >> firestore
    media_http >> Edge(label="upload", color="red") >> firebase_storage
    media_trigger >> Edge(label="process", color="orange") >> vision
    media_trigger >> Edge(label="transcribe", color="orange") >> speech

    sub_webhook >> Edge(label="update", color="red") >> firestore
    sub_scheduled >> Edge(label="query", color="red") >> firestore

    coin_http >> Edge(label="transactions", color="red") >> firestore
    coin_scheduled >> Edge(label="update balances", color="red") >> firestore

    analytics_http >> Edge(label="query", color="red") >> firestore
    analytics_http >> Edge(label="SQL", color="purple") >> postgres

    video_http >> Edge(label="signaling", color="red") >> firestore
    video_http >> Edge(label="cache", color="brown") >> redis

    notif_http >> Edge(label="read users", color="red") >> firestore

print("\n" + "="*80)
print("SUCCESS: Detailed Functions Diagram Generated!")
print("="*80)
print("\nOutput: greengo_functions_detailed.png")
print("\n" + "="*80)
print("FUNCTION BREAKDOWN BY TRIGGER TYPE")
print("="*80)
print("\nHTTP Callable Functions: ~120")
print("  - User-facing API functions")
print("  - Require Firebase Authentication")
print("  - Examples: compressImage, translateMessage, verifyPurchase")
print("\nStorage Triggered Functions: ~10")
print("  - Auto-triggered on Cloud Storage uploads")
print("  - Examples: compressUploadedImage, processUploadedVideo")
print("\nFirestore Triggered Functions: ~15")
print("  - React to database changes")
print("  - Examples: autoTranslateMessage, onNewMatch")
print("\nScheduled Functions (Cron): ~15")
print("  - Time-based execution")
print("  - Examples: cleanupDisappearingMedia (hourly)")
print("           checkExpiringSubscriptions (daily 9am)")
print("           grantMonthlyAllowances (monthly 1st)")
print("\nWebhook Functions: ~5")
print("  - External service callbacks")
print("  - Examples: handlePlayStoreWebhook, handleAppStoreWebhook")
print("\n" + "="*80)
print("TOTAL: 160+ Cloud Functions")
print("="*80)
