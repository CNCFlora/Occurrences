project = occurrences

all: build

install-deps:
	docker-compose -p $(project) -f config/docker-compose.yml run --no-deps $(project) composer install

update-deps:
	docker-compose -p $(project) -f config/docker-compose.yml  run --no-deps $(project) composer update

run: 
	docker-compose -p $(project) -f config/docker-compose.yml up

run-simple: 
	docker-compose -p $(project) -f config/docker-compose.yml run --no-deps --service-ports $(project)

start: 
	docker-compose -p $(project) -f config/docker-compose.yml up -d

stop: 
	docker-compose -p $(project) -f config/docker-compose.yml stop
	docker-compose -p $(project) -f config/docker-compose.yml rm
	docker-compose -p $(project) -f config/docker-compose.test.yml stop
	docker-compose -p $(project) -f config/docker-compose.test.yml rm

test:
	docker-compose -p $(project) -f config/docker-compose.test.yml run tester vendor/bin/phpunit tests

test-features:
	docker-compose -p $(project) -f config/docker-compose.test.yml run tester vendor/bin/behat 

build:
	docker build -t cncflora/$(project) -f config/Dockerfile .

push:
	docker push cncflora/$(project)

