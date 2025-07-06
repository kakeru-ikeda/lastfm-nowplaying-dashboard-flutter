import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/url_helper.dart';

/// クリック可能なトラック情報を表示するウィジェット
class ClickableTrackItem extends StatefulWidget {
  final String artist;
  final String track;
  final String? album;
  final String? imageUrl;
  final Widget? trailing;
  final EdgeInsets? padding;

  const ClickableTrackItem({
    super.key,
    required this.artist,
    required this.track,
    this.album,
    this.imageUrl,
    this.trailing,
    this.padding,
  });

  @override
  State<ClickableTrackItem> createState() => _ClickableTrackItemState();
}

class _ClickableTrackItemState extends State<ClickableTrackItem> {
  bool _isHovering = false;

  void _handleTap() {
    if (widget.artist.isNotEmpty && widget.track.isNotEmpty) {
      final url = UrlHelper.generateLastfmTrackUrl(widget.artist, widget.track);
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
                // アルバムアート
                if (widget.imageUrl?.isNotEmpty == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 20),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 20),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.music_note, size: 20),
                  ),
                const SizedBox(width: 12),

                // トラック情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isHovering 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.artist,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.album?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.album!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
