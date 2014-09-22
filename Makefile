all: build

build:
	@docker build --tag=${USER}/runner-gitlab .
