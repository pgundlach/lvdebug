VERSION = 0.5
DESTDIR = ctan
DOCDEST = $(DESTDIR)/doc

DATE_ISO = $(shell date +"%F")
DATE_TEX = $(shell date +"%Y\/%m\/%d")

all:
	@echo "make: dist doc zip clean"

dist: doc
	mkdir -p $(DESTDIR)
	mkdir -p $(DOCDEST)
	cp README $(DOCDEST)
	cp lua-visual-debug.sty $(DESTDIR)
	cp lua-visual-debug.lua $(DESTDIR)
	cp tmp/lvdebug-doc.tex tmp/lvdebug-doc.pdf $(DOCDEST)
	cp sample.pdf sample.tex sample-plain.pdf sample-plain.tex $(DOCDEST)
	cp *png $(DOCDEST)
	perl -pi -e 's/(lvdebugpkgversion)\{.*\}/$$1\{$(VERSION)\}/' $(DESTDIR)/lua-visual-debug.sty
	perl -pi -e 's/(lvdebugpkgdate)\{.*\}/$$1\{$(DATE_TEX)\}/' $(DESTDIR)/lua-visual-debug.sty
	perl -pi -e 's/(^-- Version:).*/$$1 $(VERSION)/' $(DESTDIR)/lua-visual-debug.lua
	perl -pi -e 's/(Package version:).*/$$1 $(VERSION)/' $(DOCDEST)/README
	rm -f $(DESTDIR)/README
	( cd $(DESTDIR) ; ln -s $(DOCDEST)/README )



doc: texsample latexsample
	mkdir -p tmp
	rm -rf tmp/*
	cp lvdebug-doc.tex tmp
	perl -pi -e 's/(pkgversion)\{.*\}/$$1\{$(VERSION)\}/' tmp/lvdebug-doc.tex
	cp *png sample-plain.tex sample.tex sample-plain-crop.pdf sample-crop.pdf tmp
	( cd tmp ; lualatex lvdebug-doc.tex)
	( cd tmp ; lualatex lvdebug-doc.tex)

zip: clean dist
	tar czvf lvdebug-$(VERSION).tgz $(DESTDIR)/*

clean:
	-rm -rf tmp $(DESTDIR)
	-rm sample-plain.pdf sample-plain-crop.pdf sample.pdf sample-crop.pdf


sample-plain.pdf: sample-plain.tex
	luatex sample-plain.tex
	pdfcrop --margins "1 1 1 1" sample-plain.pdf

sample.pdf: sample.tex
	lualatex sample.tex
	pdfcrop --margins "1 1 1 1" sample.pdf

texsample: sample-plain.pdf
latexsample: sample.pdf
