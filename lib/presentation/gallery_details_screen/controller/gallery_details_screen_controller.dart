// providers/folder_browser_provider.dart
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';
import 'package:luminar_std/repository/gallery_details_screen/service/gallery_details_service.dart';

class FolderBrowserProvider with ChangeNotifier {
  final FolderBrowserService _service = FolderBrowserService();

  // Navigation stack
  final List<FolderPathItem> _folderPathStack = [];

  // Current folder contents
  List<FolderModel> _currentSubfolders = [];
  List<VideoModel> _currentVideos = [];

  // Summaries
  FolderSummary? _currentFolderSummary;
  VideoSummary? _currentVideoSummary;

  // Pagination for videos
  int _currentVideoPage = 1;
  int _totalVideoPages = 1;
  bool _hasMoreVideos = true;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;

  // Error states
  String? _foldersError;
  String? _videosError;

  // Gallery info (保持不变)
  late String _batchId;
  late String _galleryUid;
  late String _galleryName;
  late String _galleryDescription;

  // Getters
  List<FolderPathItem> get folderPathStack => List.unmodifiable(_folderPathStack);
  List<FolderModel> get currentSubfolders => _currentSubfolders;
  List<VideoModel> get currentVideos => _currentVideos;
  FolderSummary? get currentFolderSummary => _currentFolderSummary;
  VideoSummary? get currentVideoSummary => _currentVideoSummary;

  String? get currentFolderUid => _folderPathStack.isNotEmpty ? _folderPathStack.last.uid : null;
  String? get currentFolderName => _folderPathStack.isNotEmpty ? _folderPathStack.last.name : 'Root';

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMoreVideos => _hasMoreVideos;
  bool get isInRootFolder => _folderPathStack.isEmpty;

  String? get foldersError => _foldersError;
  String? get videosError => _videosError;

  bool get hasError => _foldersError != null || _videosError != null;

  // Initialize with gallery info
  void initialize({
    required String batchId,
    required String galleryUid,
    required String galleryName,
    required String galleryDescription,
  }) {
    _batchId = batchId;
    _galleryUid = galleryUid;
    _galleryName = galleryName;
    _galleryDescription = galleryDescription;
  }

  // Load root folder contents (no folder filter)
  // providers/folder_browser_provider.dart - Update loadRootContents method

