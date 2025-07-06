import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/url_helper.dart';

/// クリック可能なアーティスト情報を表示するウィジェット
class ClickableArtistItem extends StatefulWidget {
  final String artist;
  final String? imageUrl;
  final Widget? trailing;
  final EdgeInsets? padding;

  const ClickableArtistItem({
    super.key,
    required this.artist,
    this.imageUrl,
    this.trailing,
    this.padding,
  });

  @override
  State<ClickableArtistItem> createState() => _ClickableArtistItemState();
}

class _ClickableArtistItemState extends State<ClickableArtistItem> {
  bool _isHovering = false;

  void _handleTap() {
    if (widget.artist.isNotEmpty) {
      final url = UrlHelper.generateLastfmArtistUrl(widget.artist);
      UrlHelper.openInNewTab(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ?? 
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovering 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: effectivePadding,
            child: Row(
              children: [
                // アーティストアバター
                if (widget.imageUrl?.isNotEmpty == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.person, size: 20),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.person, size: 20),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person, size: 20),
                  ),
                const SizedBox(width: 12),

                // アーティスト名
                Expanded(
                  child: Text(
                    widget.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _isHovering 
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 右端のウィジェット
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],

                // ホバー時のリンクアイコン
                if (_isHovering) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
