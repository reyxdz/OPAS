# 🏗️ OPAS Root Folder - Clean Architecture Visual Map

**Date**: November 22, 2025  
**Format**: Visual organization diagrams

---

## 📊 COMPLETE FOLDER STRUCTURE (Clean Architecture View)

```
ROOT FOLDER: OPAS_Application
│
├─── 📚 DOCUMENTATION (Project Level)
│    ├─ README.md                              [Main Entry Point]
│    ├─ START_HERE.md                          [Quick Start Guide]
│    ├─ CORE_PRINCIPLES.md                     [Architecture Principles]
│    ├─ TASK_BREAKDOWN.md                      [Current Tasks]
│    └─ (24 more docs)                         [See ROOT_FOLDER_ANALYSIS.md]
│
├─── 🚀 APPLICATION SYSTEMS
│    │
│    ├─ OPAS_Django/                           [BACKEND - Django REST API]
│    │  │
│    │  ├─ 📦 DOMAIN LAYER (entities/)
│    │  │  ├─ apps/users/
│    │  │  │  ├─ models.py               ← User Entity
│    │  │  │  ├─ admin_models.py         ← Admin Entities
│    │  │  │  ├─ enums.py                ← Value Objects
│    │  │  │  └─ forecasting_algorithm.py ← Business Logic
│    │  │  └─ apps/(other)/models.py     ← Domain Models
│    │  │
│    │  ├─ 🔗 INTERFACE ADAPTER LAYER
│    │  │  ├─ apps/users/
│    │  │  │  ├─ admin_serializers.py    ← DTO Adapters
│    │  │  │  ├─ admin_viewsets.py       ← HTTP Controllers
│    │  │  │  ├─ admin_permissions.py    ← Security Adapter
│    │  │  │  ├─ admin_urls.py           ← Route Adapter
│    │  │  │  ├─ managers.py             ← Repository Pattern
│    │  │  │  └─ admin_views.py          ← View Adapter
│    │  │  └─ apps/(other)/[similar structure]
│    │  │
│    │  ├─ 🔧 APPLICATION LAYER (use cases)
│    │  │  ├─ apps/users/
│    │  │  │  ├─ admin_viewsets.py       ← Use Case Orchestration
│    │  │  │  ├─ sellers_views.py        ← Seller Use Cases
│    │  │  │  └─ views.py                ← Other Use Cases
│    │  │  └─ apps/core/                 ← Core Application Logic
│    │  │
│    │  ├─ ⚙️ FRAMEWORK LAYER
│    │  │  ├─ settings.py                ← Django Config
│    │  │  ├─ wsgi.py                    ← WSGI Server
│    │  │  ├─ asgi.py                    ← ASGI Server
│    │  │  ├─ manage.py                  ← CLI
│    │  │  ├─ urls.py                    ← URL Routing
│    │  │  ├─ requirements.txt            ← Dependencies
│    │  │  ├─ migrations/                ← Database Migrations
│    │  │  ├─ media/                     ← File Storage
│    │  │  └─ tests/                     ← Test Suite
│    │  │
│    │  └─ apps/                         ← Application Modules
│    │     ├─ users/                     [User Management Module]
│    │     ├─ products/                  [Product Management Module]
│    │     ├─ orders/                    [Order Management Module]
│    │     └─ ...
│    │
│    ├─ OPAS_Flutter/                           [FRONTEND - Mobile UI]
│    │  │
│    │  ├─ 🎨 PRESENTATION LAYER
│    │  │  ├─ lib/
│    │  │  │  ├─ ui/                     ← UI Screens/Widgets
│    │  │  │  ├─ widgets/                ← Reusable Components
│    │  │  │  ├─ screens/                ← Screen Pages
│    │  │  │  └─ pages/                  ← Page Navigation
│    │  │  │
│    │  │  ├─ 🔗 INTERFACE ADAPTERS
│    │  │  │  ├─ lib/providers/          ← Provider State Adapters
│    │  │  │  └─ lib/services/           ← API Service Adapters
│    │  │  │
│    │  │  ├─ 🔧 APPLICATION LOGIC
│    │  │  │  ├─ lib/providers/          ← State Management
│    │  │  │  ├─ lib/models/             ← Data Models
│    │  │  │  └─ lib/services/           ← Business Logic
│    │  │  │
│    │  │  └─ ⚙️ FRAMEWORKS
│    │  │     ├─ pubspec.yaml            ← Dependencies
│    │  │     ├─ android/                ← Android Native
│    │  │     ├─ ios/                    ← iOS Native
│    │  │     └─ web/                    ← Web Platform
│    │  │
│    │  ├─ test/                         ← Test Suite
│    │  └─ analysis_options.yaml         ← Lint Config
│    │
│    └─ Documentations/                         [PROJECT DOCUMENTATION]
│       ├─ OPAS_Admin/                   [Admin Panel Docs]
│       │  ├─ ADMIN_API_REFERENCE.md
│       │  ├─ ADMIN_IMPLEMENTATION_PLAN_DONE.md
│       │  ├─ ADMIN_PANEL_STRUCTURE.md
│       │  └─ ...
│       ├─ Sellers/                      [Seller Module Docs]
│       └─ ...
│
├─── 🧪 TEST & UTILITY SCRIPTS
│    ├─ test_endpoint.py                 [API Test]
│    ├─ test_image_display.py            [Image Test]
│    ├─ test_notification_endpoints.py   [Notification Test]
│    ├─ test_seller_api.py               [Seller Test]
│    ├─ check_product_images.py          [Utility]
│    ├─ fix_seller_final.py              [Utility]
│    ├─ fix_seller_service.py            [Utility]
│    └─ fix_seller_service_v2.py         [Utility]
│
└─── ⚙️ INFRASTRUCTURE
     ├─ .git/                            [Version Control]
     ├─ .venv/                           [Python Environment]
     └─ .vscode/                         [IDE Configuration]
```

