#!/usr/bin/bash

PROGRAM=$(basename $0)
USAGE="SOURCE-FILE"

function error() {
    echo "$PROGRAM: $@"
    echo "Usage: $PROGRAM $USAGE"
    exit 1
} >&2

[ $# = 1 ] || error "Illegal number of arguments"
SOURCE_NAME=${1%.rb}.rb

GEM_FILE=$(ls *.gemspec 2>/dev/null)
[ -n "$GEM_FILE" ] || error "Can't find gemspec file"
GEM_NAME=${GEM_FILE%.gemspec}

if [ -f lib/$SOURCE_NAME ]; then
    SOURCE_FILE=lib/$SOURCE_NAME
elif [ -f lib/$GEM_NAME/$SOURCE_NAME ]; then
    SOURCE_FILE=lib/$GEM_NAME/$SOURCE_NAME
else    
    SOURCE_FILE=$(find lib/$GEM_NAME -type f -path $SOURCE_NAME | head -1)
    if [ -z "$SOURCE_FILE" ]; then
        SOURCE_FILE=lib/$GEM_NAME/$SOURCE_NAME
    fi
fi

SPEC_FILE=spec/${SOURCE_NAME%.rb}_spec.rb
[ -f $SPEC_FILE ] || error "Can't find spec file '$SPEC_FILE'"

clear
rspec --fail-fast $SPEC_FILE || { 
    # rcov forgets a newline when rspec fails
    status=$?; echo; exit $status;
}




