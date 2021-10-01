Skip to content
Search or jump to…
Pull requests
Issues
Marketplace
Explore
 
@casson-projects-2020 
bernhard-42
/
jupyter-cadquery
Public
9
11618
Code
Issues
10
Pull requests
Actions
Projects
Wiki
Security
Insights
jupyter-cadquery/Makefile
@bernhard-42
bernhard-42 proper cleaning of notebooks
Latest commit fbc6483 on May 19
 History
 2 contributors
@bernhardBV@bernhard-42
77 lines (61 sloc)  2 KB
   
.PHONY: clean_notebooks wheel install tests check_version dist check_dist upload_test upload bump release docker docker_upload

PYCACHE := $(shell find . -name '__pycache__')
EGGS := $(wildcard *.egg-info)
CURRENT_VERSION := $(shell awk '/current_version/ {print $$3}' setup.cfg)

# https://github.com/jupyter/nbconvert/issues/637

JQ_RULES := '(.cells[] | select(has("outputs")) | .outputs) = [] \
| (.cells[] | select(has("execution_count")) | .execution_count) = null \
| .metadata = { \
	"language_info": {"name":"python", "pygments_lexer": "ipython3"}, \
	"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"} \
} \
| .cells[].metadata = {}'

clean_notebooks: ./examples/*.ipynb ./examples/assemblies/*.ipynb
	@for file in $^ ; do \
		echo "$${file}" ; \
		jq --indent 1 $(JQ_RULES) "$${file}" > "$${file}_clean"; \
		mv "$${file}_clean" "$${file}"; \
		python validate_nb.py "$${file}"; \
	done

clean: clean_notebooks
	@echo "=> Cleaning"
	@rm -fr build dist $(EGGS) $(PYCACHE)

prepare: clean
	git add .
	git status
	git commit -m "cleanup before release"

# Version commands

bump:
ifdef part
ifdef version
	bumpversion --new-version $(version) $(part) && grep current setup.cfg
else
	bumpversion --allow-dirty $(part) && grep current setup.cfg
endif
else
	@echo "Provide part=major|minor|patch|release|build and optionally version=x.y.z..."
	exit 1
endif

# Dist commands

dist:
	@rm -f dist/*
	@python setup.py sdist bdist_wheel

release:
	git add .
	git status
	git diff-index --quiet HEAD || git commit -m "Latest release: $(CURRENT_VERSION)"
	git tag -a v$(CURRENT_VERSION) -m "Latest release: $(CURRENT_VERSION)"

install: dist
	@echo "=> Installing jupyter_cadquery"
	@pip install --upgrade .

check_dist:
	@twine check dist/*

upload:
	@twine upload dist/*

docker:
	@rm -fr docker/examples
	@cp -R examples docker/
	@cd docker && docker build -t bwalter42/jupyter_cadquery:$(CURRENT_VERSION) .
	@rm -fr docker/examples

upload_docker: 
	@docker push bwalter42/jupyter_cadquery:$(CURRENT_VERSION)
© 2021 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
Loading complete
