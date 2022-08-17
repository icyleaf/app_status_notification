FROM ruby:2.7-alpine

ARG REPLACE_CHINA_MIRROR="true"
ARG ORIGINAL_REPO_URL="dl-cdn.alpinelinux.org"
ARG MIRROR_REPO_URL="mirrors.ustc.edu.cn"
ARG RUBYGEMS_SOURCE="https://gems.ruby-china.com/"
ARG TZ="Asia/Shanghai"

# System dependencies
RUN set -ex && \
    if [[ "$REPLACE_CHINA_MIRROR" == "true" ]]; then \
      sed -i "s/$ORIGINAL_REPO_URL/$MIRROR_REPO_URL/g" /etc/apk/repositories && \
      gem sources --add $RUBYGEMS_SOURCE --remove https://rubygems.org/; \
    fi && \
    apk --update --no-cache add tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

ARG APP_STATUS_NOTIFICATION_VERSION="0.12.0"

ENV ASN_ENV="production"
COPY pkg/app_status_notification-${APP_STATUS_NOTIFICATION_VERSION}.gem /tmp/
RUN gem install /tmp/app_status_notification-${APP_STATUS_NOTIFICATION_VERSION}.gem && \
    rm -f /tmp/app_status_notification-${APP_STATUS_NOTIFICATION_VERSION}.gem

WORKDIR /app

VOLUME [ "/app/config", "/app/stores" ]

CMD ["app_status_notification", "--config", "/app/config"]
