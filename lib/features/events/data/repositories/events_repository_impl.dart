import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/event_filters.dart';
import '../../domain/entities/events_page.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_remote_data_source.dart';

class EventsRepositoryImpl implements EventsRepository {
  EventsRepositoryImpl({required this.remoteDataSource});

  final EventsRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, EventsPage>> getEvents({
    required double latitude,
    required double longitude,
    required EventFilters filters,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final model = await remoteDataSource.fetchEvents(
        latitude: latitude,
        longitude: longitude,
        filters: filters,
        page: page,
        pageSize: pageSize,
      );
      return Right(model.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
