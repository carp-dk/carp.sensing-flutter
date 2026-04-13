/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../carp_services/carp_services.dart';

/// The HTTP Retry method.
final HTTPRetry httpr = HTTPRetry();

/// A MultipartFile class which support cloning of the file for re-submission
/// of POST request.
class ClonableMultipartFile extends http.MultipartFile {
  final String filePath;

  ClonableMultipartFile(
    this.filePath,
    super.field,
    super.stream,
    super.length, {
    super.filename,
    super.contentType,
  });

  /// Creates a new [ClonableMultipartFile] from a file specified by
  /// the [filePath].
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

  /// Cleanup this [ClonableMultipartFile], i.e., deleting the buffer.
  void cleanup() => File(filePath).deleteSync();
}

/// A class wrapping all HTTP operations (GET, POST, PUT, DELETE) in a retry manner.
///
/// In case of network problems ([SocketException] or [TimeoutException]),
/// this method will retry the HTTP operation N=15 times, with an increasing
/// delay time as 2^(N+1) * 5 secs (20, 40, , ..., 10.240).
/// I.e., maximum retry time is ca. three hours.
class HTTPRetry {
  final client = http.Client();

  /// Sends an generic HTTP [MultipartRequest] with the given headers to the given URL,
  /// which can be a [Uri] or a [String].
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
