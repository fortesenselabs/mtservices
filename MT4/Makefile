build:
	docker build -t MetaTrader4 -f ./Dockerfile.MetaTrader4 .

run: build
	docker run --rm -d -p 5900:5900 -p 8000:8000 --name MetaTrader4 -v MetaTrader4:/data MetaTrader4

shell: 
	docker exec -it MetaTrader4 sh

users: build
	docker exec -it MetaTrader4 adduser novouser
