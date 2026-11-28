#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "37b58b8df9f38acd9435a17dd3e29a22a748017cdd7b05e4a5ad4a44b7204554", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "perl6"}
# peak-limiter.css — portiert nach perl6
# Quelle: css, Projects@abstractions:css/peak-limiter.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "raku"}
# peak-limiter.html — portiert nach raku
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

sub create-css() {
    my $css = q:to/END/;
body {
  font: 16px system-ui;
  max-width: 1000px;
  margin: 40px auto;
  padding: 20px;
}

pre {
  white-space: pre-wrap;
}

button {
  padding: 12px;
}
END
    return $css;
}

sub MAIN($output-file) {
    my $css-content = create-css();
    spurt($output-file, $css-content);
}
