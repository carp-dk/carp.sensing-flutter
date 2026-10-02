/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../carp_services/carp_services.dart';

/// The shared [HTTPRetry] client used by all CAWS services.
final HTTPRetry httpr = HTTPRetry();

/// A [http.MultipartFile] that can be cloned, so [HTTPRetry.send] can
/// re-submit a multipart POST request with the same file.
class ClonableMultipartFile extends http.MultipartFile {
  /// The path of the local file to send.
  final String filePath;

  /// Creates a [ClonableMultipartFile]. Use
  /// [ClonableMultipartFile.fromFileSync] to create one from a file path.
  ClonableMultipartFile(
    this.filePath,
    super.field,
    super.stream,
    super.length, {
    super.filename,
    super.contentType,
  });

  /// Creates a new [ClonableMultipartFile] from a file specified by
  /// the [filePath], sent as form field `file`.
  factory ClonableMultipartFile.fromFileSync(String filePath) {
    final file = File(filePath);
    final length = file.lengthSync();
    final stream = file.openRead();
    var name = file.path.split('/').last;

    return ClonableMultipartFile(
      filePath,
      'file',
      stream,
      length,
      filename: name,
    );
  }

  // /// Creates a new [MultipartFile] from a string.
  // ///
  // /// The encoding to use when translating [value] into bytes is taken from
  // /// [contentType] if it has a charset set. Otherwise, it defaults to UTF-8.
  // /// [contentType] currently defaults to `text/plain; charset=utf-8`, but in
  // /// the future may be inferred from [filename].
  // factory MultipartFileRecreatable.fromString(String field, String value) {
  //   contentType ??= MediaType('text', 'plain');
  //   var encoding = encodingForCharset(contentType.parameters['charset'], utf8);
  //   contentType = contentType.change(parameters: {'charset': encoding.name});

  //   return MultipartFile.fromBytes(field, encoding.encode(value),
  //       filename: filename, contentType: contentType);
  // }

  /// Make a clone of this [ClonableMultipartFile].
  ClonableMultipartFile clone() => ClonableMultipartFile.fromFileSync(filePath);

  /// Deletes the local file at [filePath].
  void cleanup() => File(filePath).deleteSync();
}

/// Wraps the HTTP operations (GET, POST, PUT, DELETE, multipart SEND) with
/// retry on network errors.
///
/// Used through the shared [httpr] instance by all CAWS services.
///
/// Key points:
///  * Retries only on [SocketException] or [TimeoutException]; HTTP error
///    responses are returned as-is.
///  * Makes up to 15 attempts with exponential backoff (from the `retry`
///    package), each delay capped at 30 seconds.
///  * Each attempt times out after 20 seconds (15 for DELETE, 5 for SEND).
class HTTPRetry {
  final client = http.Client();

  /// Sends a multipart [request].
  ///
  /// On retry the request is rebuilt, cloning any [ClonableMultipartFile]s.
  /// Other file types are dropped from the retried request.
  Future<http.StreamedResponse> send(http.MultipartRequest request) async {
    http.MultipartRequest sending = request;

    return await retry(
      () => client.send(sending).timeout(const Duration(seconds: 5)),
      delayFactor: const Duration(seconds: 25),
      maxAttempts: 15,
      retryIf: (e) => e is SocketException || e is TimeoutException,
      onRetry: (e) {
        debugPrint('${e.runtimeType} - Retrying to SEND ${request.url}');

        // when retrying sending form data, the request needs to be cloned
        // see e.g. >> https://github.com/flutterchina/dio/issues/482
        sending = http.MultipartRequest(request.method, request.url);
        sending.headers.addAll(request.headers);
        sending.fields.addAll(request.fields);

        for (var file in request.files) {
          if (file is ClonableMultipartFile) {
            sending.files.add(file.clone());
          }
        }
      },
    );
  }

  /// Sends an HTTP GET request with the given [headers] to the given [url].
  Future<http.Response> get(String url, {Map<String, String>? headers}) async =>
      await retry(
        () => client
            .get(Uri.parse(Uri.encodeFull(url)), headers: headers)
            .timeout(const Duration(seconds: 20)),
        delayFactor: const Duration(seconds: 5),
        maxAttempts: 15,
        retryIf: (e) => e is SocketException || e is TimeoutException,
        onRetry: (e) => debugPrint('${e.runtimeType} - Retrying to GET $url'),
      );

  /// Sends an HTTP POST request with the given [headers] and [body] to the given [url].
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => await retry(
    () => client
        .post(
          Uri.parse(Uri.encodeFull(url)),
          headers: headers,
          body: body,
          encoding: encoding,
        )
        .timeout(const Duration(seconds: 20)),
    delayFactor: const Duration(seconds: 5),
    maxAttempts: 15,
    retryIf: (e) => e is SocketException || e is TimeoutException,
    onRetry: (e) => debugPrint('${e.runtimeType} - Retrying to POST $url'),
  );

  /// Sends an HTTP PUT request with the given [headers] and [body] to the given [url].
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => await retry(
    () => client
        .put(
          Uri.parse(Uri.encodeFull(url)),
          headers: headers,
          body: body,
          encoding: encoding,
        )
        .timeout(const Duration(seconds: 20)),
    delayFactor: const Duration(seconds: 5),
    maxAttempts: 15,
    retryIf: (e) => e is SocketException || e is TimeoutException,
    onRetry: (e) => debugPrint('${e.runtimeType} - Retrying to PUT $url'),
  );

  /// Sends an HTTP DELETE request with the given [headers] to the given [url].
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async => await retry(
    () => client
        .delete(Uri.parse(Uri.encodeFull(url)), headers: headers)
        .timeout(const Duration(seconds: 15)),
    delayFactor: const Duration(seconds: 5),
    maxAttempts: 15,
    retryIf: (e) => e is SocketException || e is TimeoutException,
    onRetry: (e) => debugPrint('${e.runtimeType} - Retrying to DELETE $url'),
  );
}
