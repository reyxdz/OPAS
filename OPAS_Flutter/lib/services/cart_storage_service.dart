import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite_db;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../features/cart/models/cart_item_model.dart';

/// Cart Storage Service using SQLite for mobile and SharedPreferences for web
/// This survives app rebuilds and provides reliable data persistence
class CartStorageService {
  static final CartStorageService _instance = CartStorageService._internal();
  static sqflite_db.Database? _database;
  static bool _isWeb = kIsWeb;

  factory CartStorageService() {
    return _instance;
  }

  CartStorageService._internal();

  Future<sqflite_db.Database> get database async {
    if (_isWeb) {
      throw Exception('Web platform should use SharedPreferences fallback');
    }
    _database ??= await _initDB();
    return _database!;
  }

  Future<sqflite_db.Database> _initDB() async {
    // Initialize sqflite for mobile/desktop if needed
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqflite_ffi.sqfliteFfiInit();
    }
    
    final dbPath = await sqflite_db.getDatabasesPath();
    final path = join(dbPath, 'opas_cart.db');

    // CRITICAL: Force database deletion and recreation if it has the old schema
    // This ensures we get the v3 schema with all required columns
    try {
      // Open the database to check its version
      final testDb = await sqflite_db.openDatabase(path);
      final version = await testDb.getVersion();
      debugPrint('🛒 SQLite: Current database version: $version');
      
      if (version < 3) {
        debugPrint('🛒 SQLite: Database is old version ($version), deleting to force recreation with v3 schema');
        await testDb.close();
        await sqflite_db.deleteDatabase(path);
        debugPrint('✅ SQLite: Old database deleted, will be recreated with v3 schema');
      } else {
        await testDb.close();
      }
    } catch (e) {
      debugPrint('ℹ️ SQLite: Could not check database version: $e (this is normal for first run)');
    }

    return await sqflite_db.openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(sqflite_db.Database db, int version) async {
    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        seller_name TEXT NOT NULL,
        seller_id TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT,
        image_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Create index for faster user_id lookups
    await db.execute('''
      CREATE INDEX idx_cart_user_id ON cart_items(user_id)
    ''');
  }

  Future<void> _upgradeDB(sqflite_db.Database db, int oldVersion, int newVersion) async {
    debugPrint('🛒 SQLite: Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add missing columns for version 2+
      debugPrint('🛒 SQLite: Adding missing columns: unit, seller_id');
      try {
        await db.execute('ALTER TABLE cart_items ADD COLUMN unit TEXT');
        debugPrint('✅ SQLite: Added unit column');
      } catch (e) {
        debugPrint('ℹ️ SQLite: unit column already exists or cannot be added: $e');
      }
      
      try {
        await db.execute('ALTER TABLE cart_items ADD COLUMN seller_id TEXT NOT NULL DEFAULT "0"');
        debugPrint('✅ SQLite: Added seller_id column');
      } catch (e) {
        debugPrint('ℹ️ SQLite: seller_id column already exists or cannot be added: $e');
      }
      
      debugPrint('✅ SQLite: Database migration to version 2+ complete');
    }
    
    if (oldVersion < 3) {
      debugPrint('🛒 SQLite: Ensuring v3 schema is complete');
      // Verify columns exist by trying to read them
      try {
        final result = await db.rawQuery('PRAGMA table_info(cart_items)');
        final columnNames = (result).map((col) => col['name'].toString()).toList();
        debugPrint('🛒 SQLite: Current columns: $columnNames');
        
        if (!columnNames.contains('unit')) {
          await db.execute('ALTER TABLE cart_items ADD COLUMN unit TEXT');
          debugPrint('✅ SQLite: Added missing unit column');
        }
        
        if (!columnNames.contains('seller_id')) {
          await db.execute('ALTER TABLE cart_items ADD COLUMN seller_id TEXT NOT NULL DEFAULT "0"');
          debugPrint('✅ SQLite: Added missing seller_id column');
        }
      } catch (e) {
        debugPrint('❌ SQLite: Error during v3 upgrade: $e');
      }
    }
  }

  String _getCartKey(String userId) => 'cart_items_$userId';

