import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/comparison_history_model.dart';

class ComparisonHistoryService {
  static const String _boxName = 'comparison_history';
  Box<ComparisonHistoryModel>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    try {
      print('ComparisonHistoryService: Initializing...');
      
      if (!Hive.isBoxOpen(_boxName)) {
        print('ComparisonHistoryService: Box is not open, opening it...');
        _box = await Hive.openBox<ComparisonHistoryModel>(_boxName);
        print('ComparisonHistoryService: Box opened successfully');
      } else {
        print('ComparisonHistoryService: Box is already open, getting it...');
        _box = Hive.box<ComparisonHistoryModel>(_boxName);
        print('ComparisonHistoryService: Got existing box');
      }
      
      print('ComparisonHistoryService: Box contains ${_box?.length ?? 0} items');
    } catch (e) {
      print('ComparisonHistoryService: Error initializing: $e');
      rethrow;
    }
  }

  // Yeni karşılaştırma ekle
  Future<ComparisonHistoryModel> addComparison({
    required List<String> locations,
    required String result,
  }) async {
    if (_box == null) {
      print('ComparisonHistoryService: Box is null, initializing...');
      await init();
    }

    final id = _uuid.v4();
    final title = ComparisonHistoryModel.generateTitle(locations);
    final now = DateTime.now();

    print('ComparisonHistoryService: Adding new comparison with ID: $id and title: $title');

    final comparison = ComparisonHistoryModel(
      id: id,
      locations: locations,
      result: result,
      createdAt: now,
      title: title,
    );

    try {
      await _box!.put(id, comparison);
      print('ComparisonHistoryService: Successfully added comparison');
      print('ComparisonHistoryService: Box now contains ${_box?.length ?? 0} items');
      return comparison;
    } catch (e) {
      print('ComparisonHistoryService: Error adding comparison: $e');
      rethrow;
    }
  }

  // Tüm karşılaştırmaları getir
  List<ComparisonHistoryModel> getAllComparisons() {
    if (_box == null || !_box!.isOpen) {
      print('ComparisonHistoryService: Box is null or not open when getting all comparisons');
      return [];
    }

    final comparisons = _box!.values.toList();
    // Tarihe göre sırala (en yeniden en eskiye)
    comparisons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('ComparisonHistoryService: Returning ${comparisons.length} comparisons');
    return comparisons;
  }

  // Belirli bir karşılaştırmayı getir
  ComparisonHistoryModel? getComparison(String id) {
    if (_box == null || !_box!.isOpen) {
      print('ComparisonHistoryService: Box is null or not open when getting comparison with ID: $id');
      return null;
    }

    return _box!.get(id);
  }

  // Karşılaştırmayı sil
  Future<void> deleteComparison(String id) async {
    if (_box == null || !_box!.isOpen) {
      print('ComparisonHistoryService: Box is null or not open when deleting comparison with ID: $id');
      return;
    }

    await _box!.delete(id);
    print('ComparisonHistoryService: Deleted comparison with ID: $id');
  }

  // Tüm karşılaştırmaları sil
  Future<void> clearAllComparisons() async {
    if (_box == null || !_box!.isOpen) {
      print('ComparisonHistoryService: Box is null or not open when clearing all comparisons');
      return;
    }

    await _box!.clear();
    print('ComparisonHistoryService: Cleared all comparisons');
  }
} 