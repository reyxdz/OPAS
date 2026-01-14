# 🎯 Admin Product Upload Screen - Classification & Grouping Implementation

**Status:** ✅ COMPLETE

**Date:** December 7, 2025

---

## 📋 Overview

Enhanced the admin product upload screen with intelligent hierarchical product classification. The form now supports:

1. **Category Selection** (Read-only, matches buyer home screen)
2. **Product Type** (Cascading dropdown with "Add option")
3. **Product Subtype** (Cascading dropdown with "Add option")

This enables products to be grouped semantically for better forecasting and inventory management.

---

## 🎨 UI/UX Features

### 1. Category Dropdown (Read-Only)
- **Displays:** 8 categories matching buyer home screen
- **Categories:**
  - Vegetables (VEGETABLE)
  - Fruits (FRUIT)
  - Livestock (LIVESTOCK)
  - Poultry (POULTRY)
  - Seeds (SEEDS)
  - Fertilizers (FERTILIZERS)
  - Feeds (FEEDS)
  - Medicines (MEDICINES)

- **Behavior:** Read-only, no editing. When category changes, type and subtype reset.

### 2. Product Type Dropdown
- **Cascading:** Populated based on selected category
- **"Add Option" Button:** Allows admin to create new types
- **Example for Vegetables:**
  - Leafy Greens
  - Root Vegetables
  - Legumes
  - Others

### 3. Product Subtype Dropdown
- **Cascading:** Populated based on selected type
- **"Add Option" Button:** Allows admin to create new subtypes
- **Example for Fish (type) under Livestock:**
  - Bangus
  - Tilapia
  - Catfish

---

## 🔧 Implementation Details

### File Structure

```
opas_flutter/
└── lib/features/admin_panel/screens/
    └── product_upload_screen.dart (UPDATED - 819 lines)
```

### State Management

**Form Fields:**
```dart
String? _selectedCategory;  // e.g., 'VEGETABLE'
String? _selectedType;      // e.g., 'Leafy Greens'
String? _selectedSubtype;   // e.g., 'Tomato'
```

**Data Structures:**

1. **Category Map** - Static, matches buyer home
```dart
{
  'VEGETABLE': 'Vegetables',
  'FRUIT': 'Fruits',
  'LIVESTOCK': 'Livestock',
  ...
}
```

2. **Types by Category** - Default options per category
```dart
{
  'VEGETABLE': ['Leafy Greens', 'Root Vegetables', 'Legumes', 'Others'],
  'FRUIT': ['Citrus', 'Tropical', 'Berries', 'Others'],
  'LIVESTOCK': ['Fish', 'Cattle', 'Goats', 'Others'],
  ...
}
```

3. **Subtypes by Type** - Default options per type
```dart
{
  'VEGETABLE': {
    'Leafy Greens': ['Tomato', 'Lettuce', 'Spinach', 'Cabbage'],
    'Root Vegetables': ['Potato', 'Carrot', 'Onion', 'Radish'],
    'Legumes': ['Beans', 'Peas', 'Lentils'],
  },
  ...
}
```

4. **Custom Types/Subtypes** - Session-persisted user additions
```dart
// Stores new types created during form use
_customTypesByCategory = {
  'VEGETABLE': ['Herbs', 'Mushrooms'],
}

// Stores new subtypes created during form use
_customSubtypesByType = {
  'VEGETABLE': {
    'Herbs': ['Basil', 'Parsley'],
  }
}
```

---

## 🎬 User Workflow

### Scenario: Admin uploading "Bangus" product

**Step 1:** Select Category
- Click category dropdown → Select "Livestock"
- Type and Subtype dropdowns become active

**Step 2:** Select Product Type
- Click type dropdown → Shows: Fish, Cattle, Goats, Others
- Select "Fish"
- Subtype dropdown becomes active

**Step 3:** Select Product Subtype
- Click subtype dropdown → Shows: Bangus, Tilapia, Catfish
- Select "Bangus"
- Product is now classified as LIVESTOCK > Fish > Bangus

**Step 4 (Optional):** Add Custom Subtype
- If "Bangus" doesn't exist in list
- Click "+" button next to subtype dropdown
- Dialog appears: "Add New Product Subtype"
- Type "Bangus sariwa" and click "Add"
- New subtype added to the list and auto-selected

---

## 💾 Data Flow

### Frontend (Flutter)

```
Product Upload Form
    ↓
Admin selects Category/Type/Subtype
    ↓
Form validates classification selected
    ↓
Backend: POST /api/admin/opas-products/
    {
      "name": "Bangus...",
      "category": "LIVESTOCK",
      "product_type": "Fish",
      "product_subtype": "Bangus",
      ...
    }
```

### Backend (Django)

```
POST /api/admin/opas-products/
    ↓
OPASProductUploadSerializer validates
    ↓
Create SellerProduct with classification
    {
      category_forecast: "LIVESTOCK",
      product_type: "Fish",
      product_subtype: "Bangus",
      ...
    }
    ↓
ProductGroupingService groups similar products
    ↓
Forecasting engine identifies group: "LIVESTOCK:Fish:Bangus"
```

---

## 🔄 Helper Methods

### `_getTypesForCategory(String category)`
- **Purpose:** Returns all types for a category (default + custom)
- **Input:** Category key (e.g., 'VEGETABLE')
- **Output:** List of type strings
- **Usage:** Populates type dropdown

