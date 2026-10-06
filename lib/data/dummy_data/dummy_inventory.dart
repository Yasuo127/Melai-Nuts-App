import '../../core/services/staff_store.dart';
import '../catalog_store.dart';
import '../models/inventory_batch.dart';
import '../models/inventory_item.dart';

// NOTE: despite the folder name this file holds NO sample data any more. It is
// a thin read-only view over the real inventory that [StaffStore] loads from
// the database, kept so the Owner / Delivery / Product screens that already
// import these names keep working. Everything is scoped to the branch the
// signed-in staff member (or owner) is currently viewing.

/// Names of the real branches (empty until branches have loaded).
List<String> get kInventoryBranches => kBranches.map((b) => b.name).toList();

/// Real batches for the active branch.
List<InventoryBatch> get kInventoryBatches => StaffStore.instance.batches;

/// Real per-variant stock rows for the active branch.
List<InventoryItem> get kInventoryItems => StaffStore.instance.inventoryItems;

List<InventoryBatch> get lowStockBatches =>
    kInventoryBatches.where((b) => b.isLowStock).toList();

List<InventoryBatch> batchesByPriority(FefoPriority priority) =>
    kInventoryBatches.where((b) => b.fefoPriority == priority).toList();

List<InventoryBatch> batchesForBranch(String branch) =>
    kInventoryBatches.where((b) => b.branch == branch).toList();

List<InventoryBatch> batchesForProduct(String productId) =>
    kInventoryBatches.where((b) => b.productId == productId).toList();

List<InventoryItem> inventoryItemsForBranch(String branch) =>
    kInventoryItems.where((i) => i.branch == branch).toList();

int totalStockFor(String productId) => kInventoryItems
    .where((i) => i.productId == productId)
    .fold(0, (sum, i) => sum + i.quantity);
