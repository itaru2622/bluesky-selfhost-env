
# refer toplevel makefile for undefined variables and targets.

# target for git ops

#  checkout to main
#  HINT: make checkout2main
checkout2main:   _cmd_checkout2main   exec

# checkout to work branch
#  HINT: make checkout2work
checkout2work:  _cmd_checkout2work   exec

# create work branch
#  HINT: make createWorkBranch
createWorkBranch:  _cmd_createWorkBranch   exec

# build variables to pass exec (target in toplevel Makefile)
_cmd_checkout2main:
	$(eval cmd=git checkout main)
	$(eval under=${repoDirs})

_cmd_checkout2work:
	$(eval cmd=git checkout work)
	$(eval under=${repoDirs})

_cmd_createWorkBranch:
	$(eval cmd=git checkout -b work)
	$(eval under=${repoDirs})

_echo4git:
	@echo "under=>${under}"
	@echo "  cmd=>${cmd}"