  /// Migrate cart from SharedPreferences to SQLite if needed
  /// This handles the case where user logs in on a different platform or after logout
  /// On web, this ensures backed-up cart is still accessible in SharedPreferences
  Future<void> migrateCartIfNeeded(String userId) async {
    try {
      debugPrint('🛒 migrateCartIfNeeded: Starting migration check for userId=$userId, _isWeb=$_isWeb');
      
      final prefs = await SharedPreferences.getInstance();
      final cartKey = _getCartKey(userId);
      final backedUpCart = prefs.getString(cartKey);
      
      debugPrint('🛒 migrateCartIfNeeded: Looking for backup at key=$cartKey');
      debugPrint('🛒 migrateCartIfNeeded: Backup found: ${backedUpCart != null}, length: ${backedUpCart?.length ?? 0}');
      
      if (backedUpCart != null && backedUpCart.isNotEmpty) {
        debugPrint('🛒 CartStorageService: Found backed-up cart in SharedPreferences');
        
        // Parse the backed-up JSON cart
        final List<dynamic> decoded = jsonDecode(backedUpCart);
        final cartItems = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('🛒 migrateCartIfNeeded: Parsed ${cartItems.length} items from backup');
        
        if (_isWeb) {
          // On web, backup is already in SharedPreferences, just log the restoration
          debugPrint('🛒 CartStorageService: Web - Verified backed-up cart with ${cartItems.length} items is in localStorage for userId=$userId');
        } else {
          // On mobile, migrate from SharedPreferences to SQLite
          debugPrint('🛒 CartStorageService: MOBILE - Starting migration to SQLite for ${cartItems.length} items...');
          
          // Clear any existing cart for this user in SQLite
          debugPrint('🛒 migrateCartIfNeeded: Clearing existing SQLite data for userId=$userId');
          await clearCart(userId);
          debugPrint('🛒 migrateCartIfNeeded: Cleared SQLite, now restoring ${cartItems.length} items');
          
          // Add all backed-up items to SQLite
          for (int i = 0; i < cartItems.length; i++) {
            final item = cartItems[i];
            debugPrint('🛒 migrateCartIfNeeded: Restoring item $i: ${item.productId}');
            await addOrUpdateCartItem(userId, item);
            debugPrint('✅ migrateCartIfNeeded: Successfully restored item $i');
          }
          
          debugPrint('✅ CartStorageService: Successfully migrated ${cartItems.length} items to SQLite');
        }
      } else {
        debugPrint('🛒 CartStorageService: No backed-up cart found for userId=$userId in SharedPreferences');
      }
    } catch (e, st) {
      debugPrint('❌ CartStorageService: Error during migration: $e');
      debugPrint('❌ CartStorageService: Stack trace: $st');
    }
  }

