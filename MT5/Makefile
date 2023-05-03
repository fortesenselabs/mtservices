build:
	docker build -t metatrader:5 -f ./Dockerfile.MetaTrader5 .

run: build
	docker run --rm -d -p 8080:8080/tcp metatrader:5

shell: 
	docker exec -it metatrader sh

users: build
	docker exec -it metatrader adduser novouser
