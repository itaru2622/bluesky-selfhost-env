# variable to specify branch to apply patch. as below, <empty> then apply patch to current branch.
branch2patch=


patch-selfhost: ${rDir}/social-app/.selfhost-${DOMAIN}
${rDir}/social-app/.selfhost-${DOMAIN}::
	@echo "make branch and applying patch..."
	(cd ${rDir}/social-app; git status; git checkout ${branch2patch} -b selfhost-${DOMAIN} )
	for ops in `ls ${wDir}/patching/*.sh`; do rDir=${rDir} DOMAIN=${DOMAIN}  $${ops} ; done
	touch $@
	(cd ${rDir}/social-app; git add . ; git commit -m "update: selfhosting domain: ${DOMAIN}"; git diff main | cat )

build-social-app:
	@echo "########### make sure you already applied patch for selfhosting. (make patch-selfhost) ###########"
	(cd ${rDir}/social-app; git checkout selfhost-${DOMAIN} )
	-DOMAIN=${DOMAIN} docker-compose -f ${f} build social-app
