#!/bin/bash

cpm install

perlprivlibexp=$(perl -MConfig -e 'print $Config{privlibexp}')
perlarchlibexp=$(perl -MConfig -e 'print $Config{archlibexp}')
perlversion=$(perl -MConfig -e 'print $Config{version}')
pp -B \
    -I ./local/lib/perl5 \
    -a "$perlprivlibexp;$perlversion/" \
    -a "$perlarchlibexp;$perlversion/" \
    -a "./local/lib/perl5/;$perlversion/" \
    -a lib \
    -o sitebrew \
    script/sitebrew
