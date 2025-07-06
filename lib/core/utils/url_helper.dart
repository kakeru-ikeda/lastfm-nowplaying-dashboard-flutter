// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Last.fm URL生成とブラウザ操作のヘルパークラス
class UrlHelper {
  /// Last.fmの楽曲ページURLを生成
  ///
  /// アーティスト名と楽曲名をURLエンコードしてLast.fmのURLに変換します
  static String generateLastfmTrackUrl(String artist, String track) {
    final encodedArtist = Uri.encodeComponent(artist);
    final encodedTrack = Uri.encodeComponent(track);
    return 'https://www.last.fm/music/$encodedArtist/_/$encodedTrack';
  }

  /// Last.fmのアーティストページURLを生成
  ///
  /// アーティスト名をURLエンコードしてLast.fmのURLに変換します
  static String generateLastfmArtistUrl(String artist) {
    final encodedArtist = Uri.encodeComponent(artist);
    return 'https://www.last.fm/music/$encodedArtist';
  }

  /// 新しいタブでURLを開く
  ///
  /// Web環境でのみ動作します
  static void openInNewTab(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (e) {
      // Web環境以外では何もしない
      // Debug時のみログ出力（production環境では無効化される）
      assert(() {
        return true;
      }());
    }
  }
}
