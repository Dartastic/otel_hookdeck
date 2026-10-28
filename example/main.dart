// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_hookdeck/otel_hookdeck.dart';

/// Traces Hookdeck calls with OpenTelemetry.
///
/// `otel_hookdeck` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Hookdeck call in
/// [tracedHookdeck]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'hookdeck-example');

  // Wraps a Hookdeck API call in a CLIENT span.
  final hookdeckId = await tracedHookdeck<String>(
    operation: 'sources.create',
    invoke: () async {
      // Make the Hookdeck call here, then report what it returned.
      const id = 'hookdeck_8f3a2c';
      return const HookdeckCallResult(
          value: id,
          result: HookdeckResult(
              eventId: 'event_8f3a2c',
              requestId: 'request_8f3a2c',
              attemptId: 'attempt_8f3a2c',
              sourceId: 'source_8f3a2c',
              destinationId: 'destination_8f3a2c',
              connectionId: 'connection_8f3a2c',
              eventType: 'order.created',
              deliveryStatus: 'SUCCESSFUL',
              attemptNumber: 1,
              responseStatusCode: 201,
              responseLatencyMs: 120,
              bookmarkId: 'bookmark_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedHookdeck sources.create returned $hookdeckId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutHookdeckInstrumentationAsync.
  await runWithoutHookdeckInstrumentationAsync(
    () => tracedHookdeck<String>(
      operation: 'sources.create',
      invoke: () async {
        const id = 'hookdeck_8f3a2c';
        return const HookdeckCallResult(
            value: id,
            result: HookdeckResult(
                eventId: 'event_8f3a2c',
                requestId: 'request_8f3a2c',
                attemptId: 'attempt_8f3a2c',
                sourceId: 'source_8f3a2c',
                destinationId: 'destination_8f3a2c',
                connectionId: 'connection_8f3a2c',
                eventType: 'order.created',
                deliveryStatus: 'SUCCESSFUL',
                attemptNumber: 1,
                responseStatusCode: 201,
                responseLatencyMs: 120,
                bookmarkId: 'bookmark_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
