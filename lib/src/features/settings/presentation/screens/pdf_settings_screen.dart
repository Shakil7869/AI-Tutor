// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:student_ai_tutor/src/shared/services/pdf_service.dart';
// import 'package:student_ai_tutor/src/shared/managers/pdf_cache_manager.dart';
// import 'package:student_ai_tutor/src/shared/providers/firebase_provider.dart';

// /// PDF settings screen with Firebase integration
// class PDFSettingsScreen extends ConsumerStatefulWidget {
//   const PDFSettingsScreen({super.key});

//   @override
//   ConsumerState<PDFSettingsScreen> createState() => _PDFSettingsScreenState();
// }

// class _PDFSettingsScreenState extends ConsumerState<PDFSettingsScreen> {
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final pdfService = ref.read(pdfServiceProvider);
//     final cacheState = ref.watch(pdfCacheStateProvider);
//     final firebaseState = ref.watch(firebaseStateProvider);
//     final firebaseHealth = ref.watch(firebaseHealthProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PDF & Firebase Settings'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               ref.read(pdfCacheStateProvider.notifier).refreshCache();
//               ref.read(firebaseStateProvider.notifier).refreshConnection();
//               ref.invalidate(firebaseHealthProvider);
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await ref.read(pdfCacheStateProvider.notifier).refreshCache();
//           await ref.read(firebaseStateProvider.notifier).refreshConnection();
//           ref.invalidate(firebaseHealthProvider);
//         },
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // Firebase Status Section
//             _buildFirebaseStatusCard(theme, firebaseState, firebaseHealth),
//             const SizedBox(height: 16),

//             // PDF Service Status Section
//             _buildPDFServiceCard(theme, pdfService),
//             const SizedBox(height: 16),

//             // Cache Management Section
//             _buildCacheManagementCard(theme, cacheState),
//             const SizedBox(height: 16),

//             // Offline Management Section
//             _buildOfflineManagementCard(theme),
//             const SizedBox(height: 16),

//             // Sync Options Section
//             _buildSyncOptionsCard(theme, pdfService),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFirebaseStatusCard(ThemeData theme, FirebaseState firebaseState, AsyncValue<Map<String, dynamic>> firebaseHealth) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   firebaseState.isConnected ? Icons.cloud_done : Icons.cloud_off,
//                   color: firebaseState.isConnected ? Colors.green : Colors.orange,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Firebase Status',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             _buildStatusRow('Initialized', firebaseState.isInitialized),
//             _buildStatusRow('Connected', firebaseState.isConnected),
            
//             if (firebaseState.error != null) ...[
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: theme.colorScheme.errorContainer,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   'Error: ${firebaseState.error}',
//                   style: TextStyle(color: theme.colorScheme.onErrorContainer),
//                 ),
//               ),
//             ],

//             if (firebaseHealth.hasValue) ...[
//               const SizedBox(height: 12),
//               const Text('Performance:', style: TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 4),
//               firebaseHealth.when(
//                 data: (health) => Column(
//                   children: [
//                     _buildHealthRow('Status', health['status'] ?? 'unknown'),
//                     if (health['firestore_time_ms'] != null)
//                       _buildHealthRow('Firestore', '${health['firestore_time_ms']}ms'),
//                     if (health['storage_time_ms'] != null)
//                       _buildHealthRow('Storage', '${health['storage_time_ms']}ms'),
//                   ],
//                 ),
//                 loading: () => const CircularProgressIndicator(),
//                 error: (error, stack) => Text('Health check failed: $error'),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPDFServiceCard(ThemeData theme, PDFService pdfService) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.picture_as_pdf, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   'PDF Service',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             _buildStatusRow('Firebase Available', pdfService.isFirebaseAvailable),
//             _buildInfoRow('Storage Mode', pdfService.storageMode),
            
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               onPressed: _isLoading ? null : () => _testPDFService(pdfService),
//               icon: _isLoading ? const SizedBox(
//                 width: 16,
//                 height: 16,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ) : const Icon(Icons.network_check),
//               label: const Text('Test Service'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCacheManagementCard(ThemeData theme, PDFCacheState cacheState) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.storage, color: Colors.purple),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Cache Management',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             if (cacheState.stats != null) ...[
//               _buildInfoRow('Total Files', '${cacheState.stats!.totalFiles}'),
//               _buildInfoRow('Total Size', cacheState.stats!.totalSizeFormatted),
//               _buildInfoRow('Stale Files', '${cacheState.stats!.staleFiles}'),
              
