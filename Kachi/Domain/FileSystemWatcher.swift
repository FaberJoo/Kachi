import Foundation
import CoreServices

/// Watches a directory tree for any file-system changes using FSEvents.
/// Calls `onChange` on the main queue, debounced by `latency` seconds.
final class FileSystemWatcher {

    // nonisolated(unsafe): FSEventStreamRef is a C opaque pointer; access is
    // guarded by the run-loop-scheduled stream callbacks always firing on the
    // main thread, and stop/deinit are called on the main thread as well.
    nonisolated(unsafe) private var stream: FSEventStreamRef?
    // Heap-allocated box so the C callback can reach it without capturing self.
    private let box: CallbackBox

    init(url: URL, latency: TimeInterval = 0.3, onChange: @escaping @MainActor () -> Void) {
        box = CallbackBox(onChange)
        start(url: url, latency: latency)
    }

    deinit {
        guard let s = stream else { return }
        FSEventStreamStop(s)
        FSEventStreamInvalidate(s)
        FSEventStreamRelease(s)
    }

    func stop() {
        guard let s = stream else { return }
        FSEventStreamStop(s)
        FSEventStreamInvalidate(s)
        FSEventStreamRelease(s)
        stream = nil
    }

    // MARK: - Private

    private func start(url: URL, latency: TimeInterval) {
        let paths = [url.path(percentEncoded: false)] as CFArray
        let retained = Unmanaged.passRetained(box).toOpaque()

        var ctx = FSEventStreamContext(
            version: 0,
            info: retained,
            retain: { ptr -> UnsafeRawPointer? in
                guard let ptr else { return nil }
                return UnsafeRawPointer(Unmanaged<CallbackBox>.fromOpaque(ptr).retain().toOpaque())
            },
            release: { ptr in
                guard let ptr else { return }
                Unmanaged<CallbackBox>.fromOpaque(ptr).release()
            },
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents
        )

        stream = FSEventStreamCreate(nil, fsEventsCallback, &ctx, paths,
                                     FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                     latency, flags)

        guard let s = stream else {
            Unmanaged<CallbackBox>.fromOpaque(retained).release()
            return
        }
        FSEventStreamScheduleWithRunLoop(s, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(s)
    }
}

// MARK: - Helpers

private final class CallbackBox: @unchecked Sendable {
    let fn: @MainActor () -> Void
    init(_ fn: @escaping @MainActor () -> Void) { self.fn = fn }
}

private let fsEventsCallback: FSEventStreamCallback = { _, info, _, _, _, _ in
    guard let info else { return }
    let box = Unmanaged<CallbackBox>.fromOpaque(info).takeUnretainedValue()
    Task { @MainActor in box.fn() }
}
