LIGO_VERSION=0.47.0
BUILD_DIRECTORY=./build
BUILD_MICHELSON_DIRECTORY=$BUILD_DIRECTORY/michelson
BUILD_JSON_DIRECTORY=$BUILD_DIRECTORY/json
CONTRACTS_DIRECTORY=./contracts

if [[ "$OSTYPE" == "msys"* ]]; then
    ligo="docker run --rm -v /\"\$PWD\":\"\$PWD\" -w /\"\$PWD\" ligolang/ligo:$LIGO_VERSION"
else
    ligo="docker run --rm -v \"\$PWD\":\"\$PWD\" -w \"\$PWD\" ligolang/ligo:$LIGO_VERSION"
fi

mkdir -p $BUILD_MICHELSON_DIRECTORY $BUILD_JSON_DIRECTORY

#1: a contract file name 
compile_contract() {
    echo "Compile contract: $1"
    eval "$ligo compile contract -o $BUILD_MICHELSON_DIRECTORY/$1.tz --michelson-format text -e main  \
        $CONTRACTS_DIRECTORY/$1.ligo"
    eval "$ligo compile contract -o $BUILD_JSON_DIRECTORY/$1.json --michelson-format json -e main \
        $CONTRACTS_DIRECTORY/$1.ligo"
}

compile_contract main