---

## 🎯 CLEAN ARCHITECTURE LAYERS VISUALIZATION

```
┌──────────────────────────────────────────────────────────────┐
│                                                                │
│              🎯 PRESENTATION LAYER (Outermost)                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  OPAS_Flutter/  │  test_*.py  │  README.md (UI Layer)  │  │
│  └────────────────────────────────────────────────────────┘  │
│                              ↓                                 │
│              🔧 APPLICATION LAYER (Use Cases)                 │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Orchestration of business workflows                   │  │
│  │  - Seller approval workflows                           │  │
│  │  - Price management use cases                          │  │
│  │  - OPAS bulk purchase use cases                        │  │
│  │  - Analytics and reporting use cases                   │  │
│  └────────────────────────────────────────────────────────┘  │
│                              ↓                                 │
│         🔗 INTERFACE ADAPTER LAYER (Controllers)              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Serializers (DTO Converters)                          │  │
│  │  ViewSets (HTTP Controllers)                           │  │
│  │  Managers (Repository Pattern)                         │  │
│  │  URLs (Route Adapters)                                 │  │
│  │  Permissions (Security Adapters)                       │  │
│  └────────────────────────────────────────────────────────┘  │
│                              ↓                                 │
│         📦 ENTITIES/DOMAIN LAYER (Business Rules)             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  User Entity          │  Order Entity                  │  │
│  │  AdminUser Entity     │  Product Entity                │  │
│  │  Seller Entity        │  Notification Entity           │  │
│  │  Value Objects (Enums, Choices)                        │  │
│  │  Business Rules & Validation                           │  │
│  └────────────────────────────────────────────────────────┘  │
│                              ↓                                 │
│    ⚙️ FRAMEWORKS & DRIVERS LAYER (Innermost)                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Django ORM  │  REST Framework  │  Database            │  │
│  │  Migrations  │  External APIs   │  File Storage        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## 📂 DJANGO APP LAYER STRUCTURE (Detailed View)

```
OPAS_Django/apps/users/
│
├─── 📦 DOMAIN LAYER
│    ├─ models.py
│    │  ├─ User (Base user entity)
│    │  └─ SellerStatus, UserRole (Value objects)
│    │
│    ├─ admin_models.py
│    │  ├─ AdminUser (Admin entity)
│    │  ├─ SellerRegistrationRequest (Workflow entity)
│    │  ├─ PriceCeiling (Price entity)
│    │  ├─ OPASPurchaseOrder (OPAS entity)
│    │  └─ AdminAuditLog (Audit entity)
│    │
│    ├─ enums.py
│    │  ├─ AdminRole (Value object)
│    │  ├─ SellerRegistrationStatus (Value object)
│    │  └─ ... (other enums)
│    │
│    └─ forecasting_algorithm.py
│       └─ Business logic & algorithms
│
├─── 🔗 INTERFACE ADAPTER LAYER
│    ├─ admin_serializers.py
│    │  ├─ SellerManagementSerializer (Input/Output DTO)
│    │  ├─ PriceCeilingSerializer (Input/Output DTO)
│    │  └─ ... (other DTOs)
│    │
│    ├─ admin_viewsets.py
│    │  ├─ SellerManagementViewSet (HTTP Controller)
│    │  ├─ PriceManagementViewSet (HTTP Controller)
│    │  └─ ... (other controllers)
│    │
│    ├─ admin_permissions.py
│    │  ├─ IsAdmin (Security adapter)
│    │  ├─ CanApproveSellers (Security adapter)
│    │  └─ ... (other permissions)
│    │
│    ├─ admin_urls.py
│    │  └─ URL routing configuration
│    │
│    ├─ managers.py
│    │  └─ Repository pattern implementations
│    │
│    └─ admin_views.py
│       └─ View adapters
│
├─── 🔧 APPLICATION LAYER
│    └─ ViewSet actions (orchestration)
│       ├─ approve_seller()
│       ├─ set_price_ceiling()
│       ├─ approve_opas_submission()
│       └─ ... (other use cases)
│
└─── ⚙️ FRAMEWORK LAYER
     └─ migrations/
        ├─ 0001_initial.py
        ├─ 0010_adminauditlog_adminuser_...py
        └─ ... (database migrations)
