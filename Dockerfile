FROM perl:5.28
ADD [".", "/src"]
RUN cpanm -q -n --no-man-pages App::cpm &&  cd /src && cpm install -g && cpm install -g . && rm -rf /root/.perl-cpm /root/.cpanm && rm -rf /src
CMD ["sitebrew"]
