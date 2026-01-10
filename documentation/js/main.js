// GreenGo Documentation - Main JavaScript

document.addEventListener('DOMContentLoaded', function() {
    initializeNavigation();
    initializeSearch();
    initializeMobileMenu();
    highlightCurrentPage();
});

// Navigation Toggle
function initializeNavigation() {
    const navSections = document.querySelectorAll('.nav-section');

    navSections.forEach(section => {
        const title = section.querySelector('.nav-section-title');

        title.addEventListener('click', function() {
            // Close other sections
            navSections.forEach(s => {
                if (s !== section) {
                    s.classList.remove('active');
                }
            });

            // Toggle current section
            section.classList.toggle('active');
        });
    });

    // Open the first section by default on the home page
    if (window.location.pathname.endsWith('index.html') || window.location.pathname.endsWith('/')) {
        const firstSection = document.querySelector('.nav-section');
        if (firstSection) {
            firstSection.classList.add('active');
        }
    }
}

// Search Functionality
function initializeSearch() {
    const searchInput = document.getElementById('searchInput');
    const navMenu = document.getElementById('navMenu');

    if (!searchInput || !navMenu) return;

    // Index of all documentation pages
    const searchIndex = [
        // Project Overview
        { title: 'Project Introduction', url: 'pages/01-introduction.html', section: 'overview', keywords: 'intro app description vision mission' },
        { title: 'Technology Stack', url: 'pages/02-tech-stack.html', section: 'overview', keywords: 'flutter firebase gcp django tech stack' },
        { title: 'Repository Structure', url: 'pages/03-repository-structure.html', section: 'overview', keywords: 'folder directory structure organization' },
        { title: 'Version History', url: 'pages/04-version-history.html', section: 'overview', keywords: 'changelog releases versions updates' },
        { title: 'Getting Started', url: 'pages/05-getting-started.html', section: 'overview', keywords: 'setup install prerequisites requirements' },
        { title: 'Development Environment', url: 'pages/06-dev-environment.html', section: 'overview', keywords: 'ide tools development setup' },
        { title: 'Quick Start Tutorial', url: 'pages/07-quick-start.html', section: 'overview', keywords: 'tutorial quick start first run' },
        { title: 'Glossary & Terminology', url: 'pages/08-glossary.html', section: 'overview', keywords: 'terms glossary definitions' },

        // Architecture
        { title: 'Clean Architecture', url: 'pages/09-clean-architecture.html', section: 'architecture', keywords: 'clean architecture domain data presentation' },
        { title: 'Feature Modules', url: 'pages/10-feature-modules.html', section: 'architecture', keywords: 'features modules organization' },
        { title: 'State Management (BLoC)', url: 'pages/11-state-management.html', section: 'architecture', keywords: 'bloc state management events states' },
        { title: 'Dependency Injection', url: 'pages/12-dependency-injection.html', section: 'architecture', keywords: 'getit dependency injection di' },
        { title: 'Navigation Architecture', url: 'pages/13-navigation.html', section: 'architecture', keywords: 'navigation routes deep linking' },
        { title: 'Data Flow Diagram', url: 'pages/14-data-flow.html', section: 'architecture', keywords: 'data flow diagram' },
        { title: 'Repository Pattern', url: 'pages/15-repository-pattern.html', section: 'architecture', keywords: 'repository pattern data source' },
        { title: 'Use Cases Design', url: 'pages/16-use-cases.html', section: 'architecture', keywords: 'use cases business logic' },
        { title: 'Entity vs Model', url: 'pages/17-entities-models.html', section: 'architecture', keywords: 'entity model domain data' },
        { title: 'Error Handling', url: 'pages/18-error-handling.html', section: 'architecture', keywords: 'error handling failures exceptions' },
        { title: 'Caching Strategy', url: 'pages/19-caching.html', section: 'architecture', keywords: 'caching local storage memory' },
        { title: 'Offline-First Architecture', url: 'pages/20-offline-first.html', section: 'architecture', keywords: 'offline first sync' },

        // Design System
        { title: 'Brand Guidelines', url: 'pages/21-brand-guidelines.html', section: 'design', keywords: 'brand logo guidelines' },
        { title: 'Color Palette', url: 'pages/22-color-palette.html', section: 'design', keywords: 'colors palette gold black theme' },
        { title: 'Typography System', url: 'pages/23-typography.html', section: 'design', keywords: 'typography fonts poppins text' },
        { title: 'Spacing & Dimensions', url: 'pages/24-spacing.html', section: 'design', keywords: 'spacing padding margins dimensions' },
        { title: 'Component Library', url: 'pages/25-components.html', section: 'design', keywords: 'components buttons inputs cards' },
        { title: 'Icon System', url: 'pages/26-icons.html', section: 'design', keywords: 'icons icon system' },
        { title: 'Animation Guidelines', url: 'pages/27-animations.html', section: 'design', keywords: 'animations lottie transitions' },
        { title: 'Dark/Light Theme', url: 'pages/28-theming.html', section: 'design', keywords: 'theme dark light mode' },
        { title: 'Responsive Design', url: 'pages/29-responsive.html', section: 'design', keywords: 'responsive mobile tablet desktop' },
        { title: 'Accessibility Guidelines', url: 'pages/30-accessibility.html', section: 'design', keywords: 'accessibility a11y screen reader' },

        // Core Features
        { title: 'Authentication Flow', url: 'pages/31-auth-flow.html', section: 'features', keywords: 'auth login register sign in' },
        { title: 'Social Authentication', url: 'pages/32-social-auth.html', section: 'features', keywords: 'google facebook apple social login' },
        { title: 'Biometric Authentication', url: 'pages/33-biometric-auth.html', section: 'features', keywords: 'biometric fingerprint face id' },
        { title: 'Profile Onboarding', url: 'pages/34-onboarding.html', section: 'features', keywords: 'onboarding profile creation wizard' },
        { title: 'Photo Management', url: 'pages/35-photo-upload.html', section: 'features', keywords: 'photo upload image verification' },
        { title: 'Profile Editing', url: 'pages/36-profile-editing.html', section: 'features', keywords: 'profile edit bio interests' },
        { title: 'Matching Algorithm', url: 'pages/37-matching-algorithm.html', section: 'features', keywords: 'matching algorithm ml compatibility' },
        { title: 'Discovery Interface', url: 'pages/38-discovery.html', section: 'features', keywords: 'discovery swipe cards' },
        { title: 'Like/Pass Actions', url: 'pages/39-like-actions.html', section: 'features', keywords: 'like super like pass' },
        { title: 'Match System', url: 'pages/40-match-system.html', section: 'features', keywords: 'match mutual matches' },
        { title: 'Real-time Chat', url: 'pages/41-chat.html', section: 'features', keywords: 'chat messaging real-time' },
        { title: 'Message Features', url: 'pages/42-message-features.html', section: 'features', keywords: 'reactions read receipts typing' },
        { title: 'Push Notifications', url: 'pages/43-push-notifications.html', section: 'features', keywords: 'push notifications fcm' },
        { title: 'In-App Notifications', url: 'pages/44-in-app-notifications.html', section: 'features', keywords: 'in-app notifications center' },
        { title: 'Subscription Tiers', url: 'pages/45-subscriptions.html', section: 'features', keywords: 'subscription tiers premium gold silver' },
        { title: 'In-App Purchases', url: 'pages/46-in-app-purchases.html', section: 'features', keywords: 'in-app purchases iap store' },
        { title: 'Virtual Currency', url: 'pages/47-coins.html', section: 'features', keywords: 'coins virtual currency balance' },
        { title: 'Gamification System', url: 'pages/48-gamification.html', section: 'features', keywords: 'gamification xp levels achievements' },
        { title: 'Daily Challenges', url: 'pages/49-challenges.html', section: 'features', keywords: 'challenges daily tasks' },
        { title: 'Leaderboards', url: 'pages/50-leaderboards.html', section: 'features', keywords: 'leaderboards ranking' },

        // Backend Services
        { title: 'Firebase Overview', url: 'pages/51-firebase-overview.html', section: 'backend', keywords: 'firebase overview services' },
        { title: 'Firestore Database', url: 'pages/52-firestore.html', section: 'backend', keywords: 'firestore database nosql' },
        { title: 'Firebase Authentication', url: 'pages/53-firebase-auth.html', section: 'backend', keywords: 'firebase auth authentication' },
        { title: 'Firebase Storage', url: 'pages/54-firebase-storage.html', section: 'backend', keywords: 'firebase storage files' },
        { title: 'Cloud Functions', url: 'pages/55-cloud-functions.html', section: 'backend', keywords: 'cloud functions serverless' },
        { title: 'Django Backend', url: 'pages/56-django-backend.html', section: 'backend', keywords: 'django backend rest api' },
        { title: 'API Documentation', url: 'pages/57-api-documentation.html', section: 'backend', keywords: 'api documentation endpoints' },
        { title: 'Real-time Sync', url: 'pages/58-realtime-sync.html', section: 'backend', keywords: 'real-time sync firestore' },
        { title: 'Background Processing', url: 'pages/59-background-processing.html', section: 'backend', keywords: 'background processing celery' },
        { title: 'Rate Limiting', url: 'pages/60-rate-limiting.html', section: 'backend', keywords: 'rate limiting throttling' },

        // Database
        { title: 'Firestore Schema', url: 'pages/61-firestore-schema.html', section: 'database', keywords: 'firestore schema collections' },
        { title: 'PostgreSQL Schema', url: 'pages/62-postgresql-schema.html', section: 'database', keywords: 'postgresql schema tables' },
        { title: 'Data Migration', url: 'pages/63-data-migration.html', section: 'database', keywords: 'migration schema evolution' },
        { title: 'Indexing Strategy', url: 'pages/64-indexing.html', section: 'database', keywords: 'indexing query optimization' },
        { title: 'Backup & Recovery', url: 'pages/65-backup-recovery.html', section: 'database', keywords: 'backup recovery restore' },
        { title: 'Data Retention Policy', url: 'pages/66-data-retention.html', section: 'database', keywords: 'data retention gdpr compliance' },
        { title: 'Redis Caching', url: 'pages/67-redis-caching.html', section: 'database', keywords: 'redis cache caching' },
        { title: 'BigQuery Analytics', url: 'pages/68-bigquery.html', section: 'database', keywords: 'bigquery analytics warehouse' },

        // Security
        { title: 'Security Architecture', url: 'pages/69-security-architecture.html', section: 'security', keywords: 'security architecture overview' },
        { title: 'Firestore Rules', url: 'pages/70-firestore-rules.html', section: 'security', keywords: 'firestore rules access control' },
        { title: 'Storage Rules', url: 'pages/71-storage-rules.html', section: 'security', keywords: 'storage rules permissions' },
        { title: 'Authentication Security', url: 'pages/72-auth-security.html', section: 'security', keywords: 'auth security jwt session' },
        { title: 'Data Encryption', url: 'pages/73-encryption.html', section: 'security', keywords: 'encryption kms at-rest' },
        { title: 'App Check', url: 'pages/74-app-check.html', section: 'security', keywords: 'app check attestation' },
        { title: 'Content Moderation', url: 'pages/75-content-moderation.html', section: 'security', keywords: 'content moderation photo text' },
        { title: 'Spam Detection', url: 'pages/76-spam-detection.html', section: 'security', keywords: 'spam scam detection' },
        { title: 'Reporting System', url: 'pages/77-reporting-system.html', section: 'security', keywords: 'reporting system user reports' },
        { title: 'Security Audit', url: 'pages/78-security-audit.html', section: 'security', keywords: 'security audit penetration' },

        // Integrations
        { title: 'Agora Video Calling', url: 'pages/79-agora-video.html', section: 'integrations', keywords: 'agora video calling rtc' },
        { title: 'Stripe Payments', url: 'pages/80-stripe.html', section: 'integrations', keywords: 'stripe payments billing' },
        { title: 'SendGrid Email', url: 'pages/81-sendgrid.html', section: 'integrations', keywords: 'sendgrid email transactional' },
        { title: 'Twilio SMS', url: 'pages/82-twilio.html', section: 'integrations', keywords: 'twilio sms verification' },
        { title: 'Google Maps', url: 'pages/83-google-maps.html', section: 'integrations', keywords: 'google maps location' },
        { title: 'Google Cloud AI', url: 'pages/84-google-cloud-ai.html', section: 'integrations', keywords: 'google cloud ai vision translation' },
        { title: 'Mixpanel Analytics', url: 'pages/85-mixpanel.html', section: 'integrations', keywords: 'mixpanel analytics tracking' },
        { title: 'Sentry Tracking', url: 'pages/86-sentry.html', section: 'integrations', keywords: 'sentry error tracking crashes' },
        { title: 'Perspective API', url: 'pages/87-perspective-api.html', section: 'integrations', keywords: 'perspective api moderation' },
        { title: 'RevenueCat', url: 'pages/88-revenuecat.html', section: 'integrations', keywords: 'revenuecat subscriptions' },

        // DevOps
        { title: 'Terraform Infrastructure', url: 'pages/89-terraform.html', section: 'devops', keywords: 'terraform infrastructure iac gcp' },
        { title: 'Docker Development', url: 'pages/90-docker.html', section: 'devops', keywords: 'docker containers development' },
        { title: 'CI/CD Pipeline', url: 'pages/91-cicd.html', section: 'devops', keywords: 'cicd pipeline automation' },
        { title: 'Environment Management', url: 'pages/92-environments.html', section: 'devops', keywords: 'environments dev test prod' },
        { title: 'Feature Flags', url: 'pages/93-feature-flags.html', section: 'devops', keywords: 'feature flags remote config' },
        { title: 'Pre-commit Hooks', url: 'pages/94-pre-commit.html', section: 'devops', keywords: 'pre-commit hooks linting' },
        { title: 'Deployment Scripts', url: 'pages/95-deployment.html', section: 'devops', keywords: 'deployment scripts release' },
        { title: 'Firebase Hosting', url: 'pages/96-firebase-hosting.html', section: 'devops', keywords: 'firebase hosting web' },

        // Testing
        { title: 'Unit Testing', url: 'pages/97-unit-testing.html', section: 'testing', keywords: 'unit testing bloc repository' },
        { title: 'Widget Testing', url: 'pages/98-widget-testing.html', section: 'testing', keywords: 'widget testing ui' },
        { title: 'Integration Testing', url: 'pages/99-integration-testing.html', section: 'testing', keywords: 'integration testing e2e' },
        { title: 'Firebase Test Lab', url: 'pages/100-firebase-test-lab.html', section: 'testing', keywords: 'firebase test lab devices' }
    ];

    let debounceTimer;

    searchInput.addEventListener('input', function(e) {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            const query = e.target.value.toLowerCase().trim();

            if (query.length < 2) {
                resetSearch();
                return;
            }

            const results = searchIndex.filter(item =>
                item.title.toLowerCase().includes(query) ||
                item.keywords.toLowerCase().includes(query)
            );

            displaySearchResults(results);
        }, 300);
    });

    function displaySearchResults(results) {
        // Hide all nav items
        const allLinks = navMenu.querySelectorAll('.nav-submenu li');
        allLinks.forEach(link => link.style.display = 'none');

        // Open all sections
        const sections = navMenu.querySelectorAll('.nav-section');
        sections.forEach(section => section.classList.add('active'));

        if (results.length === 0) {
            // Show "no results" message
            return;
        }

        // Show matching items
        results.forEach(result => {
            const link = navMenu.querySelector(`a[href="${result.url}"]`);
            if (link) {
                link.parentElement.style.display = 'block';
            }
        });
    }

    function resetSearch() {
        const allLinks = navMenu.querySelectorAll('.nav-submenu li');
        allLinks.forEach(link => link.style.display = 'block');

        // Reset sections to default state
        const sections = navMenu.querySelectorAll('.nav-section');
        sections.forEach(section => section.classList.remove('active'));

        // Open first section by default
        if (sections[0]) {
            sections[0].classList.add('active');
        }
    }
}

