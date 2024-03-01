# variable to specify branch to apply patch. as below, <empty> then apply patch to current branch.
branch2patch=


patch-selfhost: ${rDir}/social-app/.selfhost-${DOMAIN}
${rDir}/social-app/.selfhost-${DOMAIN}::
	@echo "make branch and applying patch..."
	(cd ${rDir}/social-app; git status; git checkout ${branch2patch} -b selfhost-${asof}${DOMAIN} )
	for ops in `ls ${wDir}/patching/*.sh`; do wDir=${wDir} rDir=${rDir} pDir=${wDir}/patching DOMAIN=${DOMAIN} asof=${asof}  $${ops} ; done
	touch $@
	(cd ${rDir}/social-app; git add . ; git commit -m "update: selfhosting domain: ${DOMAIN} asof: ${asof}"; )

${rDir}/social-app/.selfhost-${DOMAIN}:: show_patch_result

show_patch_result:
	(cd ${rDir}/social-app; git diff HEAD^ | cat ; echo "############\n############ social-app: branches:" ; git branch | cat ; echo "############")
