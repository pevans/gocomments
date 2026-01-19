test:
    - go test .

e2e-test:
    - bash run-e2e-tests.sh

build:
    - go build -o gocomments .
