import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Translate Message Use Case
///
/// Translates a message and stores the translation
class TranslateMessage {
  final ChatRepository repository;

  TranslateMessage(this.repository);

  Future<Either<Failure, void>> call({
    required String messageId,
    required String conversationId,
    required String translatedContent,
    required String detectedLanguage,
  }) async {
    return await repository.translateMessage(
      messageId: messageId,
      conversationId: conversationId,
      translatedContent: translatedContent,
      detectedLanguage: detectedLanguage,
    );
  }
}
