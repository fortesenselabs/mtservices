build:
	docker build -t mt5 -f Dockerfile.mt .

run: build
	docker run --rm -dit -p 5900:5900 --name mt5 -v mt5:/data mt5

shell: 
	docker exec -it mt5 sh

users: build
	docker exec -it mt5 adduser novouser
