# patching: apply patch to bluesky-social repositories

## preface

It's better to merged into bluesky-social repositories, but ...

- bluesky-social repositories are under developing in quick.
- the contents of this repo is still fragile and under working.

Therefore, once patches stored in this folder, and applying them on-demand depending to operations.


## design of patches

basic design is inspired from prior work of syui.ai. and re-designed some as bellow:

1) patch files are named NUMBER-REPO-RESCRIPTION.{sh,diff}
   - make command (make target) calles *.sh, then shell script may use *.diff if it exists.
   - NUMER is the hint of order for applying patches in automatic, without conflicts. there should be some rules to assiging number.
   - REPO  is short name of bluesky-social repositories, such as social-app, indigo, etc. the same name as repos/*
   - DESCRIPTION is the hint for human why it needs.

## patch files numbering rule

| number(as prefix) | description |
|:------------------|:------------|
|1xx                | patches requires to build docker image with official source, regardless self-hosting like below:<br> |
|                   |   - add Dockerfile,  like 110-*.sh                                                      |
|                   |   - proxy consideration for build docker image, like 150-*.sh                           |
|                   |                                                                                         |
|3xx                | patches for self-hosting, like 300-*.sh                                                 |
