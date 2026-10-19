import 'route_names.dart';

/// Destino de navegación según el rol devuelto por el backend.
///
/// Solo decide la pantalla inicial. Las operaciones sensibles siguen
/// autorizándose en el backend con el token vigente.
String destinationForRole(String? role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return RouteNames.adminDashboard;
    case 'INSTITUTION_ADMIN':
      return RouteNames.institutionDashboard;
    case 'COUNSELOR':
      return RouteNames.counselorDashboard;
    case 'STUDENT':
      return RouteNames.studentDashboard;
    default:
      return RouteNames.unauthorized;
  }
}

/// Comprueba si la ruta coincide con el rol ya obtenido del backend.
bool routeMatchesRole(String location, String? role) {
  if (location == RouteNames.adminPrefix ||
      location.startsWith('${RouteNames.adminPrefix}/')) {
    return role == 'SUPER_ADMIN';
  }
  if (location == RouteNames.institutionPrefix ||
      location.startsWith('${RouteNames.institutionPrefix}/')) {
    return role == 'INSTITUTION_ADMIN';
  }
  if (location == RouteNames.counselorPrefix ||
      location.startsWith('${RouteNames.counselorPrefix}/')) {
    return role == 'COUNSELOR';
  }
  if (location == RouteNames.studentPrefix ||
      location.startsWith('${RouteNames.studentPrefix}/')) {
    return role == 'STUDENT';
  }
  return true;
}