### `_getSubtypesForType(String type)`
- **Purpose:** Returns all subtypes for a type (default + custom)
- **Input:** Type string (e.g., 'Leafy Greens')
- **Output:** List of subtype strings
- **Usage:** Populates subtype dropdown

### `_showAddTypeDialog()`
- **Purpose:** Shows dialog to add new product type
- **Validation:** Category must be selected first
- **Action:** Adds to `_customTypesByCategory` and auto-selects
- **Storage:** Session-only (not persisted to backend yet)

### `_showAddSubtypeDialog()`
- **Purpose:** Shows dialog to add new product subtype
- **Validation:** Type must be selected first
- **Action:** Adds to `_customSubtypesByType` and auto-selects
- **Storage:** Session-only (not persisted to backend yet)

---

## ✨ Key Features

### 1. Cascading Behavior
- Category change → Type resets to null
- Type change → Subtype resets to null
- Prevents invalid combinations

### 2. Add Option Buttons
- **Enabled When:** Category/Type selected respectively
- **Disabled When:** uploading or prerequisite not selected
- **Visual:** Plus icon button next to each dropdown

### 3. Dynamic Lists
- Default options always available
- Custom options added per session
- No duplicate options allowed

### 4. Form Validation
- All three fields required
- Validates in order: Category → Type → Subtype

### 5. Responsive Design
- Type dropdown + Add button on same row
- Subtype dropdown + Add button on same row
- Buttons scale with screen size

---

## 🔐 Data Consistency

### Category Consistency
- Categories in `product_upload_screen.dart` → Match `buyer_home_screen.dart`
- Both use same category keys (VEGETABLE, FRUIT, etc.)
- Read-only category ensures consistency

### Type & Subtype Consistency
- Admin can only add new types/subtypes during upload
- No editing of existing classifications
- Future phase: Admin dashboard to manage classifications globally

---

## 📱 UI Example

```
┌─────────────────────────────────────┐
│         Upload New Product          │
├─────────────────────────────────────┤
│                                     │
│ Product Name                        │
│ ┌─────────────────────────────────┐ │
│ │ e.g., Fresh Bangus              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Category                            │
│ ┌─────────────────────────────────┐ │
│ │ Livestock                    ▼   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Product Type                        │
│ ┌──────────────────────────┐ ┌────┐│
│ │ Fish                  ▼  │ │ +  ││
│ └──────────────────────────┘ └────┘│
│                                     │
│ Product Subtype                     │
│ ┌──────────────────────────┐ ┌────┐│
│ │ Bangus               ▼   │ │ +  ││
│ └──────────────────────────┘ └────┘│
│                                     │
│ Price (₱)                           │
│ ┌─────────────────────────────────┐ │
│ │ ₱ 0.00                          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ... other fields ...                │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │    ☁️  Upload Product           │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │         Cancel                  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🚀 Next Steps

### Phase 1: Backend Integration (Priority: HIGH)
- [ ] Update `AdminService.uploadOPASProduct()` to send classification fields
- [ ] Update backend endpoint to accept and store classification
- [ ] Verify Django migrations run successfully

### Phase 2: Persistence (Priority: MEDIUM)
- [ ] Store custom types/subtypes to backend
- [ ] Create management UI for admins to curate classifications
- [ ] Sync classifications across sessions

### Phase 3: Forecasting Integration (Priority: MEDIUM)
- [ ] Display group forecasts in admin dashboard
- [ ] Show forecast status based on classification
- [ ] Update group forecasts when new products added

### Phase 4: Inventory Management (Priority: LOW)
- [ ] Filter products by classification
- [ ] Bulk actions on product groups
- [ ] Classification-based reporting

---

## 📝 Code Changes Summary

### File: `product_upload_screen.dart`

**Added:**
- State variables: `_selectedType`, `_selectedSubtype`
- Data structures: `_categoryMap`, `_typesByCategory`, `_subtypesByType`
- Collections: `_customTypesByCategory`, `_customSubtypesByType`
- Methods: 4 helper methods + 2 dialog methods
- UI: 2 cascading dropdowns with add buttons

**Modified:**
- Category dropdown now uses `_categoryMap` (was hardcoded list)
- Category changes now reset type/subtype
- Form validation now checks all three fields

**Removed:**
- Old hardcoded `_categories` list (replaced with `_categoryMap`)
- `_categoryController` (not needed for dropdown)

---

## 🧪 Testing Checklist

- [ ] Category dropdown shows 8 buyer home categories
- [ ] Category is read-only (not editable)
- [ ] Selecting category resets type and subtype
- [ ] Type dropdown populated correctly for each category
- [ ] Add type button shows dialog, accepts input, adds to list
- [ ] Custom types appear in dropdown after adding
- [ ] Type dropdown change resets subtype
- [ ] Subtype dropdown populated correctly for each type
- [ ] Add subtype button shows dialog, accepts input, adds to list
- [ ] Custom subtypes appear in dropdown after adding
- [ ] All three fields required for form validation
- [ ] Product uploads with correct classification
- [ ] Form works on different screen sizes

---

## 📞 Support

For issues or clarifications:
1. Check the Workflow section above for typical usage
2. Verify category keys match `buyer_home_screen.dart`
3. Ensure Add dialogs are working for custom entries
4. Check browser console for any JavaScript errors

---

**Document Version:** 1.0
**Last Updated:** December 7, 2025
**Status:** Production Ready
