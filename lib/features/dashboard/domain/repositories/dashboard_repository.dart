import 'package:dartz/dartz.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<String, DashboardStats>> getDashboardStats();
}
