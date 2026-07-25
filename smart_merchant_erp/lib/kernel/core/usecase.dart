import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Base contract for all clean architecture use cases.
/// [T] is the return type inside [Either].
/// [Params] is the parameter type passed to the use case.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Helper class for use cases that do not require parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
