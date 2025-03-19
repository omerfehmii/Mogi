import 'package:flutter/material.dart';
import '../../data/services/premium_service.dart';

class AdminActionsWidget extends StatefulWidget {
  final PremiumService premiumService;
  final Function() onPremiumStatusChanged;

  const AdminActionsWidget({
    Key? key,
    required this.premiumService,
    required this.onPremiumStatusChanged,
  }) : super(key: key);

  @override
  State<AdminActionsWidget> createState() => _AdminActionsWidgetState();
}

class _AdminActionsWidgetState extends State<AdminActionsWidget> {
  String confirmText = '';
  String resetConfirmText = '';
  String mogiConfirmText = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _resetPremiumStatus(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : const Text(
                    'Reset Premium Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _resetMogiPoints(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.1),
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  )
                : const Text(
                    'Mogi Puanlarını 5\'e Sıfırla',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _removePremiumStatus(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.withOpacity(0.1),
              foregroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.purple,
                    ),
                  )
                : const Text(
                    'Premium Statüsünü Kaldır',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetPremiumStatus(BuildContext context) async {
    // Reset confirm text value
    resetConfirmText = '';
    
    // Show confirmation dialog
    final bool? confirm = await _showConfirmationDialog(
      context,
      title: 'Premium Durumunu Sıfırla',
      message: 'Premium durumunu sıfırlamak istediğinizden emin misiniz?\n\nBu işlem tüm premium özelliklerinizi ve limitlerinizi sıfırlayacaktır.',
      confirmText: 'SIFIRLA',
      confirmHint: 'SIFIRLA',
      confirmColor: Colors.red,
      buttonText: 'Limitleri Sıfırla',
      confirmVariable: (value) => resetConfirmText = value,
    );
    
    if (confirm != true) return;
    
    // Handle the reset action
    await _performServiceAction(
      context,
      action: () => widget.premiumService.resetPremiumStatus(),
      successMessage: 'Premium durumu sıfırlandı',
    );
  }

  Future<void> _resetMogiPoints(BuildContext context) async {
    // Reset confirm text value
    mogiConfirmText = '';
    
    // Show confirmation dialog
    final bool? confirm = await _showConfirmationDialog(
      context,
      title: 'Mogi Puanlarını Sıfırla',
      message: 'Mogi puanlarınızı 5\'e sıfırlamak istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ve mevcut tüm Mogi puanlarınızı kaybedeceksiniz.',
      confirmText: 'PUANISIFIRLA',
      confirmHint: 'PUANISIFIRLA',
      confirmColor: Colors.orange,
      buttonText: 'Puanları Sıfırla',
      confirmVariable: (value) => mogiConfirmText = value,
    );
    
    if (confirm != true) return;
    
    // Handle the reset action
    await _performServiceAction(
      context,
      action: () => widget.premiumService.resetMogiPoints(),
      successMessage: 'Mogi puanları 5\'e sıfırlandı',
    );
  }

  Future<void> _removePremiumStatus(BuildContext context) async {
    // Reset confirm text value
    confirmText = '';
    
    // Show confirmation dialog
    final bool? confirm = await _showConfirmationDialog(
      context,
      title: 'Premium Statüsünü Kaldır',
      message: 'Premium statüsünü kaldırmak istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ve premium özelliklerinizi kaybedeceksiniz.',
      confirmText: 'KALDIR',
      confirmHint: 'KALDIR',
      confirmColor: Colors.purple,
      buttonText: 'Statüsü Kaldır',
      confirmVariable: (value) => confirmText = value,
    );
    
    if (confirm != true) return;
    
    // Handle the removal action
    await _performServiceAction(
      context,
      action: () => widget.premiumService.removePremiumStatus(),
      successMessage: 'Premium statüsü kaldırıldı',
    );
  }

  // Reusable method for showing confirmation dialogs
  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required String confirmHint,
    required Color confirmColor,
    required String buttonText,
    required Function(String) confirmVariable,
  }) {
    String inputText = '';
    
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF08104F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Güvenlik doğrulaması için aşağıdakini yazın:',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: confirmHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: confirmColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: confirmColor),
                  ),
                ),
                onChanged: (value) {
                  inputText = value;
                  confirmVariable(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputText == confirmText) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Güvenlik doğrulaması başarısız oldu!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  // Reusable method for performing service actions with loading state and error handling
  Future<void> _performServiceAction(
    BuildContext context, {
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    try {
      setState(() => _isLoading = true);
      await widget.premiumService.init();
      
      print('İşlem başlatılıyor...');
      await action();
      print('İşlem tamamlandı');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onPremiumStatusChanged();
      }
    } catch (e) {
      print('İşlem hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 