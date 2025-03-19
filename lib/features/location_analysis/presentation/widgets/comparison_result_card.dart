import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ComparisonResultCard extends StatelessWidget {
  final String result;

  const ComparisonResultCard({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Markdown içeriğini düzenle - başlıklar arasında daha fazla boşluk ekle ve çizgi ekle
    String formattedResult = result;
    
    // ## ile başlayan satırların öncesine ve sonrasına ekstra boşluk ekle ve çizgi ekle
    formattedResult = formattedResult.replaceAllMapped(
      RegExp(r'(^|\n)(## .+)(\n|$)'), 
      (match) => '${match.group(1)}\n${match.group(2)}\n\n---\n\n'
    );
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withBlue(
                    (Theme.of(context).colorScheme.primary.blue + 30).clamp(0, 255)
                  ),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Comparison Results',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // İçerik
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: MarkdownBody(
              data: formattedResult,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                  color: Colors.black,
                ),
                h2: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  height: 1.8,
                  letterSpacing: 0.5,
                ),
                h3: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                  color: Color(0xFF6339F9),
                ),
                h4: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                  color: Colors.black,
                ),
                p: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                ),
                listBullet: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                em: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
                blockquote: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ),
                ),
                blockquotePadding: const EdgeInsets.all(16),
                tableHead: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tableBody: const TextStyle(
                  color: Colors.black87,
                ),
                tableBorder: TableBorder.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                tableCellsPadding: const EdgeInsets.all(10),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                a: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                code: TextStyle(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                codeblockPadding: const EdgeInsets.all(12),
              ),
              onTapLink: (text, href, title) {
                // Link tıklama işlevi
                if (href != null) {
                  // URL açma işlevi eklenebilir
                }
              },
            ),
          ),
        ],
      ),
    );
  }
} 