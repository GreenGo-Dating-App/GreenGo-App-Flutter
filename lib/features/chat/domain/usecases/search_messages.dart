import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Search Messages Params
class SearchMessagesParams {

  SearchMessagesParams({
    required this.conversationId,
    required this.query,
    this.limit,
  });
  final String conversationId;
  final String query;
  final int? limit;
}

/// Search Messages Use Case
///
/// Searches for messages within a conversation containing a query string
class SearchMessages {

  SearchMessages(this.repository);
  final ChatRepository repository;

  Stream<Either<Failure, List<Message>>> call(SearchMessagesParams params) {
    try {
      return repository.searchMessages(
        conversationId: params.conversationId,
        query: params.query,
        limit: params.limit,
      );
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }
}
