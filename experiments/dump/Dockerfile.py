FROM amancevice/pandas:slim

# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#     gcc
# RUN pip install numpy
# RUN apk add --no-cache tzdata

# ENV TZ America/New_York

COPY MTWebServer /root/MTWebServer

WORKDIR /root/MTWebServer
RUN pip install -r requirements.txt

# allow other containers/PCs to connect; maybe not necessary
EXPOSE 8000

# when using docker-compose, this command can be overwritten
# CMD ["python", "/root/MTWebServer/main.py", "--ip", "0.0.0.0"]
# CMD ["python", "main.py", "--ip", "0.0.0.0"]
