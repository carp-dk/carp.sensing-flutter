# Transportation Example

A runnable Flutter app showing the CARP transportation sampling package end to
end: the phone samples its own location, a mocked ML pipeline turns each batch
of locations into transportation samples, and everything is stored in a local
SQLite database on the phone.

## What it does

```
LocationService (distance: 0)  ->  15 x Location
        |                                |
        | ConditionalSamplingEventTrigger | buffers each location,
        | fires on the 15th               | fires when the batch is full
        v                                v
FunctionTask 'Mode Inference'  ->  15 x TransportationSample  ->  SQLite
```

* **Location sampling** - `LocationService` is configured with `distance: 0`, so
  every location update from the OS is collected, not only moves of more than
  N meters. Batches therefore fill up while standing still too.
* **Batching** - a `ConditionalSamplingEventTrigger` on the location data type
  buffers each `Location` and triggers once
  `TransportationPipeline.batchSize` (15) of them are buffered.
* **Inference** - the triggered `FunctionTask` runs the pipeline over the batch,
  emitting one `TransportationSample` per buffered location, 1:1: same
  coordinates, altitude, accuracy, speed, heading and timestamp, plus the model
  output. The model output is **mocked** - the mode comes from a speed
  threshold, and the probabilities and embedding are random - so the app runs
  without a real model. Everything else is a real GPS fix.
* **Storage** - a `SQLiteDataEndPoint` writes all measurements (both the raw
  locations and the transportation samples) to `carp-data.db` on the phone.

The UI shows the study status and database path, how many locations are buffered
towards the next batch, a per-data-type counter, and a live log of every
measurement - tap one to see the exact JSON that is stored. The toolbar's
storage icon reads the counts back out of SQLite.

## Running it

```sh
flutter run
```

Grant the location permission when asked; without it, the location service
cannot connect and no data is collected.

## Files

| File | Contents |
|---|---|
| `lib/main.dart` | the Flutter UI |
| `lib/sensing.dart` | the study protocol, the trigger, and the SQLite queries |
| `lib/transportation_pipeline.dart` | location buffering and the mocked inference |
| `test/transportation_pipeline_test.dart` | checks the batching and the 1:1 match |

## Notes

* Studies are persisted by CAMS and restored on the next launch. This example
  builds its protocol in Dart, and a `ConditionalSamplingEventTrigger`'s
  condition is a Dart function which cannot be serialized - a restored study
  would sample location but never run inference. The example therefore removes
  previously stored studies on startup. Collected data in `carp-data.db` is
  kept.
* Location permission is requested via `permission_handler` before the client
  is configured. CAMS connects the location service when the study is deployed
  and does not retry, so the permission has to be in place first.
