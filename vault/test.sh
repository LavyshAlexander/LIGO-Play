LIGO_VERSION=0.47.0
CONTRACTS_DIRECTORY=./contracts
TESTS_DIRECTORY=./tests

if [[ "$OSTYPE" == "msys"* ]]; then
    ligo="docker run --rm -v /\"\$PWD\":\"\$PWD\" -w /\"\$PWD\" ligolang/ligo:$LIGO_VERSION"
else
    ligo="docker run --rm -v \"\$PWD\":\"\$PWD\" -w \"\$PWD\" ligolang/ligo:$LIGO_VERSION"
fi


eval "$ligo run test $TESTS_DIRECTORY/main_tests.ligo"