```

---

## 🎯 FILE CATEGORIZATION MATRIX

```
┌─────────────────────┬──────────────────┬─────────────────┐
│ CLEAN ARCHITECTURE  │ FILE LOCATION    │ COUNT           │
├─────────────────────┼──────────────────┼─────────────────┤
│ Presentation        │ OPAS_Flutter/    │ 1 system        │
│ Layer               │ test_*.py        │ 4 test files    │
│                     │ README.md        │ 1 entry point   │
├─────────────────────┼──────────────────┼─────────────────┤
│ Application         │ */views.py       │ Multiple        │
│ Layer               │ */viewsets.py    │ Per app         │
│ (Use Cases)         │ Documentations/  │ 26 docs         │
├─────────────────────┼──────────────────┼─────────────────┤
│ Interface           │ */serializers.py │ Multiple        │
│ Adapter             │ */urls.py        │ Per app         │
│ Layer               │ */permissions.py │ Per app         │
│                     │ */managers.py    │ Per app         │
├─────────────────────┼──────────────────┼─────────────────┤
│ Domain/Entity       │ */models.py      │ Per app         │
│ Layer               │ */enums.py       │ Per app         │
│                     │ */algorithms.py  │ Per app         │
├─────────────────────┼──────────────────┼─────────────────┤
│ Framework/          │ OPAS_Django/     │ 1 backend       │
│ Drivers Layer       │ settings.py      │ 1 config        │
│                     │ migrations/      │ 10 migrations   │
│                     │ media/           │ 1 storage       │
│                     │ requirements.txt │ 1 dependency    │
└─────────────────────┴──────────────────┴─────────────────┘
```

---

## 📊 FILE COUNT BY CATEGORY

```
Documentation Files
┌─────────────────────────────────────────────┐
│  26 files (~60%)                            │
│  ████████████████████████████████████████   │
└─────────────────────────────────────────────┘

Application Systems
┌─────────────────────────────────────────────┐
│  3 systems (~7%)                            │
│ ███                                         │
└─────────────────────────────────────────────┘

Test & Utility Scripts
┌─────────────────────────────────────────────┐
│  8 files (~18%)                             │
│ ██████████████                              │
└─────────────────────────────────────────────┘

Infrastructure
┌─────────────────────────────────────────────┐
│  3 items (~7%)                              │
│ ███                                         │
└─────────────────────────────────────────────┘

TOTAL: 44 files/folders
```

---

## ✅ LAYER RESPONSIBILITY MATRIX

```
LAYER                   RESPONSIBILITY                   TESTABILITY
──────────────────────────────────────────────────────────────────────
Presentation            User interface &                 ✅ Mock API
                        user interactions                   

Application            Business workflows &              ✅ Mock Domain
                        orchestration                        

Interface Adapter       Data conversion &                 ✅ Test both
                        framework binding                    directions

Domain/Entities         Business rules &                  ✅ Pure logic
                        core logic                           

Framework/Drivers       Technology stack &                ✅ Integration
                        external dependencies               tests
```

---

## 🎯 DEPENDENCY FLOW (Correct Direction)

```
                    ┌─────────────────────┐
                    │  PRESENTATION LAYER │
                    │  (Flutter, Tests)   │
                    └──────────────┬──────┘
                                   ↓
                    ┌─────────────────────┐
                    │ APPLICATION LAYER   │
                    │ (Use Cases, Logic)  │
                    └──────────────┬──────┘
                                   ↓
                    ┌─────────────────────┐
                    │ INTERFACE ADAPTERS  │
                    │ (Controllers, DTOs) │
                    └──────────────┬──────┘
                                   ↓
                    ┌─────────────────────┐
                    │ DOMAIN/ENTITIES     │
                    │ (Business Rules)    │
                    └──────────────┬──────┘
                                   ↓
                    ┌─────────────────────┐
                    │ FRAMEWORKS/DRIVERS  │
                    │ (Django, Database)  │
                    └─────────────────────┘

✅ CORRECT: Dependencies point INWARD
❌ WRONG: Dependencies should NOT point outward
```

---

## 📌 KEY INSIGHTS

### **Well Implemented**
✅ Clear separation of backends (Django) and frontends (Flutter)  
✅ Comprehensive documentation at each layer  
✅ Models follow domain-driven design  
✅ ViewSets implement use case layer  
✅ Serializers act as adapters  
✅ Permissions handle security concerns  

### **Areas to Improve**
🟡 Test scripts scattered at root (move to OPAS_Django/tests/)  
🟡 Utility scripts at root (move to OPAS_Django/utils/)  
🟡 Documentation could be organized in Documentations/  
🟡 No explicit ARCHITECTURE.md explaining clean architecture  

### **Best Practices Observed**
✅ Enums for value objects  
✅ Models with help_text (self-documenting)  
✅ Serializers for DTO pattern  
✅ ViewSet actions for use cases  
✅ Multiple testing files  
✅ Phase-based delivery tracking  

---

**Analysis Date**: November 22, 2025  
**Architecture Pattern**: Clean Architecture ✅  
**Implementation Quality**: 8/10  
**Recommendation**: Reorganize root folder for better clarity
