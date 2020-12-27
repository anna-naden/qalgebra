.PHONY: help clean clean-build clean-pyc clean-test clean-venv flake8-check pylint-check test test38 test39 docs docs-pdf clean-docs black-check black isort-check isort coverage test-upload upload release dist dist-check notebooks jupyter-notebook jupyter-lab

.DEFAULT_GOAL := help

TOXOPTIONS ?=
TOXINI ?= tox.ini
TOX = tox -c $(TOXINI) $(TOXOPTIONS)

# empty TESTS delegates to TOXINI
TESTS ?=

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
    match = re.match(r'^([a-z0-9A-Z_-]+):.*?## (.*)$$', line)
    if match:
        target, help = match.groups()
        print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:  ## show this help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

bootstrap: ## verify that tox is available and pre-commit hooks are active
	python scripts/bootstrap.py

clean: ## remove all build, docs, test, and coverage artifacts, as well as tox environments
	python scripts/clean.py all

clean-build: ## remove build artifacts
	python scripts/clean.py build

clean-tests: ## remove test and coverage artifacts
	python scripts/clean.py tests

clean-venv: ## remove tox virtual environments
	python scripts/clean.py venv

clean-docs: ## remove documentation artifacts
	python scripts/clean.py docs

flake8-check: bootstrap ## check style with flake8
	$(TOX) -e run-flake8

pylint-check: bootstrap ## check style with pylint
	$(TOX) -e run-pylint


test: bootstrap ## run tests for all supported Python versions
	$(TOX) -e py38-test -- $(TESTS)

test38: bootstrap ## run tests for Python 3.8
	$(TOX) -e py38-test -- $(TESTS)

test39: bootstrap ## run tests for Python 3.9
	$(TOX) -e py39-test -- $(TESTS)

docs: bootstrap ## generate Sphinx HTML documentation, including API docs
	$(TOX) -e docs
	@echo "open docs/_build/html/index.html"

docs-pdf: bootstrap ## generate Sphinx PDF documentation, via latex
	$(TOX) -e docs -- -b latex docs/_build/latex
	$(TOX) -e run-cmd -- python docs/sources/build_pdf.py docs/_build/latex/qalgebra.tex

black-check: bootstrap ## Check all src and test files for complience to "black" code style
	$(TOX) -e run-blackcheck

black: bootstrap ## Apply 'black' code style to all src and test files
	$(TOX) -e run-black

isort-check: bootstrap ## Check all src and test files for correctly sorted imports
	$(TOX) -e run-isortcheck

isort: bootstrap ## Sort imports in all src and test files
	$(TOX) -e run-isort

coverage: test38  ## generate coverage report in ./htmlcov
	$(TOX) -e coverage
	@echo "open htmlcov/index.html"

test-upload: bootstrap clean-build dist ## package and upload a release to test.pypi.org
	$(TOX) -e run-cmd -- twine check dist/*
	$(TOX) -e run-cmd -- twine upload --repository-url https://test.pypi.org/legacy/ dist/*

upload: bootstrap clean-build dist ## package and upload a release to pypi.org
	$(TOX) -e run-cmd -- twine check dist/*
	$(TOX) -e run-cmd -- twine upload dist/*

release: bootstrap ## Create a new version, package and upload it
	python3.8 -m venv .venv/release
	.venv/release/bin/python -m pip install click gitpython pytest
	.venv/release/bin/python ./scripts/release.py

dist: bootstrap ## builds source and wheel package
	$(TOX) -e run-cmd -- python setup.py sdist
	$(TOX) -e run-cmd -- python setup.py bdist_wheel
	ls -l dist

dist-check: bootstrap ## Check all dist files for correctness
	$(TOX) -e run-cmd -- twine check dist/*

# How to execute notebook files
%.ipynb.log: %.ipynb
	@echo ""
	$(TOX) -e run-cmd -- jupyter nbconvert --to notebook --execute --inplace --allow-errors --ExecutePreprocessor.kernel_name='python3'  --ExecutePreprocessor.timeout=-1 --config=/dev/null $< 2>&1 | tee $@

notebooks: docs/tutorial.ipynb.log

install-kernel: bootstrap  ## Install Jupyter 'qalgebra' kernel into user environment
	$(TOX) -e run-cmd -- python -m ipykernel install --user --name qalgebra --display-name "QAlgebra"

uninstall-kernel: bootstrap   ## Remove Jupyter 'qalgebra' kernel from user environment
	$(TOX) -e run-cmd -- jupyter kernelspec remove -f afioct || true

jupyter-notebook: install-kernel ## run a notebook server (inside the user environment) for editing the examples
	jupyter notebook

jupyter-lab: install-kernel ## run a jupyterlab server (inside the user environment) for editing the examples
	jupyter lab
