# PASUPASASTRA user manual (Indonesian): make  ->  ../PASUPASASTRA-Manual-Pengguna.pdf
.PHONY: pdf clean
pdf:
	latexmk -xelatex -interaction=nonstopmode -halt-on-error manual.tex
	cp manual.pdf ../PASUPASASTRA-Manual-Pengguna.pdf
clean:
	latexmk -C
