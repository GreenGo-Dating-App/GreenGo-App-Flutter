/// Communities Feature
///
/// Provides interest groups, language circles, and local guide communities
/// for connecting users with shared interests and languages.
library;

// Data - Datasources
export 'data/datasources/communities_remote_datasource.dart';
export 'data/models/community_member_model.dart';
export 'data/models/community_message_model.dart';
// Data - Models
export 'data/models/community_model.dart';
// Data - Repositories
export 'data/repositories/communities_repository_impl.dart';
// Domain - Entities
export 'domain/entities/community.dart';
export 'domain/entities/community_member.dart';
export 'domain/entities/community_message.dart';
// Domain - Repositories
export 'domain/repositories/communities_repository.dart';
// Presentation - BLoC
export 'presentation/bloc/communities_bloc.dart';
export 'presentation/bloc/communities_event.dart';
export 'presentation/bloc/communities_state.dart';
// Presentation - Screens
export 'presentation/screens/communities_screen.dart';
export 'presentation/screens/community_detail_screen.dart';
export 'presentation/screens/create_community_screen.dart';
// Presentation - Widgets
export 'presentation/widgets/community_card.dart';
export 'presentation/widgets/community_member_tile.dart';
export 'presentation/widgets/community_message_bubble.dart';
export 'presentation/widgets/community_type_chip.dart';
