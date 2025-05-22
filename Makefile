.PHONY: cantaloupe

cantaloupe:
	docker run -d -p 8182:8182 \
	  -e "CANTALOUPE_ENDPOINT_ADMIN_SECRET=secret" \
	  -e "CANTALOUPE_ENDPOINT_ADMIN_ENABLED=true" \
	  --name cantaloupe -v ./cantaloupe/images:/imageroot docker.io/uclalibrary/cantaloupe:5.0.7-0
