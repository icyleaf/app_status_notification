FROM ruby:2.7-alpine

ARG REPLACE_CHINA_MIRROR="true"
ARG ORIGINAL_REPO_URL="http://dl-cdn.alpinelinux.org"
ARG MIRROR_REPO_URL="https://mirrors.tuna.tsinghua.edu.cn"
ARG RUBYGEMS_SOURCE="https://gems.ruby-china.com/"
ARG TZ="Asia/Shanghai"
ARG APP_STATUS_NOTIFICATION_VERSION="app_status_notification-0.9.0.beta6"

# System dependencies
RUN set -ex && \
    if [[ "$REPLACE_CHINA_MIRROR" == "true" ]]; then \
      REPLACE_STRING=$(echo $MIRROR_REPO_URL | sed 's/\//\\\//g') && \
      SEARCH_STRING=$(echo $ORIGINAL_REPO_URL | sed 's/\//\\\//g') && \
      sed -i "s/$SEARCH_STRING/$REPLACE_STRING/g" /etc/apk/repositories && \
      gem sources --add $RUBYGEMS_SOURCE --remove https://rubygems.org/; \
    fi && \
    apk --update --no-cache add tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

COPY pkg/${APP_STATUS_NOTIFICATION_VERSION}.gem /tmp/
RUN gem install /tmp/${APP_STATUS_NOTIFICATION_VERSION}.gem

WORKDIR /app

VOLUME [ "/app/config" ]

CMD ["app_status_notification", "--config", "/app/config"]
