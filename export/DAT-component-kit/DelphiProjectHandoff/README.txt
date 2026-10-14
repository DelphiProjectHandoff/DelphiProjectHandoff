DELPHI APP TRANSLATION - COMPONENT INTEGRATION KIT
==================================================

Target: DelphiProjectHandoff
Framework: FireMonkey

The Studio prepares the project-local dependency from this kit. It atomically installs the complete DAT source set under dependencies\DelphiAppTranslation\source, uses that folder temporarily for Studio-initiated builds, and deploys the current language packs directly. Target Pascal, DPR, DPROJ, DFM, and FMX files remain developer-owned and are never rewritten.

1. Choose Prepare / Update Dependencies. Repeating this operation refreshes one managed dependency folder without creating duplicate copies.
2. In RAD Studio, open Project > Options > Building > Delphi Compiler. For all configurations and platforms, add $(PROJECTDIR)\dependencies\DelphiAppTranslation\source to Search path. Keep all existing entries. The Studio deliberately does not edit the DPROJ.
3. After preparation, choose Show Design BPL. The Studio selects DesignPackages\Win32\Release\DATLanguageManagerFMXDesign.bpl inside this kit. The matching core and framework runtime BPLs are beside it.
4. In RAD Studio choose Component > Install Packages, then choose Add.
5. Select that exact design BPL and choose Open. Never use Install Component and never select a DPK.
6. Confirm the DAT Language Manager package is checked, then choose OK.
7. Open the target application and its primary form in the Form Designer.
8. Place one TDATFMXLanguageManager from the DAT Localization palette page.
9. Set ApplicationId to "DelphiProjectHandoff".
10. Leave LanguagesFolder as "Localization\Languages" and set SourceLanguage to "en-US".
11. Place one TDATFMXLanguageComboBox. In Object Inspector, set its LanguageManager property to the manager component. Do not leave this property blank. A visible selector is required unless the application provides an equivalent connected Language menu.
12. Build and test every platform and configuration you distribute. Changing the selector applies the language immediately and saves the preference.
13. For a portable, network, or USB installation, enter its full application folder on the Wizard Deployment page. Final processing and Wizard-initiated builds deploy it whenever the destination is available. The component property stays relative as Localization\Languages.

Ordinary forms need no component. For inherited or unusually renamed forms, configure FormIdentityMappings on the manager using FormClass=ScannerFormRoot entries.

The only package-registration action left to the developer is adding the verified design BPL through RAD Studio. The Studio deliberately does not register IDE packages on the developer's behalf.
