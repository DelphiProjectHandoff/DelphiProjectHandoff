Delphi App Translation v2 dependency for Delphi Project Handoff

DPH uses the DAT FireMonkey language manager and language selector on its
editable main form. The 14 Pascal units in source are pinned to the local
VCL2FMXConverter v7 dependency, including its right-to-left reading-direction
correction. DPH builds against this local source and runs with its own language
packs in Localization\Languages; neither VCL2FMXConverter nor a translation
provider is required on a user's computer.

The three Pascal units beside this README remain for older DPH publishing and
test scripts. The current DPH project and current test scripts search source
first. SNAPSHOT.json records each bundled source path and SHA-256 digest.

The DAT component integration kit in export\DAT-component-kit contains the
RAD Studio 37 FMX design package and setup instructions. Install that package
to edit the language manager and selector in the Object Inspector. End users
only need the built DPH executable and the language packs. The license for
this dependency is in LICENSE.
