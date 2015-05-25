## Apache Cassandra Node image
#
FROM prodriguezdefino/cassandrabase
MAINTAINER prodriguezdefino prodriguezdefino@gmail.com

# Deploy startup script
ADD init.sh /usr/local/bin/cass-start
RUN chmod 755 /usr/local/bin/cass-start

# Deploy shutdown script
ADD shutdown.sh /usr/local/bin/cass-stop
RUN chmod 755 /usr/local/bin/cass-stop

CMD cass-start