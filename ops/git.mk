
# refer toplevel makefile for variables undefined.

# variables,  for github/git ops
printlastlog   :=git log --pretty='format:%h %ad  %aE   %s' --date=iso-strict -1


# target for git ops

#  checkout to main
#  HINT: make checkout2main
checkout2main:   _cmd_checkout2main   exec

#  make branch    
#  HINT: make mkBranch_asof asof=2024-01-01 branch=work
mkBranch_asof: _cmd_mkbranch_asof     exec

# add tag
#  HINT: make addTag_asof asof=2024-01-01 tag=
addTag_asof:        _cmd_addtag_asof  exec

#  del branch
#  HINT: make delBranch branch=
delBranch:     _cmd_delbranch         exec

# delTag
#  HINT: make delTag tag=
delTag:        _cmd_deltag            exec

# build variables to pass exec (target in toplevel Makefile)
_cmd_checkout2main:
	$(eval cmd=git checkout main)
	$(eval under=${repoDirs})
_cmd_mkbranch_asof:
	$(eval cmd=git checkout `${getHashByDate}` -b ${branch})
	$(eval under=${repoDirs})
_cmd_addtag_asof:
	$(eval cmd=git tag -a ${tag} -m '${tag}' `${getHashByDate}`)
	$(eval under=${repoDirs})

_cmd_delbranch:
	$(eval cmd=git branch -D ${branch})
	$(eval under=${repoDirs})

_cmd_deltag:
	$(eval cmd=git tag -d ${tag})
	$(eval under=${repoDirs})


_echo4git:
	@echo "under=>${under}"
	@echo "  cmd=>${cmd}"
