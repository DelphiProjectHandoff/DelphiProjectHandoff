DPH OFFLINE PROJECT-TEXT TRANSLATION TRIAL

This folder contains the browser-based Bergamot 0.4.9 translation engine and
English-to-Bulgarian, Czech, French, German, Italian, Portuguese, Russian,
Spanish, and Ukrainian models. DPH uses them for marked project prose in the
Handoff dossier, Learning library, and source-linked explanations when the
matching language is selected. Code, paths, and identifiers stay in their
original form. Model and engine requests stay on DPH's loopback-only local
preview server. No project text is sent to an Internet translation service.

The engine package came from:
https://registry.npmjs.org/@browsermt/bergamot-translator/-/bergamot-translator-0.4.9.tgz
Unused package demo files were omitted, and trailing whitespace was removed
from two JavaScript source files. The engine behavior was not changed.

The unmodified model files came from the matching language-pair entries of:
https://bergamot.s3.amazonaws.com/models/index.json
Each model, shortlist, and vocabulary file was checked against the source
index's SHA-256 value after download. Original URLs and expected hashes are
recorded in model-provenance.json. German files remain at model/; the other
pairs are in model/enbg, encs, enes, enfr, enit, enpt, enru, and enuk.
Ukrainian uses separate source and target vocabularies.

The engine is licensed under MPL 2.0; see BERGAMOT-LICENSE.txt. The models
are distributed under CC BY-SA 4.0; see MODEL-LICENSE.txt and
https://github.com/browsermt/students/blob/master/LICENSE.md.

The original project content remains in the selected project's files and
DPH's saved analysis. Machine translation can be inaccurate and does not
replace source evidence. The other language packs translate DPH interface
text but do not yet have a bundled arbitrary-prose model. V7's 35-language
pack system likewise does not translate arbitrary external source files or
documents.
