
.PHONY: install
install:
	pip install .

.PHONY: uninstall
uninstall:
	pip uninstall -y vtable_lib .

.PHONY: reinstall
reinstall: uninstall install

lint:
	pylint -E ./src
