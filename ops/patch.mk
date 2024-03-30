# variable to specify branch to apply patch. as below, <empty> then apply patch to current branch.
branch2patch=

patch-dockerbuild: ${rDir}/feed-generator/.dockerbuild  ${rDir}/indigo/.dockerbuild  ${rDir}/atproto/.dockerbuild

${rDir}/feed-generator/.dockerbuild:
	@echo "make branch and applying patch..."
	(cd ${rDir}/feed-generator; git status; git checkout ${branch2patch} -b dockerbuild )
	for ops in `ls ${wDir}/patching/1*.sh | grep feed-generator`; do wDir=${wDir} rDir=${rDir} pDir=${wDir}/patching DOMAIN=${DOMAIN} asof=${asof}  $${ops} ; done
	touch $@
	(cd ${rDir}/feed-generator; git add . ; git commit -m "update: dockerbuild"; )

${rDir}/indigo/.dockerbuild:
	@echo "make branch and applying patch..."
	(cd ${rDir}/indigo; git status; git checkout ${branch2patch} -b dockerbuild )
	for ops in `ls ${wDir}/patching/1*.sh | grep indigo`; do wDir=${wDir} rDir=${rDir} pDir=${wDir}/patching DOMAIN=${DOMAIN} asof=${asof}  $${ops} ; done
	touch $@
	(cd ${rDir}/indigo; git add . ; git commit -m "update: dockerbuild"; )

${rDir}/atproto/.dockerbuild:
	@echo "make branch and applying patch..."
	(cd ${rDir}/atproto; git status; git checkout ${branch2patch} -b dockerbuild )
	for ops in `ls ${wDir}/patching/1*.sh | grep atproto`; do wDir=${wDir} rDir=${rDir} pDir=${wDir}/patching DOMAIN=${DOMAIN} asof=${asof}  $${ops} ; done
	touch $@
	(cd ${rDir}/atproto; git add . ; git commit -m "update: dockerbuild"; )

patch-selfhost: ${rDir}/social-app/.selfhost-${DOMAIN} ${rDir}/feed-generator/.selfhost-${DOMAIN}
${rDir}/social-app/.selfhost-${DOMAIN}::
	@echo "make branch and applying patch..."
	(cd ${rDir}/social-app; git status; git checkout ${branch2patch} -b selfhost-${asof}${DOMAIN} )
	for ops in `ls ${wDir}/patching/3*.sh | grep social-app | grep -v expo`; do wDir=${wDir} rDir=${rDir} pDir=${wDir}/patching DOMAIN=${DOMAIN} asof=${asof}  $${ops} ; done
	touch $@
	(cd ${rDir}/social-app; git add . ; git commit -m "update: selfhosting domain: ${DOMAIN} asof: ${asof}"; )

${rDir}/social-app/.selfhost-${DOMAIN}:: show_patch_result

patch-selfhost-feedgen: ${rDir}/feed-generator/.selfhost-${DOMAIN}
${rDir}/feed-generator/.selfhost-${DOMAIN}::
	@echo "make branch and applying patch..."
	(cd ${rDir}/feed-generator; git status; git checkout ${branch2patch} -b selfhost-${asof}${DOMAIN} )
	for ops in `ls ${wDir}/patching/3*.sh | grep feed-generator`; do wDir=${wDir} rDir=${rDir} pDir=${wDir}/patching DOMAIN=${DOMAIN} asof=${asof}  $${ops} ; done
	touch $@
	(cd ${rDir}/feed-generator; git add . ; git commit -m "update: selfhosting domain: ${DOMAIN} asof: ${asof}"; )



show_patch_result:
	(cd ${rDir}/social-app; git diff HEAD^ | cat ; echo "############\n############ social-app: branches:" ; git branch | cat ; echo "############")
