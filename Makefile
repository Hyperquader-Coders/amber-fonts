# amber-fonts — the suite's typefaces, packaged once for copal, kat800 and amberlin.

VERSION = 0.1.0
# The finished package. amberlinux-apt ingests it via `make deb-path`;
# amberlinux-apt/docs/PACKAGING.md is the shared target contract.
# Architecture: all — a font is the same bytes on every machine.
DEB = dist/amber-fonts_$(VERSION)-1_all.deb
BRANCH ?= main
REMOTE ?= origin
ROOT_COMMIT_MSG ?= Initial amber-fonts

# One directory per upstream project, mirrored into the package. The two
# SauceCodePro families share theirs — distinct families, distinct filenames.
FONTROOT = packaging/fonts/truetype
INSTROOT = usr/share/fonts/truetype

NERD_DIR  = saucecodepro-nerd
CODE_DIR  = source-code-pro
SANS_DIR  = source-sans-3
SERIF_DIR = source-serif-4
FONT_DIRS = $(NERD_DIR) $(CODE_DIR) $(SANS_DIR) $(SERIF_DIR)

# The families whose upstream licence file sits beside their faces. The two
# SauceCodePro families are not among them: theirs is packaging/fonts/OFL.txt,
# one directory up, where a single copy covers both.
OFL_DIRS = $(CODE_DIR) $(SANS_DIR) $(SERIF_DIR)

NERD_FACES = \
	SauceCodeProNerdFont-Regular.ttf \
	SauceCodeProNerdFont-Bold.ttf \
	SauceCodeProNerdFont-Italic.ttf \
	SauceCodeProNerdFont-BoldItalic.ttf \
	SauceCodeProNerdFontMono-Regular.ttf \
	SauceCodeProNerdFontMono-Bold.ttf \
	SauceCodeProNerdFontMono-Italic.ttf \
	SauceCodeProNerdFontMono-BoldItalic.ttf

CODE_FACES = \
	SourceCodePro-Regular.ttf \
	SourceCodePro-Bold.ttf \
	SourceCodePro-It.ttf \
	SourceCodePro-BoldIt.ttf

SANS_FACES = \
	SourceSans3-Regular.ttf \
	SourceSans3-Bold.ttf \
	SourceSans3-It.ttf \
	SourceSans3-BoldIt.ttf

SERIF_FACES = \
	SourceSerif4-Regular.ttf \
	SourceSerif4-Bold.ttf \
	SourceSerif4-It.ttf \
	SourceSerif4-BoldIt.ttf

# Every face as <dir>/<file>, which is its path under $(FONTROOT) and under
# $(INSTROOT) alike.
FACES = \
	$(addprefix $(NERD_DIR)/,$(NERD_FACES)) \
	$(addprefix $(CODE_DIR)/,$(CODE_FACES)) \
	$(addprefix $(SANS_DIR)/,$(SANS_FACES)) \
	$(addprefix $(SERIF_DIR)/,$(SERIF_FACES))

.PHONY: deps check build lint ci deb deb-path deb-install deb-remove clean push force-push check-no-agent-files

# Nothing is compiled, so the build dependencies are the packaging tools only.
deps:
	sudo apt install dpkg-dev fontconfig shellcheck

