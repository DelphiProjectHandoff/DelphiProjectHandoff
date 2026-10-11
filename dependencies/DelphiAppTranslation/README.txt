Pinned Atlas offline dependency for Delphi Project Handoff

The owner identified the local VCL2FMX project as the Atlas reference. Its
DelphiAppTranslation snapshot provides this Apache-2.0 runtime language-pack
reader. DPH keeps its own copy of the three required Pascal units and license.
SNAPSHOT.json records original paths, reference snapshot date and SHA256 hashes.
Original source bytes are preserved. VCL2FMX is not modified or required to build
or run DPH. No provider/cloud/client units are included.

DPH calls LoadFromJson on explicitly selected local UTF-8 bytes. It does not use
the DAT file-recovery writer, diagnostic file output or language-pack discovery.
The adapter validates the application ID, locale and file-size limit. Pack hashes
are part of the exact translation cache identity. These files are compiled into
the application; end users do not need to install a Delphi component package.

The three-phrase samples/translation pack demonstrates the interchange format.
It is incomplete and unreviewed. Source prose is retained when a translation is
missing. Human review remains required for localized wording.
