class StatusCodeException implements Exception {
  final int statusCode;
  final String msg;
  StatusCodeException(this.statusCode) : msg = "200 <> $statusCode";
}
