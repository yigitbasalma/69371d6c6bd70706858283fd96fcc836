FROM alpine:3.7 as base

ENV PYTHONUNBUFFERED 1
RUN apk add --update \
    py-pip \
    mariadb-dev \
    python2

FROM base as builder

RUN apk add --update \
    python-dev \
    musl-dev \
    gcc
RUN mkdir /install
WORKDIR /install
COPY app/requirements.txt /requirements.txt
RUN pip install --install-option="--prefix=/install" -r /requirements.txt

FROM base

RUN pip install gunicorn
COPY --from=builder /install/lib/python2.7/site-packages /usr/lib/python2.7/site-packages
COPY app /app
WORKDIR /app
CMD ["gunicorn", "-w 4", "application:application", "-b", "0.0.0.0:3000"]
