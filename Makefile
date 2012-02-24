dist: latexsample texsample doc zip

doc:
	lualatex lvdebug-doc.tex

zip:
	cd ../ ; zip lvdebug.zip lvdebug/README lvdebug/lvdebug-doc.pdf lvdebug/lvdebug-doc.tex lvdebug/sample.tex lvdebug/sample.pdf lvdebug/sample-plain.tex lvdebug/sample-plain.pdf lvdebug/lua-visual-debug.lua lvdebug/lua-visual-debug.sty

texsample:
	luatex sample-plain.tex
	pdfcrop --margins "1 1 1 1" sample-plain.pdf

latexsample:
	lualatex sample.tex
	pdfcrop --margins "1 1 1 1" sample.pdf
