#!/usr/bin/make
# USAGE: 'sudo make' to build a jessie image (jmtd/debian:jessie).
# Define variables on the make command line to change behaviour
# e.g.
#       sudo make release=wheezy arch=i386 tag=wheezy-i386

# variables that can be overridden:
release ?= jessie
prefix  ?= solderzzc
arch    ?= armhf
mirror  ?= http://archive.raspbian.org/raspbian
tag     ?= $(release)-$(arch)

build: $(tag)/root.tar $(tag)/Dockerfile
	docker build -t $(prefix)/debian:$(tag) $(tag)

rev=$(shell git rev-parse --verify HEAD)
$(tag)/Dockerfile: Dockerfile.in $(tag)
	sed 's/SUBSTITUTION_FAILED/$(rev)/' $< >$@

$(tag):
	mkdir $@

$(tag)/root.tar: roots/$(tag)/etc $(tag)
	cd roots/$(tag) \
		&& tar -c --numeric-owner -f ../../$(tag)/root.tar ./ \
                && cp -rf ../../assets ./

# slightly awkward indirection to avoid a bug whereby user runs
# this unprivileged, creates the dir but debootstrap fails, but
# the target is satisfied and a subsequent run believes the rule
# satisfied
roots/$(tag):
	mkdir -p $@

roots/$(tag)/etc: roots/$(tag)
	debootstrap --foreign  --arch $(arch) $(release) $< $(mirror) \
                && cp assets/qemu-arm-static $</usr/bin/ \
		&& DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot $< /debootstrap/debootstrap --second-stage \
		&& chroot $< apt-get clean

clean:
	rm -f $(tag)/root.tar $(tag)/Dockerfile
	rm -r roots/$(tag)
	test -d $(tag) && rmdir $(tag)

.PHONY: clean build
