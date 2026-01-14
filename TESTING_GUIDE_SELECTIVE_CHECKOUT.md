# Selective Checkout Feature - User Testing Guide

## Quick Reference: How to Use

### Enable Selection Mode
```
1. Open Cart screen
2. Look at the top-right corner (next to Profile and Notification icons)
3. Click the checkbox icon (☐)
4. Checkboxes appear on all cart items
```

### Select Items for Checkout

#### Option A: Select Individual Items
```
1. In selection mode, TAP any cart item card
2. Item card shows GREEN border and background
3. Green text shows "Selected for checkout"
4. Count badge updates showing total selected
```

#### Option B: Select All at Once
```
1. Click the GREEN "Select All" button (appears below header)
2. All items instantly get green highlight
3. Count badge shows total number of items selected
```

#### Option C: Select Specific Seller's Items
```
1. Seller items remain grouped together
2. Tap items from desired seller group
3. Items from multiple sellers can be selected
4. Count badge updates live
```

### Deselect Items

#### Option A: Deselect Individual Items
```
1. Tap a selected item again to deselect it
2. Green highlight disappears
3. Text shows "Not selected"
4. Count badge updates
```

#### Option B: Clear All Selections
```
1. Click the GRAY "Clear" button
2. All green highlights disappear instantly
3. Count badge disappears
4. All items show "Not selected"
```

### Exit Selection Mode
```
1. Click the checkbox icon again (now showing ☑)
2. Selection mode turns OFF
3. Checkboxes disappear
4. All selections are automatically cleared
5. Cart returns to normal view
```

---

## Visual Elements Guide

### Header Elements (Top of Cart Screen)

```
┌─────────────────────────────────────────────────────────┐
│  Rey Denzo                    [☐] [👤] [🔔]            │
│  OPAS Cart                                               │
└─────────────────────────────────────────────────────────┘

☐ = Selection Mode Toggle (click to enable/disable)
```

### Selection Mode Buttons (When Active)

```
┌─────────────────────────────────────────────────────────┐
│  [✓ Select All]  [✕ Clear]  ...  [3 selected]           │
└─────────────────────────────────────────────────────────┘

✓ Select All  = Green button (Selects all items)
✕ Clear      = Gray button (Deselects all items)  
[3 selected] = Count badge (Shows how many selected)
```

### Cart Item Card - Normal Mode

```
┌─────────────────────────────────────────────────────────┐
│  [IMAGE]  Itlog sa Pugo                  [✕]            │
│           Seller: Juan's Farm                            │
│                                                           │
│           ₱5.00/pc  ₱5.00    [−] 1 [+]                 │
└─────────────────────────────────────────────────────────┘
```

### Cart Item Card - Selection Mode (Unselected)

```
┌─────────────────────────────────────────────────────────┐
│  ☐ Not selected                                          │
│  [IMAGE]  Itlog sa Pugo                  [✕]            │
│           Seller: Juan's Farm                            │
│                                                           │
│           ₱5.00/pc  ₱5.00    [−] 1 [+]                 │
└─────────────────────────────────────────────────────────┘
```

### Cart Item Card - Selection Mode (Selected)

```
┌═════════════════════════════════════════════════════════┐
│ ☑ Selected for checkout                                 │
│ [IMAGE]  Itlog sa Pugo                  [✕]            │
│          Seller: Juan's Farm                            │
│                                                          │
│          ₱5.00/pc  ₱5.00    [−] 1 [+]                 │
└═════════════════════════════════════════════════════════┘

Green border (2px), light green background
```

---

## Testing Scenarios

### Scenario 1: Select Multiple Items

**Steps**:
1. Add 4-5 items to cart
2. Click checkbox icon to enable selection mode
3. Tap the 1st item → should show green highlight + "Selected for checkout"
4. Tap the 3rd item → should also show green highlight
5. Verify count badge shows "2 selected"
6. Tap the 2nd item → count badge now shows "3 selected"

**Expected Result**: ✅ All tapped items show green highlight, count updates correctly

---

### Scenario 2: Select All / Clear All

