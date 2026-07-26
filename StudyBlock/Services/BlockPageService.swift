import Foundation

struct BlockPageService {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.fileURL = base
                .appendingPathComponent("Study Block", isDirectory: true)
                .appendingPathComponent("block.html")
        }
    }

    func prepare() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Self.html.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func url(
        blockedDomain: String,
        sessionStartDate: Date,
        sessionEndDate: Date?
    ) -> URL {
        var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "domain", value: blockedDomain),
            URLQueryItem(
                name: "start",
                value: String(Int(sessionStartDate.timeIntervalSince1970 * 1_000))
            ),
            URLQueryItem(
                name: "end",
                value: sessionEndDate.map {
                    String(Int($0.timeIntervalSince1970 * 1_000))
                }
            )
        ]
        return components.url!
    }

    private static let html = """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Back to focus · Study Block</title>
      <style>
        :root { color-scheme: dark; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
        * { box-sizing: border-box; }
        body {
          margin: 0; min-height: 100vh; display: grid; place-items: center;
          color: #f2f1ec; background:
            radial-gradient(circle at 50% 35%, rgba(82, 97, 124, .22), transparent 38%),
            #0d1016;
        }
        main { width: min(620px, calc(100vw - 48px)); text-align: center; }
        .ring {
          width: 74px; height: 74px; margin: 0 auto 28px; border-radius: 50%;
          border: 2px solid #8291aa; display: grid; place-items: center;
          box-shadow: 0 0 36px rgba(110, 132, 168, .18);
        }
        .ring::after { content: "◷"; font-size: 32px; color: #b8c3d6; }
        h1 { margin: 0 0 12px; font-size: clamp(34px, 6vw, 54px); letter-spacing: -.035em; }
        p { margin: 0; color: #aeb5c2; font-size: 18px; line-height: 1.55; }
        #domain { color: #d8dde6; }
        #time { margin-top: 30px; font-size: 44px; font-variant-numeric: tabular-nums; }
        .label { margin-top: 4px; color: #747d8d; font-size: 13px; letter-spacing: .08em; text-transform: uppercase; }
      </style>
    </head>
    <body>
      <main>
        <div class="ring" aria-hidden="true"></div>
        <h1>Stay with the work.</h1>
        <p><span id="domain">This site</span> can wait. Your focus session is still running.</p>
        <div id="time">00:00</div>
        <div class="label" id="label">time remaining</div>
      </main>
      <script>
        const params = new URLSearchParams(location.search);
        const domain = params.get("domain");
        const start = Number(params.get("start"));
        const end = Number(params.get("end"));
        const isOpenEnded = !params.get("end");
        if (domain) document.querySelector("#domain").textContent = domain;
        if (isOpenEnded) document.querySelector("#label").textContent = "time focused";
        function tick() {
          const seconds = isOpenEnded
            ? Math.max(0, Math.floor((Date.now() - start) / 1000))
            : Math.max(0, Math.ceil((end - Date.now()) / 1000));
          const minutes = Math.floor(seconds / 60);
          const remainder = String(seconds % 60).padStart(2, "0");
          document.querySelector("#time").textContent = `${String(minutes).padStart(2, "0")}:${remainder}`;
        }
        tick();
        setInterval(tick, 250);
      </script>
    </body>
    </html>
    """
}
