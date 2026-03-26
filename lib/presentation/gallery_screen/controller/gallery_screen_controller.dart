// providers/gallery_provider.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/gallery_screen/models/gellery_res_model.dart';
import 'package:luminar_std/repository/gallery_screen/service/gallery_screen_service.dart';

class GalleryProvider with ChangeNotifier {
  final GalleryScreenService _galleryService = GalleryScreenService();

  List<Gallery> _galleries = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  Summary? _summary;
  int _totalPages = 1;

  // Getters
  List<Gallery> get galleries => _galleries;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  Summary? get summary => _summary;
  int get totalGalleries => _summary?.totalGalleries ?? 0;

  Future<void> loadGalleries(String batchId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _galleries = [];
      _hasMore = true;
      _summary = null;
    }

    if (_isLoading) return;

    // Check if we've reached the last page
    if (!refresh && _currentPage > _totalPages) {
      _hasMore = false;
      return;
    }

    _isLoading = refresh;
    _isLoadingMore = !refresh && _currentPage > 1;
    _error = null;
    notifyListeners();

    try {
      final response = await _galleryService.getGalleries(batchId: batchId, page: _currentPage);

      if (response.success) {
        final GalleryResModel resModel = response.data;

        // Update pagination info
        _totalPages = resModel.totalPages;
        _currentPage = resModel.currentPage + 1; // Increment for next page
        _hasMore = _currentPage <= _totalPages;

        // Update summary
        _summary = resModel.summary;

        // Add galleries
        if (refresh) {
          _galleries = resModel.galleries;
        } else {
          _galleries.addAll(resModel.galleries);
        }
      } else {
        _error = response.message ?? 'Failed to load galleries';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshGalleries(String batchId) async {
    await loadGalleries(batchId, refresh: true);
  }

  Future<void> loadNextPage(String batchId) async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    await loadGalleries(batchId);
  }
}