// Mobile Menu
function initializeMobileMenu() {
    const mobileToggle = document.getElementById('mobileMenuToggle');
    const sidebar = document.getElementById('sidebar');

    if (!mobileToggle || !sidebar) return;

    mobileToggle.addEventListener('click', function() {
        sidebar.classList.toggle('active');
    });

    // Close sidebar when clicking outside
    document.addEventListener('click', function(e) {
        if (window.innerWidth <= 1024) {
            if (!sidebar.contains(e.target) && !mobileToggle.contains(e.target)) {
                sidebar.classList.remove('active');
            }
        }
    });

    // Close sidebar when clicking a link on mobile
    const navLinks = sidebar.querySelectorAll('.nav-submenu a');
    navLinks.forEach(link => {
        link.addEventListener('click', function() {
            if (window.innerWidth <= 1024) {
                sidebar.classList.remove('active');
            }
        });
    });
}

// Highlight Current Page
function highlightCurrentPage() {
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('.nav-submenu a');

    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (currentPath.includes(href) || (href && currentPath.endsWith(href.split('/').pop()))) {
            link.classList.add('active');

            // Open parent section
            const section = link.closest('.nav-section');
            if (section) {
                section.classList.add('active');
            }
        }
    });
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Copy code blocks
function initializeCodeCopy() {
    const codeBlocks = document.querySelectorAll('pre code');

    codeBlocks.forEach(block => {
        const wrapper = block.parentElement;
        const copyButton = document.createElement('button');
        copyButton.className = 'copy-button';
        copyButton.textContent = 'Copy';

        wrapper.style.position = 'relative';
        wrapper.appendChild(copyButton);

        copyButton.addEventListener('click', async () => {
            try {
                await navigator.clipboard.writeText(block.textContent);
                copyButton.textContent = 'Copied!';
                setTimeout(() => {
                    copyButton.textContent = 'Copy';
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);
            }
        });
    });
}

// Initialize code copy when DOM is loaded
document.addEventListener('DOMContentLoaded', initializeCodeCopy);
