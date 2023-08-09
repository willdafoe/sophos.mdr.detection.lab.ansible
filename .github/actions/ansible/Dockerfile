FROM alpine/ansible

ARG args
ENV args=${args}

RUN apk update
RUN apk add git
RUN apk add terraform

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bash","/entrypoint.sh"]