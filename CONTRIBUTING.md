# Contributing

Thanks for taking an interest in Study Block.

Before opening a pull request, please open an issue for substantial changes so
the scope can be agreed first. Keep each pull request focused, follow the
existing SwiftUI-first structure, and avoid broadening permissions or
enforcement behavior without making that change explicit.

Run the checks before submitting:

```sh
./script/run_smoke_tests.sh
./script/build_and_run.sh --verify
```

Please include a short description of the behavior you changed and how you
verified it.