//               if (cacheState.stats!.filesByClass.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 const Text('Files by Class:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 ...cacheState.stats!.filesByClass.entries.map(
//                   (entry) => Padding(
//                     padding: const EdgeInsets.only(left: 16),
//                     child: _buildInfoRow('Class ${entry.key}', '${entry.value} files'),
//                   ),
//                 ),
//               ],
//             ],
            
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: cacheState.isLoading ? null : () => 
//                       ref.read(pdfCacheStateProvider.notifier).clearStaleCache(),
//                   icon: const Icon(Icons.cleaning_services),
//                   label: const Text('Clear Stale'),
//                 ),
//                 OutlinedButton.icon(
//                   onPressed: cacheState.isLoading ? null : () => 
//                       _showClearCacheDialog(context),
//                   icon: const Icon(Icons.delete),
//                   label: const Text('Clear All'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOfflineManagementCard(ThemeData theme) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.offline_pin, color: Colors.green),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Offline Management',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             const Text('Download chapters for offline use:'),
//             const SizedBox(height: 12),
            
//             Wrap(
//               spacing: 8,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () => _showPreloadDialog(context, 9),
//                   icon: const Icon(Icons.download),
//                   label: const Text('Class 9'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () => _showPreloadDialog(context, 10),
//                   icon: const Icon(Icons.download),
//                   label: const Text('Class 10'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSyncOptionsCard(ThemeData theme, PDFService pdfService) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.sync, color: Colors.orange),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Sync Options',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             const Text('Synchronize data with Firebase:'),
//             const SizedBox(height: 12),
            
//             ElevatedButton.icon(
//               onPressed: pdfService.isFirebaseAvailable ? () => _syncWithFirebase(pdfService) : null,
//               icon: const Icon(Icons.cloud_sync),
//               label: const Text('Sync Chapters'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusRow(String label, bool status) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Icon(
//             status ? Icons.check_circle : Icons.cancel,
//             color: status ? Colors.green : Colors.red,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Text(label),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildHealthRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 1),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontSize: 12)),
//           Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Future<void> _testPDFService(PDFService pdfService) async {
//     setState(() => _isLoading = true);
    
//     try {
//       final isHealthy = await pdfService.checkServiceStatus();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(isHealthy ? 'PDF Service is healthy' : 'PDF Service is not responding'),
//             backgroundColor: isHealthy ? Colors.green : Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Test failed: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _syncWithFirebase(PDFService pdfService) async {
//     try {
//       await pdfService.syncChaptersWithFirebase();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Chapters synced with Firebase'), backgroundColor: Colors.green),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   void _showClearCacheDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clear All Cache'),
//         content: const Text('This will delete all downloaded PDFs. You can re-download them later.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               ref.read(pdfCacheStateProvider.notifier).clearCache();
//             },
//             child: const Text('Clear'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showPreloadDialog(BuildContext context, int classLevel) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Download Class $classLevel'),
//         content: const Text('Download all available chapters for offline use?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _preloadClass(classLevel);
//             },
//             child: const Text('Download'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _preloadClass(int classLevel) async {
//     try {
//       // Get all chapters for the class
//       final pdfService = ref.read(pdfServiceProvider);
//       final chapters = await pdfService.getChapters(classLevel);
//       final chapterIds = chapters.keys.toList();
      
//       if (chapterIds.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No chapters found for this class')),
//         );
//         return;
//       }

//       // Start preloading
//       await ref.read(pdfCacheStateProvider.notifier).preloadChapters(classLevel, chapterIds);
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Downloaded ${chapterIds.length} chapters for Class $classLevel')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }
// }