  Future<void> loadRootContents({bool refresh = false}) async {
    if (refresh) {
      _clearCurrentFolder();
    }

    _isLoading = true;
    _isRefreshing = refresh;
    notifyListeners();

    try {
      // For root, load both folders AND videos without folder
      final response = await _service.getFolderContents(
        batchId: _batchId,
        galleryUid: _galleryUid,
        folderUid: null, // null means get videos without folder
        folderName: 'Root',
        videoPage: 1,
      );

      if (response.success) {
        final data = response.data as Map<String, dynamic>;

        // Process folders (subfolders in root)
        final foldersResponse = data['folders'] as FolderResponseModel;
        _currentSubfolders = foldersResponse.folders;
        _currentFolderSummary = foldersResponse.summary;

        // Process videos (videos without folder)
        final videosResponse = data['videos'] as VideoResponseModel?;
        if (videosResponse != null) {
          _currentVideos = videosResponse.videos;
          _currentVideoSummary = videosResponse.summary;
          _currentVideoPage = videosResponse.pagination.currentPage;
          _totalVideoPages = videosResponse.pagination.totalPages;
          _hasMoreVideos = _currentVideoPage < _totalVideoPages;
        } else {
          _currentVideos = [];
          _currentVideoSummary = null;
          _hasMoreVideos = false;
        }

        _foldersError = null;
        _videosError = null;
      } else {
        _foldersError = response.message;
      }
    } catch (e) {
      _foldersError = e.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Navigate into a folder
  Future<void> navigateToFolder({required String folderUid, required String folderName}) async {
    // Add to path stack
    _folderPathStack.add(FolderPathItem(uid: folderUid, name: folderName, parentFolderUid: currentFolderUid));

    _isLoading = true;
    _clearCurrentFolder();
    notifyListeners();

    try {
      // Load folder contents
      await _loadFolderContents(folderUid: folderUid, folderName: folderName);
    } catch (e) {
      _foldersError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Navigate back to previous folder
  Future<void> navigateBack() async {
    if (_folderPathStack.isEmpty) return;

    // Remove current folder
    _folderPathStack.removeLast();

    _isLoading = true;
    _clearCurrentFolder();
    notifyListeners();

    try {
      if (_folderPathStack.isEmpty) {
        // Back to root
        await loadRootContents();
      } else {
        // Load previous folder contents
        final previousFolder = _folderPathStack.last;
        await _loadFolderContents(folderUid: previousFolder.uid, folderName: previousFolder.name);
      }
    } catch (e) {
      _foldersError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Navigate to specific index in path (breadcrumb navigation)
  Future<void> navigateToPathIndex(int index) async {
    if (index < 0 || index >= _folderPathStack.length) return;

    // Remove all folders after this index
    _folderPathStack.removeRange(index + 1, _folderPathStack.length);

    _isLoading = true;
    _clearCurrentFolder();
    notifyListeners();

    try {
      if (_folderPathStack.isEmpty) {
        await loadRootContents();
      } else {
        final targetFolder = _folderPathStack.last;
        await _loadFolderContents(folderUid: targetFolder.uid, folderName: targetFolder.name);
      }
    } catch (e) {
      _foldersError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load folder contents (subfolders and videos)
  Future<void> _loadFolderContents({
    required String folderUid,
    required String folderName,
    int videoPage = 1,
    bool refresh = false,
  }) async {
    try {
      final response = await _service.getFolderContents(
        batchId: _batchId,
        galleryUid: _galleryUid,
        folderUid: folderUid,
        folderName: folderName,
        videoPage: videoPage,
      );

      if (response.success) {
        final data = response.data as Map<String, dynamic>;

        // Process folders
        final foldersResponse = data['folders'] as FolderResponseModel;
        _currentSubfolders = foldersResponse.folders;
        _currentFolderSummary = foldersResponse.summary;

        // Process videos (may be null for folders without videos)
        final videosResponse = data['videos'] as VideoResponseModel?;
        if (videosResponse != null) {
          if (refresh || videoPage == 1) {
            _currentVideos = videosResponse.videos;
          } else {
            _currentVideos.addAll(videosResponse.videos);
          }

          _currentVideoSummary = videosResponse.summary;
          _currentVideoPage = videosResponse.pagination.currentPage;
          _totalVideoPages = videosResponse.pagination.totalPages;
          _hasMoreVideos = _currentVideoPage < _totalVideoPages;
        } else {
          _currentVideos = [];
          _currentVideoSummary = null;
          _hasMoreVideos = false;
        }

        _foldersError = null;
        _videosError = null;
      } else {
        _foldersError = response.message;
      }
    } catch (e) {
      _foldersError = e.toString();
    }
  }

  // Load subfolders only
  Future<void> _loadSubfolders({String? parentFolderUid}) async {
    try {
      final response = await _service.getSubfolders(
        batchId: _batchId,
        galleryUid: _galleryUid,
        parentFolderUid: parentFolderUid,
      );

      if (response.success) {
        final foldersResponse = response.data as FolderResponseModel;
        _currentSubfolders = foldersResponse.folders;
        _currentFolderSummary = foldersResponse.summary;
        _foldersError = null;
      } else {
        _foldersError = response.message;
      }
    } catch (e) {
      _foldersError = e.toString();
    }
  }

  // Load next page of videos for current folder
  Future<void> loadNextVideoPage() async {
    if (!_hasMoreVideos || _isLoadingMore || currentFolderUid == null) return;

    _isLoadingMore = true;
    notifyListeners();

    await _loadFolderContents(
      folderUid: currentFolderUid!,
      folderName: currentFolderName ?? '',
      videoPage: _currentVideoPage + 1,
    );

    _isLoadingMore = false;
    notifyListeners();
  }

  // Refresh current folder
  Future<void> refreshCurrentFolder() async {
    if (isInRootFolder) {
      await loadRootContents(refresh: true);
    } else {
      _isRefreshing = true;
      notifyListeners();

      await _loadFolderContents(
        folderUid: currentFolderUid!,
        folderName: currentFolderName ?? '',
        videoPage: 1,
        refresh: true,
      );

      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Clear current folder data
  void _clearCurrentFolder() {
    _currentSubfolders = [];
    _currentVideos = [];
    _currentFolderSummary = null;
    _currentVideoSummary = null;
    _currentVideoPage = 1;
    _totalVideoPages = 1;
    _hasMoreVideos = true;
    _foldersError = null;
    _videosError = null;
  }

  // Reset everything (when leaving the screen)
  void reset() {
    _folderPathStack.clear();
    _clearCurrentFolder();
    _isLoading = false;
    _isLoadingMore = false;
    _isRefreshing = false;
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