# A missing face is a silent Pango fallback at runtime, not an error.
check:
	@for f in $(FACES); do \
		test -f "$(FONTROOT)/$$f" || { echo "check: missing $(FONTROOT)/$$f"; exit 1; }; \
		case "$$(file -b --mime-type "$(FONTROOT)/$$f")" in \
			font/*|application/font*|application/x-font*) ;; \
			*) echo "check: $$f is not a font ($$(file -b "$(FONTROOT)/$$f"))"; exit 1 ;; \
		esac; \
	done
	@for d in $(OFL_DIRS); do \
		test -f "$(FONTROOT)/$$d/OFL.txt" || { echo "check: missing $(FONTROOT)/$$d/OFL.txt"; exit 1; }; \
	done
	@echo "check: $(words $(FACES)) faces present in $(words $(FONT_DIRS)) directories"

build: check

# Consumers ask fontconfig for the family name, not the filename. Assert it (Rule 7).
lint: deb check
	@command -v fc-query >/dev/null || { echo "lint: needs fontconfig"; exit 1; }
	@for f in $(FONTROOT)/$(NERD_DIR)/SauceCodeProNerdFont-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "SauceCodePro Nerd Font" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'SauceCodePro Nerd Font'"; exit 1; }; \
	done
	@for f in $(FONTROOT)/$(NERD_DIR)/SauceCodeProNerdFontMono-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "SauceCodePro Nerd Font Mono" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'SauceCodePro Nerd Font Mono'"; exit 1; }; \
	done
	@for f in $(FONTROOT)/$(CODE_DIR)/SourceCodePro-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "Source Code Pro" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'Source Code Pro'"; exit 1; }; \
	done
	@for f in $(FONTROOT)/$(SANS_DIR)/SourceSans3-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "Source Sans 3" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'Source Sans 3'"; exit 1; }; \
	done
	@for f in $(FONTROOT)/$(SERIF_DIR)/SourceSerif4-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "Source Serif 4" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'Source Serif 4'"; exit 1; }; \
	done
	@grep -q "SIL Open Font License" packaging/fonts/OFL.txt \
		|| { echo "lint: OFL.txt does not contain the licence text"; exit 1; }
	@for d in $(OFL_DIRS); do \
		grep -q "SIL Open Font License" "$(FONTROOT)/$$d/OFL.txt" \
			|| { echo "lint: $$d/OFL.txt does not contain the licence text"; exit 1; }; \
		grep -q "Reserved Font Name" "$(FONTROOT)/$$d/OFL.txt" \
			|| { echo "lint: $$d/OFL.txt does not state its Reserved Font Name"; exit 1; }; \
	done
	@for d in $(FONT_DIRS); do \
		grep -q "$$d" packaging/debian/copyright \
			|| { echo "lint: $$d has no Files: stanza in packaging/debian/copyright"; exit 1; }; \
		grep -q "$$d" packaging/fonts/SOURCES \
			|| { echo "lint: $$d has no entry in packaging/fonts/SOURCES"; exit 1; }; \
	done
	@echo "lint: every family reports its expected name; licence and provenance declared"
	@if command -v shellcheck >/dev/null; then \
		git ls-files | while read -r f; do \
			case "$$f" in *.sh|*.bash) echo "$$f";; \
			*) head -1 "$$f" 2>/dev/null | grep -q '^#!.*sh' && echo "$$f";; esac; \
		done | xargs -r shellcheck --severity=warning && echo "shellcheck OK"; \
	else echo "shellcheck not installed — skipping (apt install shellcheck)"; fi
	@if command -v lintian >/dev/null; then lintian --no-tag-display-limit -L '>=pedantic' $(DEB); \
	else echo "lintian not installed — skipping (apt install lintian)"; fi

ci: check build lint deb
	@echo "CI OK"

# Face by face, not `cp -r`: that carries OFL.txt into /usr/share/fonts and gives
# directories the builder's umask. Both are lintian warnings.
deb: check
	rm -rf out/deb
	@for d in $(FONT_DIRS); do install -d -m755 "out/deb/$(INSTROOT)/$$d" || exit 1; done
	@for f in $(FACES); do \
		install -m644 "$(FONTROOT)/$$f" "out/deb/$(INSTROOT)/$$f" || exit 1; \
	done
	install -D -m644 packaging/fonts/OFL.txt out/deb/usr/share/doc/amber-fonts/OFL.txt
	install -D -m644 $(FONTROOT)/$(CODE_DIR)/OFL.txt out/deb/usr/share/doc/amber-fonts/OFL-$(CODE_DIR).txt
	install -D -m644 $(FONTROOT)/$(SANS_DIR)/OFL.txt out/deb/usr/share/doc/amber-fonts/OFL-$(SANS_DIR).txt
	install -D -m644 $(FONTROOT)/$(SERIF_DIR)/OFL.txt out/deb/usr/share/doc/amber-fonts/OFL-$(SERIF_DIR).txt
	install -D -m644 LICENSE out/deb/usr/share/doc/amber-fonts/LICENSE
	install -D -m644 packaging/lintian-overrides out/deb/usr/share/lintian/overrides/amber-fonts
	install -D -m644 packaging/debian/copyright out/deb/usr/share/doc/amber-fonts/copyright
	# A redirect uses the builder's umask, not 0644.
	gzip -9n < packaging/debian/changelog > out/deb/usr/share/doc/amber-fonts/changelog.Debian.gz
	chmod 644 out/deb/usr/share/doc/amber-fonts/changelog.Debian.gz
	mkdir -p out/deb/DEBIAN
	cd out/deb && find . -type f -not -path './DEBIAN/*' -printf '%P\n' | sort | xargs md5sum > DEBIAN/md5sums
	sed -e 's/@VERSION@/$(VERSION)/' \
		-e "s/@SIZE@/$$(du -sk out/deb --exclude=DEBIAN | cut -f1)/" \
		packaging/control.in > out/deb/DEBIAN/control
	mkdir -p dist
	dpkg-deb --build --root-owner-group out/deb $(DEB)

# Where `make deb` puts the package: one absolute path, nothing else.
deb-path:
	@echo "$(CURDIR)/$(DEB)"

# No fc-cache, no maintainer scripts: fontconfig's dpkg trigger on
# /usr/share/fonts does it (maintainer-script-updates-fontconfig-cache-improperly).
deb-install: deb
	sudo apt install --reinstall ./$(DEB)

deb-remove:
	sudo apt remove amber-fonts

push:
	git push "$(REMOTE)" "$(BRANCH)"

# Agent files are never published. Two ways they get in: already tracked, or
# present-and-unignored when `git add -A` below sweeps the whole tree. Both are
# checked here, because a squashed history shows no file being added — a stray
# path simply appears in the root commit as though it always belonged.
check-no-agent-files:
	@bad=$$(git ls-files | grep -E '(^|/)(\.mcp\.json|\.claude/|\.claude-amber/)' || true); \
	if [ -n "$$bad" ]; then \
		echo "agent files are tracked and must not be published:"; \
		printf '  %s\n' $$bad; \
		echo "fix: git rm -r --cached <path>, then add it to .gitignore"; \
		exit 2; \
	fi
	@for p in .mcp.json .claude .claude-amber; do \
		if [ -e "$$p" ] && ! git check-ignore -q "$$p"; then \
			echo "$$p exists and is not gitignored — 'git add -A' would publish it"; \
			echo "fix: add $$p to .gitignore"; \
			exit 2; \
		fi; \
	done
	@echo "no agent files staged for publication"

force-push: check check-no-agent-files
	@test -z "$$(git status --porcelain)" || { \
		echo "Working tree is dirty. Commit, stash, or revert changes first."; \
		exit 2; \
	}
	@orig_branch="$$(git branch --show-current)"; \
	tmp_branch="root-squash-$$(date +%s)"; \
	git checkout --orphan "$$tmp_branch"; \
	git add -A; \
	git commit -S -m "$(ROOT_COMMIT_MSG)"; \
	git branch -D "$(BRANCH)" 2>/dev/null || true; \
	git branch -m "$(BRANCH)"; \
	git push --force --set-upstream "$(REMOTE)" "$(BRANCH)"; \
	echo "Rewrote $$orig_branch as signed root commit on $(REMOTE)/$(BRANCH)."

clean:
	rm -rf out dist
