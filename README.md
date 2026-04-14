# 🚀 OPAS: Order Processing & Approval System (Mobile)

<div align="center">

<!-- TODO: Add project logo (e.g., OPAS logo) -->

[![GitHub stars](https://img.shields.io/github/stars/reyxdz/OPAS?style=for-the-badge)](https://github.com/reyxdz/OPAS/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/reyxdz/OPAS?style=for-the-badge)](https://github.com/reyxdz/OPAS/network)
[![GitHub issues](https://img.shields.io/github/issues/reyxdz/OPAS?style=for-the-badge)](https://github.com/reyxdz/OPAS/issues)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE) <!-- TODO: Verify and update license type -->

**A robust mobile application and backend system designed for streamlined Order Processing and Approval.**

<!-- TODO: Add live demo link if available -->
[Live Demo](https://opas-biliran.web.app/)

</div>

## 📖 Overview

OPAS (Online Platform for Agricultural Services) is a comprehensive solution comprising a cross-platform mobile application built with Flutter and a powerful backend API developed using Django. The system is engineered to facilitate efficient management of products, orders, and organizational workflows, enabling users to create, track, and approve orders, while ensuring robust data integrity and user-specific notifications.

This repository represents a multi-phase development effort, focusing on critical features like user management, product lifecycle, order processing with integrated stock management, and a sophisticated notification system, all underpinned by a secure and performant API.

## ✨ Features

-   🎯 **User Authentication & Management**: Secure user registration, login, and profile management with robust API handling.
-   📦 **Product Management**: Comprehensive system for managing products, including creation, updates, and deletion protection to prevent data loss.
-   🛒 **Order Processing**: End-to-end order lifecycle management, from creation to approval, including:
    -   Detailed order creation with multiple items.
    -   Integration with stock management to track inventory levels dynamically.
    -   Buyer-specific API functionalities for enhanced user experience.
-   🔔 **Real-time Notification System**: Cross-user notifications with read state management to keep users informed about important events and order updates.
-   🏛️ **Organization & Role Management**: Structure for managing organizations and assigning roles, likely supporting multi-tenancy or hierarchical approvals.
-   ⚡ **Performance Optimizations**: Engineered for speed and efficiency, addressing potential bottlenecks in critical workflows like approval processes.
-   📈 **Comprehensive API**: A well-documented and robust API backend serving the mobile application, ensuring reliable data exchange.

## 🖥️ Screenshots

<!-- TODO: Add actual screenshots of the mobile application and potentially key backend admin panels -->
<!-- ![Screenshot 1](path-to-mobile-screenshot-1.png) -->
<!-- ![Screenshot 2](path-to-mobile-screenshot-2.png) -->
<!-- ![Screenshot 3](path-to-mobile-screenshot-3.png) -->

## 🛠️ Tech Stack

**Mobile Frontend:**
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)

**Backend API:**
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Django](https://img.shields.io/badge/Django-092E20?style=for-the-badge&logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Django REST Framework](https://img.shields.io/badge/DRF-darkgreen?style=for-the-badge&logo=django&logoColor=white)](https://www.django-rest-framework.org/)

**Database:**
<!-- Assumed from Django default/common practices. Update if different DB is used. -->
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
<!-- Or if using SQLite for development: [![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/index.html) -->

## 🚀 Quick Start

To get OPAS up and running, you'll need to set up both the Django backend and the Flutter mobile application.

### Prerequisites

-   **Flutter SDK**: [Installation Guide](https://flutter.dev/docs/get-started/install)
-   **Python 3.8+**: [Installation Guide](https://www.python.org/downloads/)
-   **pip**: Python package installer (usually comes with Python)
-   **A PostgreSQL database**: (Or other database configured in Django settings)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/reyxdz/OPAS.git
    cd OPAS
    ```

2.  **Backend Setup (OPAS_Django)**

    a.  **Navigate to the backend directory**
        ```bash
        cd OPAS_Django
        ```

    b.  **Create a Python virtual environment** (recommended)
        ```bash
        python -m venv venv
        # On Windows
        .\venv\Scripts\activate
        # On macOS/Linux
        source venv/bin/activate
        ```

    c.  **Install Python dependencies**
        ```bash
        pip install -r requirements.txt # TODO: Confirm requirements.txt exists in OPAS_Django/
        ```

    d.  **Environment setup**
        Create a `.env` file in the `OPAS_Django` directory by copying `.env.example` (if available) or creating a new one.
        ```bash
        cp .env.example .env # TODO: Check if .env.example exists
        ```
        Configure your environment variables, including database connection strings, secret keys, etc.
        ```ini
        # .env example
        SECRET_KEY='your_secret_key'
        DEBUG=True
        DATABASE_URL='postgres://user:password@host:port/database_name' # Example for PostgreSQL
        # ... other Django settings like ALLOWED_HOSTS, etc.
        ```

    e.  **Database setup**
        Apply database migrations:
        ```bash
        python manage.py migrate
        ```
        (Optional) Create a superuser for admin access:
        ```bash
        python manage.py createsuperuser
        ```

    f.  **Start the Django development server**
        ```bash
        python manage.py runserver
        ```
        The backend API will typically run on `http://localhost:8000`.
        A `run_server.bat` script is also provided for Windows users:
        ```bash
        .\run_server.bat
        ```

3.  **Mobile App Setup (OPAS_Flutter)**

    a.  **Navigate to the mobile app directory**
        ```bash
        cd ../OPAS_Flutter
        ```

    b.  **Install Flutter dependencies**
        ```bash
        flutter pub get
        ```

    c.  **Firebase configuration**
        Place your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files in the appropriate platform directories (`android/app/` and `ios/Runner/` respectively). Ensure your Flutter project is connected to your Firebase project.

    d.  **Configure API endpoint**
        You might need to update the API endpoint URL in the Flutter application's source code (e.g., in a `lib/config.dart` or similar file) to point to your running Django backend (e.g., `http://10.0.2.2:8000` for Android emulator or `http://localhost:8000` for web/iOS simulator).

    e.  **Run the Flutter application**
        Connect a device or start an emulator/simulator, then run:
        ```bash
        flutter run
        ```
        This will launch the OPAS mobile application.

## 📁 Project Structure

```
OPAS/
├── .github/                       # GitHub Actions workflows or project settings
├── .vscode/                       # VS Code editor settings
├── Documentations/                # Project specific documentation and reports
├── OPAS_Django/                   # Django Backend API
│   ├── <project_name>/            # Django project settings and root URLs
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── <app_name>/                # Django application(s) (e.g., users, products, orders, notifications)
│   │   ├── migrations/
│   │   ├── models.py
│   │   ├── admin.py
│   │   ├── views.py
│   │   ├── serializers.py         # For Django REST Framework
│   │   └── urls.py
│   ├── media/                     # User-uploaded files
│   ├── static/                    # Static assets
│   ├── venv/                      # Python virtual environment (ignored by Git)
│   ├── manage.py                  # Django's command-line utility
│   └── requirements.txt           # Python dependencies
├── OPAS_Flutter/                  # Flutter Mobile Application
│   ├── android/                   # Android-specific project files
│   ├── ios/                       # iOS-specific project files
│   ├── lib/                       # Dart source code
│   │   ├── api/                   # API service integration
│   │   ├── auth/                  # Authentication related files
│   │   ├── components/            # Reusable UI widgets
│   │   ├── models/                # Data models
│   │   ├── screens/               # Application screens/pages
│   │   ├── services/              # Business logic/external services
│   │   ├── utils/                 # Utility functions
│   │   └── main.dart              # Main entry point for the Flutter app
│   ├── assets/                    # Static assets (images, fonts)
│   ├── pubspec.yaml               # Dart/Flutter project dependencies and metadata
│   ├── pubspec.lock               # Generated lock file for dependencies
│   └── test/                      # Flutter unit and widget tests
├── google-services.json           # Firebase configuration for Android (at root for convenience, often in android/app)
├── run_server.bat                 # Windows batch script to run Django server
├── IMPLEMENTATION_COMPLETE.md     # Internal development reports/summaries
├── IMPLEMENTATION_SUMMARY.md
├── NOTIFICATION_CROSS_USER_FIX.md
├── ... (other markdown development reports)
└── README.md                      # This README file
```

## ⚙️ Configuration

### Environment Variables (Backend - OPAS_Django)
The Django backend relies on environment variables for sensitive information and configuration. A `.env` file should be created in the `OPAS_Django` directory.

| Variable          | Description                                    | Default        | Required |
|-------------------|------------------------------------------------|----------------|----------|
| `SECRET_KEY`      | Django secret key for cryptographic signing.   | (Generated)    | Yes      |
| `DEBUG`           | Boolean, enables/disables debug mode.          | `False`        | Yes      |
| `DATABASE_URL`    | Connection string for the database (e.g., PostgreSQL). | (None)         | Yes      |
| `ALLOWED_HOSTS`   | Comma-separated list of hosts allowed to serve this Django project. | `localhost,127.0.0.1` | Yes      |
| `FRONTEND_URL`    | URL of the mobile application/frontend.        | (None)         | No       |
| `EMAIL_HOST`      | SMTP host for email sending.                   | (None)         | No       |
| `EMAIL_PORT`      | SMTP port for email sending.                   | (None)         | No       |
| `EMAIL_HOST_USER` | SMTP username.                                 | (None)         | No       |
| `EMAIL_HOST_PASSWORD` | SMTP password.                             | (None)         | No       |

### Firebase Configuration (Mobile - OPAS_Flutter)
The mobile application uses Firebase for various services (e.g., authentication, notifications).
-   `google-services.json`: For Android, placed in `android/app/`. (A copy exists at the root, move it to `android/app` for local development).
-   `GoogleService-Info.plist`: For iOS, placed in `ios/Runner/`.

## 🔧 Development

### Available Scripts

**For the Django Backend (in `OPAS_Django` directory):**

| Command                        | Description                                     |
|--------------------------------|-------------------------------------------------|
| `python manage.py runserver`   | Starts the Django development server.           |
| `python manage.py makemigrations` | Creates new database migrations based on model changes. |
| `python manage.py migrate`     | Applies pending database migrations.            |
| `python manage.py createsuperuser` | Creates an administrative user.               |
| `python manage.py test`        | Runs all tests for the Django project.          |
| `.\run_server.bat`             | (Windows) Starts the Django development server. |

**For the Flutter Mobile App (in `OPAS_Flutter` directory):**

| Command         | Description                                     |
|-----------------|-------------------------------------------------|
| `flutter run`   | Runs the application on a connected device or emulator. |
| `flutter run --release` | Builds and runs the application in release mode. |
| `flutter build apk` | Builds an Android APK file for release.         |
| `flutter build ios` | Builds an iOS application bundle.               |
| `flutter pub get` | Fetches all the dependencies for the project.   |
| `flutter test`  | Runs unit and widget tests for the Flutter app. |

### Development Workflow

1.  **Start the Backend**: Navigate to `OPAS_Django` and run `python manage.py runserver`.
2.  **Start the Frontend**: Navigate to `OPAS_Flutter` and run `flutter run`.
3.  **Code Changes**: Make changes to either the Django or Flutter codebase.
    *   For Django, changes are typically hot-reloaded or require a server restart for certain configuration updates.
    *   For Flutter, hot reload (`r`) or hot restart (`R`) can be used to see changes instantly.

## 🧪 Testing

### Backend Testing (OPAS_Django)
The Django project can be tested using its built-in testing framework.
```bash
# Navigate to the OPAS_Django directory
cd OPAS_Django
# Run all tests
python manage.py test
```
The presence of `ORDER_CREATION_INTEGRATION_TEST.md` suggests a focus on integration testing, ensuring the different components of the API work together seamlessly.

### Mobile App Testing (OPAS_Flutter)
The Flutter application supports unit, widget, and integration testing.
```bash
# Navigate to the OPAS_Flutter directory
cd OPAS_Flutter
# Run all Flutter tests
flutter test
```

## 🚀 Deployment

### Backend Deployment
The Django backend can be deployed to various cloud providers or on-premises servers.
-   **Heroku, AWS Elastic Beanstalk, Google Cloud App Engine**: These platforms offer managed Python/Django environments.
-   **Docker**: Create a `Dockerfile` for containerization and deploy to container orchestration services like Kubernetes or AWS ECS. (No Dockerfile detected currently).
-   **Manual Deployment**: Set up a WSGI server (Gunicorn, uWSGI) with Nginx/Apache.

### Mobile App Deployment
The Flutter application can be deployed to app stores:
-   **Android**: Build an APK or App Bundle (`flutter build apk` / `flutter build appbundle`) and upload to Google Play Console.
-   **iOS**: Build an iOS archive (`flutter build ipa`) and upload to Apple App Store Connect via Xcode.

## 📚 API Reference

The backend API is extensively documented. For detailed information on available endpoints, authentication methods, request/response formats, and data models, please refer to the dedicated API documentation report:

-   [PHASE_5_API_DOCUMENTATION_REPORT.md](https://github.com/reyxdz/OPAS/blob/main/PHASE_5_API_DOCUMENTATION_REPORT.md)

Key API areas covered include:
-   User Authentication and Authorization
-   Product Management APIs
-   Order Creation, Retrieval, Update, and Deletion
-   Notification Management
-   Organization and Role-based access APIs
-   Buyer-specific endpoints

## 🤝 Contributing

We welcome contributions to the OPAS project! To contribute, please follow these steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix (`git checkout -b feature/your-feature-name`).
3.  Make your changes and ensure they adhere to the project's coding standards.
4.  Write appropriate tests for your changes.
5.  Commit your changes (`git commit -m 'feat: Add new feature'`).
6.  Push to your fork (`git push origin feature/your-feature-name`).
7.  Open a Pull Request to the `main` branch of this repository.

Please refer to the existing internal documentation files (e.g., `IMPLEMENTATION_SUMMARY.md`) for insights into the project's development phases and design decisions.

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details. <!-- TODO: Verify or add LICENSE file -->

## 🙏 Acknowledgments

-   This project leverages the power of [Flutter](https://flutter.dev/) for an expressive and performant mobile UI.
-   The robust backend is built upon the solid foundations of [Django](https://www.djangoproject.com/) and [Django REST Framework](https://www.django-rest-framework.org/).
-   [Firebase](https://firebase.google.com/) provides essential services for mobile app development.
-   Special thanks to the various markdown documentation files within the repository for guiding the understanding of features and development phases.

## 📞 Support & Contact

-   📧 For general inquiries, please contact the repository owner ([reyxdz](https://github.com/reyxdz)). <!-- TODO: Add a specific contact email if available -->
-   🐛 For bug reports or feature requests, please open an issue on [GitHub Issues](https://github.com/reyxdz/OPAS/issues).

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with ❤️ by [reyxdz](https://github.com/reyxdz)

</div>
