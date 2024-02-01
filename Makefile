build:
	docker build -t MetaTrader5 -f ./Dockerfile.MetaTrader5 .

run: build
	docker run --rm -d -p 8080:8080 --name MetaTrader5 -v MetaTrader5:/data MetaTrader5

shell: 
	docker exec -it MetaTrader5 sh

users: build
	docker exec -it MetaTrader5 adduser novouser