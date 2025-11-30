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

    return await sqflite_db.openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
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
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
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

  String _getCartKey(String userId) => 'cart_items_$userId';

  /// Migrate cart from SharedPreferences to SQLite if needed
  /// This handles the case where user logs in on a different platform or after logout
  Future<void> migrateCartIfNeeded(String userId) async {
    if (_isWeb) return; // Web uses SharedPreferences, no migration needed
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = _getCartKey(userId);
      final backedUpCart = prefs.getString(cartKey);
      
      if (backedUpCart != null && backedUpCart.isNotEmpty) {
        debugPrint('🛒 CartStorageService: Found backed-up cart in SharedPreferences, migrating to SQLite...');
        
        // Parse the backed-up JSON cart
        final List<dynamic> decoded = jsonDecode(backedUpCart);
        final cartItems = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Clear any existing cart for this user in SQLite
        await clearCart(userId);
        
        // Add all backed-up items to SQLite
        for (final item in cartItems) {
          await addOrUpdateCartItem(userId, item);
        }
        
        debugPrint('✅ CartStorageService: Successfully migrated ${cartItems.length} items from SharedPreferences to SQLite');
      }
    } catch (e) {
      debugPrint('❌ CartStorageService: Error during migration: $e');
    }
  }

  /// Get all cart items for a user
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      if (_isWeb) {
        // Use SharedPreferences on web
        // IMPORTANT: Always get fresh instance to ensure we read from localStorage
        final prefs = await SharedPreferences.getInstance();
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
      if (_isWeb) {
        // Use SharedPreferences on web
        // IMPORTANT: Always get fresh instance to ensure we read from localStorage
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString(_getCartKey(userId)) ?? '[]';
        final List<dynamic> decoded = jsonDecode(cartJson);
        final cart = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
        
        final existingIndex =
            cart.indexWhere((i) => i.productId == item.productId);
        if (existingIndex >= 0) {
          cart[existingIndex].quantity += item.quantity;
          debugPrint('🛒 Web: Updated quantity for product ${item.productId} to ${cart[existingIndex].quantity}');
        } else {
          cart.add(item);
          debugPrint('🛒 Web: Added new product ${item.productId} to cart');
        }
        
        final updatedJson =
            jsonEncode(cart.map((item) => item.toJson()).toList());
        final success = await prefs.setString(_getCartKey(userId), updatedJson);
        debugPrint('🛒 Web: Saved ${cart.length} items to localStorage, success=$success');
        if (!success) {
          debugPrint('❌ Web: Failed to save cart to localStorage!');
        }
      } else {
        // Use SQLite on mobile
        final db = await database;
        
        final existing = await db.query(
          'cart_items',
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, item.productId],
        );

        if (existing.isNotEmpty) {
          final currentQuantity = existing[0]['quantity'] as int;
          final newQuantity = currentQuantity + item.quantity;
          await db.update(
            'cart_items',
            {
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'user_id = ? AND product_id = ?',
            whereArgs: [userId, item.productId],
          );
          debugPrint('🛒 SQLite: Updated quantity for product ${item.productId} to $newQuantity');
        } else {
          await db.insert(
            'cart_items',
            {
              ...item.toMap(),
              'user_id': userId,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
          debugPrint('🛒 SQLite: Inserted new product ${item.productId}');
        }
      }
      
      debugPrint('✅ Cart item saved: ${item.productName}');
    } catch (e) {
      debugPrint('❌ Error saving cart item: $e');
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_getCartKey(userId));
      } else {
        final db = await database;
        await db.delete(
          'cart_items',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }
      debugPrint('✅ Cart cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing cart: $e');
    }
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
