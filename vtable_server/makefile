
.PHONY: run
run:
	gunicorn --bind 0.0.0.0:8000 'vtable_server:build_app()'

.PHONY: install
install:
	pip install .

.PHONY: uninstall
uninstall:
	pip uninstall -y vtable_server .

.PHONY: reinstall
reinstall: uninstall install

lint:
	pylint -E ./src

test:
	newman run ./vtable_server.postman.json