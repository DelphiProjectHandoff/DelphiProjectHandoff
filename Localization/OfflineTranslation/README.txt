DPH OFFLINE PROJECT-TEXT TRANSLATION TRIAL

This folder contains the browser-based Bergamot 0.4.9 translation engine and
one English-to-German model. DPH uses these files only for marked project
prose in the Learn the project view when German (de-DE) is selected. All model
and engine requests stay on DPH's loopback-only local preview server. No
translation request is sent to an Internet service.

The engine package came from:
https://registry.npmjs.org/@browsermt/bergamot-translator/-/bergamot-translator-0.4.9.tgz
Unused package demo files were omitted, and trailing whitespace was removed
from two JavaScript source files. The engine behavior was not changed.

The three model files came from the ende entry of:
https://bergamot.s3.amazonaws.com/models/index.json

Model SHA-256 values, checked after download:
model.ende.intgemm.alphas.bin  b3e980d6602ab0bdfe8d9315cb5fc282a16bb1c8dccf38e70945c584551c4318
lex.50.50.ende.s2t.bin         f03eb8245042feb7a5800815b8d0dc215d7a60691632405b65c461d250cedbe6
vocab.deen.spm                 417668f2ed297970febafb5b079a9d5ebc4ed0b3550ac8386d67a90473a09bd7

The engine is licensed under MPL 2.0; see BERGAMOT-LICENSE.txt. The model
files are distributed by the Bergamot project. The original English project
content remains in the selected project's files and DPH's saved analysis.
Machine translation can be inaccurate and does not replace source evidence.
