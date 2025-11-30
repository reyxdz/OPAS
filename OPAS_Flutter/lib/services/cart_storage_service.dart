import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../features/cart/models/cart_item_model.dart';

/// Cart Storage Service using SQLite for persistent storage
/// This survives app rebuilds and provides reliable data persistence
class CartStorageService {
  static final CartStorageService _instance = CartStorageService._internal();
  static Database? _database;

  factory CartStorageService() {
    return _instance;
  }

  CartStorageService._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'opas_cart.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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

  /// Get all cart items for a user
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'cart_items',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
      );

      return maps.map((map) => CartItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting cart items: $e');
      return [];
    }
  }

  /// Add or update a cart item
  Future<void> addOrUpdateCartItem(String userId, CartItem item) async {
    try {
      final db = await database;
      
      // Check if item already exists
      final existing = await db.query(
        'cart_items',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, item.productId],
      );

      if (existing.isNotEmpty) {
        // Update quantity
        final newQuantity = existing[0]['quantity'] as int + item.quantity;
        await db.update(
          'cart_items',
          {
            'quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, item.productId],
        );
      } else {
        // Insert new item
        await db.insert(
          'cart_items',
          {
            ...item.toMap(),
            'user_id': userId,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }
      
      debugPrint('✅ Cart item saved: ${item.productName}');
    } catch (e) {
      debugPrint('❌ Error saving cart item: $e');
    }
  }

  /// Remove a cart item
  Future<void> removeCartItem(String userId, String productId) async {
    try {
      final db = await database;
      await db.delete(
        'cart_items',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
      debugPrint('✅ Cart item removed: $productId');
    } catch (e) {
      debugPrint('❌ Error removing cart item: $e');
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String userId, String productId, int quantity) async {
    try {
      final db = await database;
      if (quantity <= 0) {
        await removeCartItem(userId, productId);
      } else {
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
      final db = await database;
      await db.delete(
        'cart_items',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
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

// Import for debugPrint
import 'package:flutter/foundation.dart';
