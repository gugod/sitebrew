FROM perl:5.28
WORKDIR /app/sitebrew
COPY cpanfile /app/sitebrew/cpanfile
RUN cpanm -q -n --no-man-pages App::cpm && cpm install -g && rm -rf /root/.perl-cpm /root/.cpanm

ADD [".", "/app/sitebrew"]
ENV PERL5LIB=/app/sitebrew/lib \
    PATH=/app/sitebrew/bin:$PATH
CMD ["sitebrew"]
