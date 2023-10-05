#!/bin/bash

# FIXME: add all logic to handle versions

RELEASE="0.5.6"

echo "*** Fetching a clean copy of fractal-web ${RELEASE} ***"

rm -fr fractal-web-${RELEASE}
rm -f ${RELEASE}.tar.gz

wget https://github.com/fractal-analytics-platform/fractal-web/archive/refs/tags/${RELEASE}.tar.gz
tar -xvf ${RELEASE}.tar.gz
mv fractal-web-${RELEASE}/ fractal-web/
rm ${RELEASE}.tar.gz
