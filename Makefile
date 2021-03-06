# User-configurable variables
# You may edit the variables here, or override from the command-line.
#
# e.g. to use c-l-c systems and dump a standalone executable with SBCL, try
#	make LISPS=sbcl DUMP=! SYSTEMS_DIR=/usr/share/common-lisp/systems
# e.g. to use c-l-c systems and dump a clisp image, try
#	make LISPS=clisp SYSTEMS_DIR=/usr/share/common-lisp/systems
# e.g. to use c-l-c systems and openmcl without dumping an image, try
#	make LISPS=openmcl DUMP= SYSTEMS_DIR=/usr/share/common-lisp/systems
#
# we prefer SBCL by default, because it is faster than all except CMUCL
# (and even than CMUCL, on amd64) and the latest cl-pdf works with it.
#
INSTALL_BIN=${HOME}/local/stow/lisp/bin
INSTALL_LIB=${HOME}/local/stow/lisp/lib
INSTALL_SHARE=${HOME}/local/stow/lisp/share
IMAGE_DIR=${INSTALL_LIB}/common-lisp/images
LISPS=sbcl cmucl clisp openmcl allegro
CLBUILD=--no-clbuild
#CLBUILD=--clbuild
IMAGE=${IMAGE_DIR}/exscribe.image
DUMP= --dump $(IMAGE)
## For a standalone executable, use the following:
#DUMP= --dump !
VERBOSE=

SHELL=zsh -f --null-glob

### Here, the XCVB way of building exscribe:
# You need to export a proper XCVB_PATH and that's all.
XCVB_WORKSPACE := /tmp/${USER}/exscribe-workspace
XCVB_OBJECT_CACHE := ${XCVB_WORKSPACE}/obj

${INSTALL_BIN}/exscribe: install
#install: install-with-xcvb
install: install-with-asdf

# How to build it with XCVB:
install-with-xcvb:
	mkdir -p ${XCVB_WORKSPACE} ${XCVB_OBJECT_CACHE}
	xcvb mkmk --build /exscribe --setup /exscribe/setup \
		--define exscribe-typeset \
		--lisp-implementation sbcl \
		--workspace ${XCVB_WORKSPACE} \
		--object-cache ${XCVB_OBJECT_CACHE}
	make -C ${XCVB_WORKSPACE} -f xcvb.mk -j || \
		XCVB_DEBUGGING=t make -C ${XCVB_WORKSPACE} -f xcvb.mk
	cl-launch --image ${XCVB_OBJECT_CACHE}/fare.tunes.org/exscribe.image \
		--entry exscribe::main \
		--output ${INSTALL_BIN}/exscribe \
		${DUMP}

### Below, the ASDF way of building the same thing:
install-with-asdf:
	CL_LAUNCH_VERBOSE=${VERBOSE} \
	cl-launch ${CLBUILD} --lisp "${LISPS}" \
		--no-include \
		--system exscribe/typeset --entry 'exscribe::main' \
		--output ${INSTALL_BIN}/exscribe \
		${DUMP}

### Other targets to help with the ASDF build:

clean:
	-rm -f $(wildcard *.x86f *.lib *.fas *.fasl *.html *.pdf \
		 xcvb.mk *.image *.cfasl foo bar baz *.[oa] *.data )


### Tests:
allimptests:
	for LISP in clisp sbcl cmucl ; do $(MAKE) install alltests LISPS=$$LISP DUMP= ; done
	for LISP in clisp sbcl cmucl ; do $(MAKE) install alltests LISPS=$$LISP ; done

alltests: nulltest test bigtest bastest bastestall  # not for clisp: tpdf btpdf

nulltest:
	for i in 1 2 3 4 ; do time ${INSTALL_BIN}/exscribe -o - /dev/null ; done

test:
	rm index.html ; \
	time ${INSTALL_BIN}/exscribe -I ${HOME}/fare/www -o index.html ${HOME}/fare/www/index.scr

bigtest:
	time ${INSTALL_BIN}/exscribe -I ${HOME}/fare/www -o microsoft_monopoly.html ${HOME}/fare/www/liberty/microsoft_monopoly.scr

bastest:
	rsync -a --exclude "*html" --delete ${HOME}/webs/bastiat /tmp/
	rm -rf /tmp/bastiat/html/* \
		${HOME}/.cache/lisp-fasl/*/{{tmp,dev/shm/tmp}/bastiat,*/fare/fare/www/} \
		/var/cache/common-lisp-controller/$${UID}/*/local/{{tmp,dev/shm/tmp}/bastiat,*/fare/fare/www/}
	touch /tmp/bastiat/bo-style.scr ; time make -C /tmp/bastiat

bastestall:
	rsync -a --exclude "*html" --delete ${HOME}/webs/bastiat /tmp/
	rm -rf ${HOME}/.cache/lisp-fasl/*/{{tmp,dev/shm/tmp}/bastiat,*/fare/fare/www/} /tmp/bastiat/html/*
	touch /tmp/bastiat/bo-style.scr ; time make -C /tmp/bastiat allscr

tpdf:
	time ${INSTALL_BIN}/exscribe -P -I ${HOME}/fare/www -o white_black_magic.pdf ${HOME}/fare/www/liberty/white_black_magic.scr

btpdf:
	time ${INSTALL_BIN}/exscribe -P -I ${HOME}/fare/www -o microsoft_monopoly.pdf ${HOME}/fare/www/liberty/microsoft_monopoly.scr


### Building an tarball of examples:
FAREWEB = ${HOME}/fare/www
EXAMPLE_FILES = ${FAREWEB}/liberty/microsoft_monopoly.scr \
		${FAREWEB}/fare-style.scr \
		${FAREWEB}/cl-compat.scr \
		$(shell pwd)/test-exscribe
EXAMPLE_ARCHIVE = ${HOME}/files/asdf-packages/exscribe-examples.tar.gz

examples:
	mkdir -p /tmp/exscribe-examples
	ln -sf ${EXAMPLE_FILES} /tmp/exscribe-examples/
	tar zchvfC ${EXAMPLE_ARCHIVE} /tmp exscribe-examples/
	rm -rf /tmp/exscribe-examples
