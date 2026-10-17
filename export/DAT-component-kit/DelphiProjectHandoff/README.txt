DELPHI APP TRANSLATION - DPH SOURCE-BUILD INSTRUCTIONS
=====================================================

These steps are for a developer opening DelphiProjectHandoff.dproj in RAD
Studio 37. They use ordinary RAD Studio commands. There is no separate
"Prepare / Update Dependencies" command in RAD Studio.

1. Extract the complete DPH source distribution to a writable local folder.
   Keep this kit and dependencies\DelphiAppTranslation\source in place. The
   DPH project already names that source folder in its compiler search path.
2. Before opening DPH.UI.Main.fmx in the Form Designer, start RAD Studio and
   choose Component > Install Packages. Click Add and select:
   export\DAT-component-kit\DelphiProjectHandoff\DesignPackages\Win32\Release\DATLanguageManagerFMXDesign.bpl
   The two accompanying runtime BPL files must remain beside the design BPL.
   Check that the DAT Language Manager package is enabled, then click OK.
   Restart RAD Studio if it requests a restart.
3. Open DelphiProjectHandoff.dproj. Its main form contains an existing
   TDATFMXLanguageManager and TDATFMXLanguageComboBox. You do not need to
   place another copy of either control.
4. Build the desired Win32 or Win64, Debug or Release configuration. Run the
   corresponding executable under bin\<platform>\<configuration>. Keep
   WebView2Loader.dll beside the executable and the Localization, migrations,
   help, and images and icons folders in the extracted source root.

If the designer reports either DAT control class as missing, close the form,
return to Component > Install Packages, and confirm that the design package
in step 2 is listed and checked. Do not remove the controls from the form.
If compilation reports a missing DAT unit, confirm that the complete
dependencies\DelphiAppTranslation\source folder exists and that Project >
Options > Building > Delphi Compiler > Search path contains its path. The
checked-in DPROJ already supplies this entry for normal builds.

This kit also contains component source and language packs for integration
work on other projects. DPH itself already includes the matching dependency
source and its language packs; copying the kit over the DPH files is not a
normal build step.
