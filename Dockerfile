FROM centos:latest

MAINTAINER Udo Urbantschitsch udo@urbantschitsch.com

LABEL io.openshift.tags java,java18,elasticsearch,elasticsearch24
LABEL io.k8s.description Elasticsearch Cluster Image
LABEL io.openshift.expose-services 9200/tcp:http,9300/tcp:cluster

RUN useradd elastic -u 1001

RUN \
yum update -y && \
yum install -y iproute && \
yum install -y ruby && \
yum install -y java-1.8.0 && \
yum clean all

ARG VERSION=2.4.1

RUN curl -O https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/$VERSION/elasticsearch-$VERSION.rpm && \
rpm -i elasticsearch-$VERSION.rpm && \
rm -f elasticsearch-$VERSION.rpm && \
ln -s /etc/elasticsearch /usr/share/elasticsearch/config && \
ln -s /usr/share/elasticsearch/bin/elasticsearch /bin/elasticsearch && \
chmod +x /bin/elasticsearch && \
chmod -R 777 /usr/share/elasticsearch && \
chmod -R 777 /etc/elasticsearch

RUN /usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head && \
    /usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf/v2.1.2

COPY container-files /

ENV NODE_MASTER=true NODE_DATA=true NODE_HTTP=true CLUSTER_NAME=elasticsearch
ENV ES_HEAP_SIZE=512m

EXPOSE 9200 9300

USER 1001

CMD /docker-entrypoint.sh
