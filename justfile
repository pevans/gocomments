unit-test:
    - go test .

e2e-test:
    - bash bin/run-tests.sh

test: unit-test e2e-test

build:
    - go build -o gocomments .
