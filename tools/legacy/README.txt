Historical Python scripts moved from bin on 2026-10-13.

These scripts record one-time implementation, validation, and guide-generation
work. They are not part of the DPH application or its normal build. Run a
specific script only after reviewing its contents: some modify project files.
Scripts that locate the repository through __file__ were updated for this
folder depth. Scripts that use Path.cwd() still expect the repository root as
their working directory. Current maintained scripts remain in tools.

Keep future Python utilities under tools, not bin. The bin folder is for
compiled output and distribution artifacts.
