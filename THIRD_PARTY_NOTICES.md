# Third-party components

Delphi Project Handoff's original source code and documentation are available under the Apache License 2.0 license in [LICENSE](LICENSE). That license does not replace the terms of bundled components or of a Delphi project selected for analysis.

| Component | Where used | License or provenance |
| --- | --- | --- |
| DelphiAppTranslation | `dependencies/DelphiAppTranslation` and the editable component kit | Its bundled `LICENSE` (Apache 2.0). |
| Microsoft WebView2 loader | `tools/WebView2` and Windows packages | `tools/WebView2/LICENSE.txt`. The WebView2 Runtime is supplied by Microsoft separately. |
| Bergamot translation engine | `Localization/OfflineTranslation/package` | `Localization/OfflineTranslation/BERGAMOT-LICENSE.txt` (MPL 2.0); package origin and version are recorded in the adjacent `README.txt`. |
| English-to-German translation model | `Localization/OfflineTranslation/model` | Bergamot project model, [CC BY-SA 4.0](Localization/OfflineTranslation/MODEL-LICENSE.txt). The [Bergamot model terms](https://github.com/browsermt/students/blob/master/LICENSE.md), [original model index](https://bergamot.s3.amazonaws.com/models/index.json), unmodified file hashes and provenance are recorded in `Localization/OfflineTranslation/README.txt`. |

The experimental Windows ZIP and source ZIP each include the notices and licenses relevant to their contents. A recipient should review these terms before redistributing a modified package.
