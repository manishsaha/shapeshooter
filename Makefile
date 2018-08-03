build:
	ocamlbuild -use-ocamlfind main.byte -tag debug
	js_of_ocaml _build/main.byte -I _build/ --no-inline --debug-info --pretty -o static/js/main.js

worker:
	ocamlbuild -use-ocamlfind boss.byte state_worker.byte -tag debug
	js_of_ocaml _build/boss.byte -I _build/ --no-inline --debug-info --pretty -o static/js/main.js
	js_of_ocaml _build/state_worker.byte -I _build/ --no-inline --debug-info --pretty -o static/js/worker.js

test:
	ocamlbuild -use-ocamlfind test.byte && ./test.byte

clean:
	ocamlbuild -clean
	rm static/js/main.js

server:
	python app.py
