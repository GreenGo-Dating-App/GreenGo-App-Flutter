# Firebase Emulators Docker Image
FROM node:20-alpine

# Install Firebase CLI and Java 21 (required for emulators)
RUN apk add --no-cache openjdk21-jre bash curl && \
    npm install -g firebase-tools@latest

# Create working directory
WORKDIR /firebase

# Create data directory for persistence
RUN mkdir -p /firebase/data

# Expose ports for emulators
# 4000 - Emulator UI
# 9099 - Auth Emulator
# 8080 - Firestore Emulator
# 9199 - Storage Emulator
# 5001 - Functions Emulator
# 8085 - Pub/Sub Emulator
# 9000 - Realtime Database Emulator
EXPOSE 4000 9099 8080 9199 5001 8085 9000

# Copy firebase configuration
COPY firebase.json .
COPY .firebaserc .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:4000 || exit 1

# Start Firebase emulators (only auth, firestore, storage - no functions/hosting)
CMD ["firebase", "emulators:start", "--project", "demo-greengo-chat", "--only", "auth,firestore,storage,pubsub,ui"]
