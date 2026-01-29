.PHONY: cantaloupe install

build:
	cd mirador-js && yarn && yarn build
	cp mirador-js/dist/mirador.mjs Koha/Plugin/HKS3/Mirador/mirador.js

install:
	rsync -av Koha ${PLUGINS_DIR}/

cantaloupe:
	docker run -d -p 8182:8182 \
	  -e "CANTALOUPE_ENDPOINT_ADMIN_SECRET=secret" \
	  -e "CANTALOUPE_ENDPOINT_ADMIN_ENABLED=true" \
	  -e "LC_ALL=C.utf8" \
	  --name cantaloupe -v ./cantaloupe/images:/imageroot docker.io/uclalibrary/cantaloupe:5.0.7-0
