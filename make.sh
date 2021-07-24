#!/bin/bash

if [ ! -x "$(which emcc)" ]; then
	echo "Emscripten compiler frontend (emcc) not found" >&2
	exit 1
fi

BABEL="./node_modules/.bin/babel"
SASS="./node_modules/.bin/sass"

if [ ! -x "$BABEL" ] || [ ! -x "$SASS" ]; then
	echo "NPM modules not installed" >&2
	exit 1
fi

EMCC_FLAGS="-O3"

if [ "$1" = "--dev" ]; then
	EMCC_FLAGS="-O0"
fi

mkdir -p dist

if [ "$1" = "--dev" ]; then
	$SASS --embed-source-map --no-charset src/spc_player.scss dist/spc_player.css
else
	$SASS --style=compressed --no-source-map --no-charset src/spc_player.scss dist/spc_player.css
fi

OPTIONS='-s NO_EXIT_RUNTIME -s ENVIRONMENT=web'
INTERFACE='--pre-js  pre/interface.js'

if [ "$2" = "--node" ]; then
	OPTIONS='-s ENVIRONMENT=node -s NODEJS_CATCH_EXIT=0 -s NODEJS_CATCH_REJECTION=0'
	INTERFACE=''
fi

[ $? -eq 0 ] \
&& $BABEL -o pre/spc_player.js src/spc_player.js \
&& $BABEL -o pre/interface.js src/interface.js \
&& emcc $EMCC_FLAGS --pre-js pre/spc_player.js $INTERFACE \
	$OPTIONS -s "EXPORTED_FUNCTIONS=['_main', '_malloc', '_free', '_loadSPC', '_playSPC']" \
	-I.. src/spc_player.c src/snes_spc/*cpp -o dist/spc.js \
&& cp src/spc_player.html dist
