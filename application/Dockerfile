FROM python:3

RUN apt update && apt install -y shellinabox tcpdump && pip3 install Flask mysql-connector-python hvac requests

WORKDIR /usr/src/app
ADD templates ./templates/
ADD app.py db_client.py ./
ADD config.ini ./config/
ADD shellinabox /etc/default/shellinabox
ADD tdump8080.sh ./
ADD tdump8443.sh ./

 service shellinaboxd start

VOLUME ["/usr/src/app/config"]

CMD service shellinaboxd start && python ./app.py