**Steps**:
1. Add 3 items to cart
2. Enable selection mode
3. Click "Select All" button
4. Verify all 3 items show green highlight
5. Verify count badge shows "3 selected"
6. Click "Clear" button
7. Verify all highlights disappear
8. Verify count badge disappears

**Expected Result**: ✅ Select All highlights all items, Clear removes all highlights

---

### Scenario 3: Toggle Selection Mode

**Steps**:
1. Add items to cart and enable selection mode
2. Select some items (e.g., 2 items)
3. Verify count badge shows selections
4. Click checkbox icon to disable selection mode
5. Verify checkboxes disappear
6. Enable selection mode again
7. Verify all items show "Not selected" (no previous selections remembered)

**Expected Result**: ✅ Selection clears when mode is toggled off

---

### Scenario 4: Seller Grouping + Selection

**Steps**:
1. Add items from 3 different sellers
2. Verify items are grouped by seller (should see seller headers)
3. Enable selection mode
4. Select items from different seller groups
5. Verify items from each group can be selected independently

**Expected Result**: ✅ Items remain grouped, selection works across groups

---

### Scenario 5: Quantity Changes in Selection Mode

**Steps**:
1. Add items to cart
2. Enable selection mode
3. Select an item
4. Change quantity of selected item (click +/- buttons)
5. Verify:
   - Item remains selected (green highlight)
   - Count badge still shows this item as selected
   - Smooth fade animation occurs (no jarring refresh)
   - Subtotal updates

**Expected Result**: ✅ Selection persists through quantity changes

---

### Scenario 6: Pull-to-Refresh with Selection

**Steps**:
1. Enable selection mode
2. Select some items
3. Pull down to refresh (swipe down on cart)
4. Verify refresh completes smoothly
5. Verify selections are cleared (expected behavior)
6. Verify smooth animation, no black screen

**Expected Result**: ✅ Pull-to-refresh works, selections cleared after refresh

---

## Performance Check

### Metrics to Verify

| Check | Expected | How to Verify |
|-------|----------|--------------|
| Selection Toggling | <100ms | Checkbox appears/disappears instantly |
| Item Selection | <50ms | Green highlight appears immediately |
| Select All | <100ms | All items highlight within 1 frame |
| Clear All | <100ms | All highlights disappear instantly |
| Count Badge Update | Real-time | Badge updates as you select/deselect |
| Quantity Changes | Smooth | 200ms fade animation, no glitches |
| Performance | Stable | No frame drops with many items |

---

## What's NOT Implemented Yet

⚠️ These are planned for future updates:

- [ ] Checkout with selected items only (currently feature-ready, needs checkout screen changes)
- [ ] Bulk operations (delete/modify multiple items at once)
- [ ] Selection persistence (selections are cleared on refresh)
- [ ] Undo/Redo for selections
- [ ] Selection history
- [ ] Quick presets ("Select all vegetables", etc.)

---

## Troubleshooting

### Checkboxes Don't Appear

**Solution**:
1. Make sure selection mode is ON (checkbox icon should be filled ☑)
2. Cart must have items in it
3. Try scrolling down to see if checkboxes are below visible area

### Green Highlight Not Showing

**Solution**:
1. Make sure you're tapping the card itself (not the remove button)
2. Verify selection mode is still ON
3. Try selecting a different item

### Count Badge Shows Wrong Number

**Solution**:
1. The count badge only updates when in selection mode
2. Try clicking Select All to verify all items are counted
3. Check if count matches number of green-highlighted items

### Selections Cleared After Refresh

**Solution**: This is intentional behavior (by design)
- Selection state is session-only for now
- Selections clear when you:
  - Pull-to-refresh the cart
  - Exit selection mode
  - Navigate away from cart screen
  - Restart the app

---

## Feedback & Issues

If you encounter any issues:

1. **Take a screenshot** of the problem
2. **Note the exact steps** that caused it
3. **Record any error messages** shown (check debug console)
4. **Mention the device/browser**: Edge on Web, Android Phone, etc.
5. **Report to development team** with details above

---

## Ready to Test!

The Selective Checkout Feature is now live and ready for testing. Have fun selecting items for checkout! 🛒✅
