PATH := ./node_modules/.bin:$(PATH)

test: compile
	@NODE_ENV=test mocha-fibers --recursive test --compilers coffee:coffee-script

compile:
	@coffee --compile --output lib/ src

compile-test:
	@coffee --compile --output test-compiled/ test

.PHONY: test
