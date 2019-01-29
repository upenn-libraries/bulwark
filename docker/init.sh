#!/bin/bash
  
git annex init --version=6
git annex enableremote ceph01
git config remote.origin.annex-ignore true
git config annex.largefiles 'not (include=.repoadmin/bin/*.sh)'
git annex fsck --from ceph01 --fast

