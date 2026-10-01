/// Agrega query params a una URL, descartando los que vienen `null`.
///
/// Vive aparte de `ApiClient` para poder testearlo: `Uri.replace` se encarga
/// del encoding, que es justo lo que se rompe al concatenar los params a mano
/// en el string del path (un `&` o un espacio en un nombre rompe la URL).
///
/// No pisa los params que ya tuviera la URL: los fusiona.
Uri withQueryParams(Uri uri, Map<String, String?>? params) {
  if (params == null || params.isEmpty) return uri;

  final present = <String, String>{
    for (final entry in params.entries)
      if (entry.value != null) entry.key: entry.value!,
  };
  if (present.isEmpty) return uri;

  return uri.replace(
    queryParameters: <String, String>{...uri.queryParameters, ...present},
  );
}