  /// Get all cart items for a user
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      if (_isWeb) {
        // Use SharedPreferences on web
        // IMPORTANT: Always get fresh instance to ensure we read from localStorage
        final prefs = await SharedPreferences.getInstance();
        
        // Force reload from browser localStorage to get latest data after rebuild
        await prefs.reload();
        debugPrint('🛒 Web: Reloaded SharedPreferences from localStorage');
        
        final cartJson = prefs.getString(_getCartKey(userId)) ?? '[]';
        debugPrint('🛒 Web: Reading cart for userId=$userId from localStorage, got ${cartJson.length} chars');
        final List<dynamic> decoded = jsonDecode(cartJson);
        final items = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('🛒 Web: Decoded ${items.length} cart items for userId=$userId');
        return items;
      } else {
        // Use SQLite on mobile
        final db = await database;
        final maps = await db.query(
          'cart_items',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'updated_at DESC',
        );
        debugPrint('🛒 SQLite: Loaded ${maps.length} cart items for userId=$userId');
        return maps.map((map) => CartItem.fromMap(map)).toList();
      }
    } catch (e) {
      debugPrint('❌ Error getting cart items: $e');
      return [];
    }
  }

  /// Add or update a cart item
  Future<void> addOrUpdateCartItem(String userId, CartItem item) async {
    try {
      debugPrint('🛒 addOrUpdateCartItem called: userId=$userId, product=${item.productId}, _isWeb=$_isWeb');
      
      if (_isWeb) {
        debugPrint('🛒 Web platform detected - using SharedPreferences');
        // Use SharedPreferences on web
        // IMPORTANT: Always get fresh instance to ensure we read from localStorage
        final prefs = await SharedPreferences.getInstance();
        debugPrint('🛒 Web: SharedPreferences instance obtained');
        
        // Force reload from browser localStorage to get latest data
        await prefs.reload();
        debugPrint('🛒 Web: Reloaded SharedPreferences from localStorage before write');
        
        final cartKey = _getCartKey(userId);
        debugPrint('🛒 Web: Cart key = $cartKey');
        
        final cartJson = prefs.getString(cartKey) ?? '[]';
        debugPrint('🛒 Web: Current cart JSON length = ${cartJson.length} chars');
        
        final List<dynamic> decoded = jsonDecode(cartJson);
        debugPrint('🛒 Web: Decoded ${decoded.length} items from JSON');
        
        final cart = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('🛒 Web: Parsed ${cart.length} CartItems from JSON');
        
        final existingIndex =
            cart.indexWhere((i) => i.productId == item.productId);
        if (existingIndex >= 0) {
          cart[existingIndex].quantity += item.quantity;
          debugPrint('🛒 Web: Updated quantity for product ${item.productId} to ${cart[existingIndex].quantity}');
        } else {
          cart.add(item);
          debugPrint('🛒 Web: Added new product ${item.productId}, cart now has ${cart.length} items');
        }
        
        final updatedJson =
            jsonEncode(cart.map((item) => item.toJson()).toList());
        debugPrint('🛒 Web: Encoded cart to JSON, length = ${updatedJson.length} chars');
        
        final success = await prefs.setString(cartKey, updatedJson);
        debugPrint('🛒 Web: prefs.setString() returned success=$success');
        
        if (success) {
          debugPrint('✅ Web: Successfully saved ${cart.length} items to localStorage');
          // Additional persistence guarantee on web: ensure it's actually written
          if (kIsWeb) {
            // Give browser a moment to persist to localStorage
            await Future.delayed(const Duration(milliseconds: 100));
            debugPrint('🛒 Web: Delayed write to ensure localStorage persistence');
          }
        } else {
          debugPrint('❌ Web: setString() returned false - data may not be persisted!');
        }
      } else {
        // Use SQLite on mobile
        debugPrint('🛒 SQLite: Adding/updating product ${item.productId} for userId=$userId');
        final db = await database;
        
        final existing = await db.query(
          'cart_items',
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, item.productId],
        );
        
        debugPrint('🛒 SQLite: Found ${existing.length} existing records for this product');

        if (existing.isNotEmpty) {
          final currentQuantity = existing[0]['quantity'] as int;
          final newQuantity = currentQuantity + item.quantity;
          final updateResult = await db.update(
            'cart_items',
            {
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'user_id = ? AND product_id = ?',
            whereArgs: [userId, item.productId],
          );
          debugPrint('🛒 SQLite: Updated quantity for product ${item.productId} to $newQuantity (rows affected: $updateResult)');
        } else {
          final now = DateTime.now().toIso8601String();
          final insertResult = await db.insert(
            'cart_items',
            {
              ...item.toMap(),
              'user_id': userId,
              'created_at': now,
              'updated_at': now,
            },
          );
          debugPrint('🛒 SQLite: Inserted new product ${item.productId} (rowid: $insertResult)');
        }
      }
      
      debugPrint('✅ Cart item saved: ${item.productName}');
    } catch (e, st) {
      debugPrint('❌ Error saving cart item: $e');
      debugPrint('❌ Stack trace: $st');
    }
  }

  /// Remove a cart item
  Future<void> removeCartItem(String userId, String productId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString(_getCartKey(userId)) ?? '[]';
        final List<dynamic> decoded = jsonDecode(cartJson);
        final cart = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        cart.removeWhere((i) => i.productId == productId);
        final updatedJson =
            jsonEncode(cart.map((item) => item.toJson()).toList());
        await prefs.setString(_getCartKey(userId), updatedJson);
      } else {
        final db = await database;
        await db.delete(
          'cart_items',
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, productId],
        );
      }
      debugPrint('✅ Cart item removed: $productId');
    } catch (e) {
      debugPrint('❌ Error removing cart item: $e');
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String userId, String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeCartItem(userId, productId);
      } else if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString(_getCartKey(userId)) ?? '[]';
        final List<dynamic> decoded = jsonDecode(cartJson);
        final cart = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        final index =
            cart.indexWhere((i) => i.productId == productId);
        if (index >= 0) {
          cart[index].quantity = quantity;
        }
        final updatedJson =
            jsonEncode(cart.map((item) => item.toJson()).toList());
        await prefs.setString(_getCartKey(userId), updatedJson);
      } else {
        final db = await database;
        await db.update(
          'cart_items',
          {
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, productId],
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating quantity: $e');
    }
  }

  /// Clear all cart items for a user
  Future<void> clearCart(String userId) async {
    try {
      if (_isWeb) {
        debugPrint('🛒 clearCart: WEB - Removing key cart_items_$userId from SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_getCartKey(userId));
        debugPrint('✅ clearCart: WEB - Removed cart for user: $userId');
      } else {
        debugPrint('🛒 clearCart: MOBILE - Deleting SQLite rows for userId=$userId');
        final db = await database;
        final rowsDeleted = await db.delete(
          'cart_items',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        debugPrint('✅ clearCart: MOBILE - Deleted $rowsDeleted cart items for user: $userId');
      }
    } catch (e, st) {
      debugPrint('❌ Error clearing cart: $e');
      debugPrint('❌ Stack trace: $st');
    }
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
