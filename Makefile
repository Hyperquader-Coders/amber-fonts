# amber-fonts — the suite's typeface, packaged once for copal, kat800 and amberlin.

VERSION = 0.1.0
# The finished package. amberlinux-apt ingests it via `make deb-path`;
# amberlinux-apt/docs/PACKAGING.md is the shared target contract.
# Architecture: all — a font is the same bytes on every machine.
DEB = dist/amber-fonts_$(VERSION)-1_all.deb
BRANCH ?= main
REMOTE ?= origin
ROOT_COMMIT_MSG ?= Initial amber-fonts

FONTDIR = packaging/fonts/truetype/saucecodepro-nerd
# Both families share this directory: distinct families, distinct filenames.
INSTDIR = usr/share/fonts/truetype/saucecodepro-nerd

FACES = \
	SauceCodeProNerdFont-Regular.ttf \
	SauceCodeProNerdFont-Bold.ttf \
	SauceCodeProNerdFont-Italic.ttf \
	SauceCodeProNerdFont-BoldItalic.ttf \
	SauceCodeProNerdFontMono-Regular.ttf \
	SauceCodeProNerdFontMono-Bold.ttf \
	SauceCodeProNerdFontMono-Italic.ttf \
	SauceCodeProNerdFontMono-BoldItalic.ttf

.PHONY: deps check build lint ci deb deb-path deb-install deb-remove clean push force-push check-no-agent-files

# Nothing is compiled, so the build dependencies are the packaging tools only.
deps:
	sudo apt install dpkg-dev fontconfig shellcheck

# A missing face is a silent Pango fallback at runtime, not an error.
check:
	@for f in $(FACES); do \
		test -f "$(FONTDIR)/$$f" || { echo "check: missing $(FONTDIR)/$$f"; exit 1; }; \
		case "$$(file -b --mime-type "$(FONTDIR)/$$f")" in \
			font/*|application/font*|application/x-font*) ;; \
			*) echo "check: $$f is not a font ($$(file -b "$(FONTDIR)/$$f"))"; exit 1 ;; \
		esac; \
	done
	@echo "check: $(words $(FACES)) faces present"

build: check

# Consumers ask fontconfig for the family name, not the filename. Assert it (Rule 7).
lint: deb check
	@command -v fc-query >/dev/null || { echo "lint: needs fontconfig"; exit 1; }
	@for f in $(FONTDIR)/SauceCodeProNerdFont-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "SauceCodePro Nerd Font" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'SauceCodePro Nerd Font'"; exit 1; }; \
	done
	@for f in $(FONTDIR)/SauceCodeProNerdFontMono-*.ttf; do \
		fam=$$(fc-query -f '%{family[0]}' "$$f"); \
		[ "$$fam" = "SauceCodePro Nerd Font Mono" ] \
			|| { echo "lint: $$f reports family '$$fam', expected 'SauceCodePro Nerd Font Mono'"; exit 1; }; \
	done
	@grep -q "SIL Open Font License" packaging/fonts/OFL.txt \
		|| { echo "lint: OFL.txt does not contain the licence text"; exit 1; }
	@grep -q "saucecodepro-nerd" packaging/debian/copyright \
		|| { echo "lint: the fonts have no Files: stanza in packaging/debian/copyright"; exit 1; }
	@echo "lint: both families report their expected names; licence declared"
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
	install -d -m755 out/deb/$(INSTDIR)
	@for f in $(FACES); do \
		install -m644 "$(FONTDIR)/$$f" "out/deb/$(INSTDIR)/$$f" || exit 1; \
	done
	install -D -m644 packaging/fonts/OFL.txt out/deb/usr/share/doc/amber-fonts/OFL.txt
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
