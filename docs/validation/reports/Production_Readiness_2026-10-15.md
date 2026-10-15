# Delphi Project Handoff: pre-production review

**Status:** Experimental 0.6.12, reviewed 15 October 2026. This is preparation for a future 1.0 release, not production acceptance.

## Changes completed in this pass

- Website reading now rejects privately resolved IPv4 hosts, keeps redirects disabled, and caps each response in the receiving stream at 128 KiB. The checkbox remains off by default.
- A compressed-document regression fixture verifies that an oversized ODT entry does not become displayed guide text. Existing DOCX/ODT readers already check the entry's declared expanded size before allocation.
- DPH's original code and documentation have an Apache 2.0 `LICENSE`. `THIRD_PARTY_NOTICES.md` separates bundled components; the unmodified Bergamot model files match the [project model index](https://bergamot.s3.amazonaws.com/models/index.json) by SHA-256 and carry the [project's CC BY-SA 4.0 model terms](https://github.com/browsermt/students/blob/master/LICENSE.md) and a local license copy.
- The user and engineering guides, HTML help, run directions, screen illustrations, source-hash report, and Windows/source package scripts have been updated. The final rendered manuals are 7 and 57 pages, with populated editable contents. A nearly empty trailing engineering page was removed.
- The learning regression's redundant WebView2 bitmap capture was removed after it stalled suite teardown. The full browser-enabled suite now exits successfully.

## Validation of the exact downloads

| Check | Result |
| --- | --- |
| Win32 Debug and Release application builds | Pass |
| Win64 Debug and Release application builds | Pass |
| Browser-enabled learning regression | 170 checks passed; report: `learning-refocus-learning-validation.json` |
| Source ZIP manifest and hashes | 457 files, verified |
| Fresh Win32 Release build from final source ZIP extraction | Pass |
| Windows ZIP file hashes and extraction | 145 entries, verified |
| Final extracted Win32 and Win64 startup | Both remained running for the smoke interval; validation instances closed |
| User/Engineering guide render and contents | 7/57 pages; rendered page images inspected |

The final source download is `DPH_v0_6_12_Source_Distribution_2026-10-15_133506.zip`, SHA-256 `6734AA22AB914E5EB377BA254413E3A79410255E76A0C0D1FDCC2628B4DCEEAF`. The final Windows download is `DPH-0.6.12-experimental-Windows.zip`, SHA-256 `3CCE1440CC56EEC121D834662D7D36BDD7FA707832315072D761F37CFBD9B59B`.

## Work still required before 1.0

1. **Network isolation:** The optional public-website path resolves a hostname before `THTTPClient` connects. DNS can change between those operations; a private destination could therefore evade the pre-check. The safe default is off, but production use needs a connection-level address check or a deliberately restricted retrieval design, plus controlled DNS-rebinding tests.
2. **Release identity and trust:** Both Windows executables are unsigned and expose no FileVersion/ProductVersion metadata. Add version resources and sign with a publisher certificate before presenting a production Windows download.
3. **Human acceptance:** No independent first-time learner has completed the guide checklist on a genuinely unfamiliar application in this pass. Test a small VCL and FMX project, and retain issues from actual users and screen sizes.
4. **Translation review:** The 35 offline interface packs and experimental local German project-text model need native-speaker and right-to-left layout review. Machine-translated project prose must not be treated as verified source evidence.
5. **Repeatability and scale:** Add automated build/package checks and measured time/memory budgets for representative small and large projects. Historical ZIPs remain in Git; plan repository-size management without rewriting public history or deleting published downloads.

The results above validate the experimental files and known boundaries. They do not constitute a production-readiness claim.
