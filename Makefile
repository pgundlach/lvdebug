VERSION = 0.9
DESTDIR = lua-visual-debug
DOCDEST = $(DESTDIR)/doc
CP = cp -X

DATE_ISO = $(shell date +"%F")
DATE_TEX = $(shell date +"%Y\/%m\/%d")

all:
	@echo "make: dist doc zip clean"

dist: doc
	mkdir -p $(DESTDIR)
	mkdir -p $(DOCDEST)
	$(CP) README.md $(DOCDEST)
	$(CP) lua-visual-debug.sty $(DESTDIR)
	$(CP) lua-visual-debug.lua $(DESTDIR)
	$(CP) tmp/lvdebug-doc.tex tmp/lvdebug-doc.pdf $(DOCDEST)
	$(CP) sample.pdf sample.tex sample-plain.pdf sample-plain.tex $(DOCDEST)
	$(CP) *png $(DOCDEST)
	perl -pi -e 's/(lvdebugpkgversion)\{.*\}/$$1\{$(VERSION)\}/' $(DESTDIR)/lua-visual-debug.sty
	perl -pi -e 's/(lvdebugpkgdate)\{.*\}/$$1\{$(DATE_TEX)\}/' $(DESTDIR)/lua-visual-debug.sty
	perl -pi -e 's/(^-- Version:).*/$$1 $(VERSION)/' $(DESTDIR)/lua-visual-debug.lua
	perl -pi -e 's/(Package version:).*/$$1 $(VERSION)/' $(DOCDEST)/README.md
	rm -f $(DESTDIR)/README.md
	( cd $(DESTDIR) ; ln -s doc/README.md )



doc: texsample latexsample
	mkdir -p tmp
	rm -rf tmp/*
	cp lvdebug-doc.tex tmp
	perl -pi -e 's/(pkgversion)\{.*\}/$$1\{$(VERSION)\}/' tmp/lvdebug-doc.tex
	cp *png sample-plain.tex sample.tex sample-plain-crop.pdf sample-crop.pdf tmp
	( cd tmp ; lualatex lvdebug-doc.tex)
	( cd tmp ; lualatex lvdebug-doc.tex)

zip: clean dist
	-rm lvdebug-$(VERSION).tgz
	tar czvf lvdebug-$(VERSION).tgz $(DESTDIR)/*

clean:
	-rm -rf tmp $(DESTDIR)
	-rm sample-plain.pdf sample-plain-crop.pdf sample.pdf sample-crop.pdf
	find . -name ".DS_Store" -exec rm {} \;



sample-plain.pdf: sample-plain.tex
	luatex sample-plain.tex
	pdfcrop --margins "1 1 1 1" sample-plain.pdf

sample.pdf: sample.tex
	lualatex sample.tex
	pdfcrop --margins "1 1 1 1" sample.pdf

texsample: sample-plain.pdf
latexsample: sample.pdf
