.PHONY: azure_test

azure_test:
	act -s GITHUB_TOKEN="$(gh auth token)" \
		--input-file=my.input \
		--secret-file=my.secrets \
		-W ./.github/workflows/Azure.yml
