# Selective Checkout Feature - Cart Screen Enhancement

## Overview
Implemented a comprehensive checklist feature for the cart screen that allows buyers to select specific items to checkout when there are many items in the cart.

## Feature Components

### 1. **Selection State Management**
- `_selectedProductIds`: `Set<String>` - Efficiently tracks which products are selected (O(1) lookup)
- `_isSelectionMode`: `bool` - Toggle between normal and selection mode

### 2. **Selection UI Elements**

#### Header Section
- **Selection Mode Toggle Button**: Checkbox icon in the header that toggles selection mode on/off
  - When OFF: Clears all selections and hides selection UI
  - When ON: Shows checkboxes on cart items and reveals selection controls
  - Visual feedback: Button highlights in green when active

#### Selection Control Buttons (only visible when in selection mode)
- **"Select All" Button**: Selects all items in the cart at once
- **"Clear" Button**: Deselects all items
- **Count Badge**: Shows "X selected" (e.g., "3 selected") when items are selected

### 3. **Cart Item Card Updates**

#### Conditional Checkbox Row
When `_isSelectionMode` is true, each cart item displays:
- Checkbox for toggling selection
- Status text: "Selected for checkout" (green) or "Not selected" (gray)

#### Visual Selection Feedback
- **Border**: Selected items show a green border (2px) instead of gray (1px)
- **Background**: Selected items have a light green background tint
- **Shadow**: Enhanced shadow for selected items

#### Tap-to-Select Behavior
- In selection mode: Tapping a card toggles its selection
- In normal mode: Tapping a card does nothing (no gesture handler active)

### 4. **Helper Methods**

```dart
/// Toggle individual item selection
void _toggleItemSelection(String productId)

/// Select all items in cart
void _selectAllItems()

/// Clear all selections
void _clearSelection()

/// Get list of selected items
List<CartItem> _getSelectedItems()

/// Get total of selected items (for future checkout use)
double _getSelectedTotal()
```

## Usage Flow

### For Buyer:
1. **Tap checkbox icon** in cart header to enable selection mode
2. **Tap items** to select/deselect them for checkout
3. **Use "Select All"** to quickly select everything
4. **Use "Clear"** to deselect everything
5. **Watch count badge** to see how many items are selected
6. **Tap checkbox icon again** to exit selection mode (auto-clears selections)

### For Developer:
The selection feature is now ready for the checkout flow:
- Call `_getSelectedItems()` to get only the selected cart items
- Call `_getSelectedTotal()` to calculate the checkout total
- Pass selected items to checkout screen instead of all cart items

## Implementation Details

### Animations & Transitions
- Smooth fade animation (200ms) when cart updates (still works with selection mode)
- Selection UI appears/disappears smoothly when toggling selection mode

### Data Persistence
- Selected items are NOT persisted - selection clears when:
  - Selection mode is toggled OFF
  - Cart is refreshed
  - App is restarted
- This is intentional to avoid stale selections

### Seller Grouping Integration
- Selection feature works seamlessly with existing seller-based grouping
- Items remain grouped by seller
- Selection state is independent of seller grouping

## Testing Checklist

- [x] Syntax errors fixed (bracket/parenthesis matching)
- [ ] Selection mode toggle works on/off
- [ ] Checkbox shows/hides based on selection mode
- [ ] Individual item selection toggles properly
- [ ] Green highlight appears on selected items
- [ ] Select All button selects all items
- [ ] Clear button deselects all items
- [ ] Count badge updates correctly
- [ ] Exiting selection mode clears selections
- [ ] All previous features still work (smooth animation, seller grouping, pull-to-refresh)
- [ ] No performance degradation with large carts

## Future Enhancements

1. **Bulk Operations**: Delete selected items, change quantity for all selected
2. **Persistent Selection**: Option to remember selections across sessions
3. **Selection Presets**: Save common checkout selections as presets
4. **Quantity Adjustment**: Increase/decrease quantity for all selected items together
5. **Checkout Integration**: Pass selected items directly to checkout screen

## Files Modified
- `lib/features/cart/screens/cart_screen.dart`:
  - Added `_selectedProductIds` and `_isSelectionMode` state variables
  - Added `_fadeController` and `_fadeAnimation` for smooth transitions
  - Implemented 5 helper methods for selection logic
  - Updated `_buildModernCartItemCard()` with checkbox UI and selection feedback
  - Updated `_buildCartHeader()` with selection toggle button and control buttons

## Related Features
- Seller-based grouping: Still active, items remain grouped by seller
- Smooth fade animation: Works with selection mode
- Pull-to-refresh: Unaffected by selection feature
- Cart persistence: Selection state is in-memory only (not persisted)
