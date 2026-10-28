// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_hookdeck_suppression.dart';

const _tracerName = 'dartastic_otel_libs_hookdeck';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class HookdeckResult {
  /// Creates a result.
  const HookdeckResult({
    this.eventId,
    this.requestId,
    this.attemptId,
    this.sourceId,
    this.destinationId,
    this.connectionId,
    this.eventType,
    this.deliveryStatus,
    this.attemptNumber,
    this.responseStatusCode,
    this.responseLatencyMs,
    this.bookmarkId,
    this.statusCode,
  });

  final String? eventId;
  final String? requestId;
  final String? attemptId;

  /// Source identifies the inbound origin (a Stripe webhook, a GitHub
  /// payload, etc.).
  final String? sourceId;

  /// Destination is the downstream consumer endpoint Hookdeck delivers
  /// to.
  final String? destinationId;

  final String? connectionId;
  final String? eventType;

  /// `SUCCESSFUL` / `FAILED` / `PENDING` / `HOLD` / `QUEUED` /
  /// `IGNORED` / `BLOCKED`.
  final String? deliveryStatus;

  /// 1 for the first attempt; >1 for retries.
  final int? attemptNumber;

  /// Status code returned by the customer's destination endpoint.
  final int? responseStatusCode;

  final int? responseLatencyMs;

  /// Bookmark used to replay events.
  final String? bookmarkId;

  /// Hookdeck API status code (the control-plane call, not the delivery
  /// response).
  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class HookdeckCallResult<T> {
  /// Creates a call result.
  const HookdeckCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final HookdeckResult? result;
}

/// Wraps a Hookdeck API call in a CLIENT span. [operation] is one of
/// `events.list`, `events.retrieve`, `events.retry`, `attempts.list`,
/// `sources.create`, `destinations.create`, `connections.create`,
/// `bookmarks.create`, `bookmarks.trigger`, `requests.list`.
Future<T> tracedHookdeck<T>({
  required String operation,
  required Future<HookdeckCallResult<T>> Function() invoke,
}) async {
  if (hookdeckInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'hookdeck',
    'rpc.method': operation,
    'hookdeck.operation': operation,
  };

  final span = _tracer().startSpan(
    'hookdeck $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.eventId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.event.id',
          r.result!.eventId!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.attemptId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.attempt.id',
          r.result!.attemptId!,
        ));
      }
      if (r.result!.sourceId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.source.id',
          r.result!.sourceId!,
        ));
      }
      if (r.result!.destinationId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.destination.id',
          r.result!.destinationId!,
        ));
      }
      if (r.result!.connectionId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.connection.id',
          r.result!.connectionId!,
        ));
      }
      if (r.result!.eventType != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.event.type',
          r.result!.eventType!,
        ));
      }
      if (r.result!.deliveryStatus != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.delivery.status',
          r.result!.deliveryStatus!,
        ));
        if (r.result!.deliveryStatus == 'FAILED' ||
            r.result!.deliveryStatus == 'BLOCKED') {
          span.setStatus(
            SpanStatusCode.Error,
            'Hookdeck delivery ${r.result!.deliveryStatus}',
          );
        }
      }
      if (r.result!.attemptNumber != null) {
        extras.add(OTelAPI.attributeInt(
          'hookdeck.attempt.number',
          r.result!.attemptNumber!,
        ));
      }
      if (r.result!.responseStatusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'hookdeck.response.status_code',
          r.result!.responseStatusCode!,
        ));
      }
      if (r.result!.responseLatencyMs != null) {
        extras.add(OTelAPI.attributeInt(
          'hookdeck.response.latency_ms',
          r.result!.responseLatencyMs!,
        ));
      }
      if (r.result!.bookmarkId != null) {
        extras.add(OTelAPI.attributeString(
          'hookdeck.bookmark.id',
          r.result!.bookmarkId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Hookdeck HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
