!IMPORTANT! Apply the following principles 'IF POSSIBLE';


### USER EXPERIENCE ###
    1. Resource Management (The "Battery First" Rule)
        - Efficient Logic: Avoid computationally expensive loops or heavy background tasks unless absolutely necessary.
        - Memory Management: Code efficiently to prevent memory leaks.
        - Image Optimization: You must implement dynamic loading (loading images only when they appear on screen) and proper caching.

        2. Handling Interruptions and Lifecycle
        - State Preservation: When the app moves to the background and when the user returns, the app must restore their previous state (what they typed) exactly as they left it.
        - Graceful Pausing: When the app goes to the background, it should immediately stop non-essential tasks (like GPS tracking or animations) to save resources.

        3. Screen Fragmentation and Responsiveness
        - Responsive Layouts: Never use fixed pixel dimensions (e.g., "width: 300px;"). Use relative units (percentages, flexbox, constraints) so the UI adapts to a 5-inch phone and a 12-inch tablet equally well.
        - Touch Targets: Interactive elements (buttons/icons) should have a touch target of at least 44x44 points (iOS) or 48x48 dp (Android) to prevent "fat finger" errors.

        4. Network Volatility (Offline-First Mindset)
        - Caching: Store essential data locally on the device (using SQLite, Realm, or CoreData). The app should display content immediately upon opening, even if the internet is down, by showing the last known data.
        - Optimistic UI: When a user performs an action (e.g., "Add to cart" a product), update the UI immediately to "Added to cart" before waiting for the server response. This makes the app feel instant. If the request fails later, you can revert the change and notify the user.

        5.Platform Convention Compliance
        - Navigation: Often uses a "Back" button built into the hardware or OS gesture. Top-left "Hamburger" menus are common.
        - Selection: Long-press to select or open context menus.
        - Permissions: Ask for permissions (Camera, Location) only when the user tries to use that specific feature (Runtime Permissions).

        6. Security and Sandboxing
        - Least Privilege: Only request permissions that are critical.
        - Secure Storage: Never store sensitive tokens (passwords, API keys) in plain text files. Use the system's secure storage: EncryptedSharedPreferences/Keystore.

### DEVELOPER EXPERIENCE ###
    1. Structureal Principles (How code is organized)
        Ensure that the codebase doesn't collapse under its own weight as features are added.
            1.1. SOLID Principles
                1.1.a. Single Responsibility: A class should have one, and only one, reason to change. (e.g., A UserValidator class should not also handle SaveUserTo Database).
                1.1.b. Open/Closed: Software entities should be open for extension but closed for modification. (Use extensions/subclassing rather than reqriting existing classes).
                1.1.c. Liskov Substitution: Subtypes must be substitutable for their base types without breaking the app.
                1.1.d. Interface Segregation: Many specific interfaces are better than one general-purpose interface.
                1.1.e. Dependency Invasion: Depend on abstractions (interfaces), not concretions. (See Dependency Injection below).
            1.2. Dependency Injection (DI): Instead of a class creating its own dependencies (e.g., val api = new ApiClient()), the dependencies are provided to it (injected).
                1.2.a. Why it matters: It makes testing easier because you can inject "fake" data sources during tests.
                1.2.b. Tools: Hilt/Dagger (Android)
            1.3. Modularization: Breaking the app into distinct sub-projects (modules).
                1.3.a. Isolation: Changes in the "Payment Module" won't accidentally break the "Chat Module".
                1.3.b. Build Speed: The compiler only rebuilds the module you changed, not the whole app, drastically reducing wait times.

    2. Code Hygiene Principles (How code is read)
        Code is read 10x more often than it is written. Good DX prioritizes readability.
        2.1. Linting and Formatting: Enfore a standard style guide automatically.
            2.1.a. Tools: Ktlint (Kotlin), SwiftLine (Swift).
            2.1.b. Principle: The code should look like it was written by a single person, even if 10 people worked on it. No arguments about tabs vs. spaces.
        2.2. Self-Documenting Code:
            Naming variables and functions so clearly that comments are unnecessary.
                - Bad: fun cal(g: Int)
                - Good: fun calculateAdmissionProbability(grade: Int)
        2.3. Boy Scrout Rule:
            "Always leave the campground cleaner than you found it." If you touch a file to add a feature, and you see messy code nearby, fix the messy code too.
    
### Backend and API Principles ###
    1. Scalability and Load Balancing:
        Design the backend to be stateless (not storing user session data on the server) so that load balancers can distribute traffic across numerous server instances as your user base grows.
    
    2. API Idempotency:
        Ensure that repeated identical requests (e.g., a user double-tapping a "Submit Payment" due tp network lag) have the exact same effect as a single request, preventing duplicate transactions.
    
    3. Rate Limiting: Implement strict controls on the number of requests a single user or device can make within a time frame to prevent abuser and denial-of-service attacks.

### Database Principles ###
    1. Data Modelling for Access:
        Choose a data model (Relational SQL) that directly supports the mobile app's access patterns, prioritizing reading speed over writing complexity if necessary.

    2. Indexing Strategy:
        Properly index database columns that are frequently used in search queries, sorting, or WHERE clauses to ensure fast API response times.

    3. Transaction Integrity (ACID):
        Apply the database mechanisms to guarantee that transactional data (like user profiles or payment records) remains Atomic, Consistent, Isolated, and Durable.

### Comprehensive Security Principles ###
Security must be implemented at every layer, not just the front door.
    1. Threat Modelling:
        Systematically identify potential security risks unique to your application's logic and design solutions to mitigate them before writing the code.
    
    2. Input Validation and Sanitization:
        This must be performed on the backend, not just the frontend, to prevent attacks like SQL Injection or Cross-Site Scripting (XSS) that could compromise your database.

    3. Authentication and Authorization (AuthN/AuthZ):
        Use modern standards (like OAuth 2.0 or JWT) to verify user identity (AuthN) and then strictly enforce what the user is allowed to do (AuthZ) on every single API endpoint.

    4. Data Encryption in Transit and at Rest:
        Ensure data is encrypted via HTTPS/TLS when travelling between the app and the server, and encrypted when stored on the server's disk ("at rest").