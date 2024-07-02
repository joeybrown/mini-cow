ARG TARGET_PLATFORM
FROM --platform=${TARGET_PLATFORM} heroku/heroku:24

USER root

RUN echo "For science!" > /science.txt
RUN echo "For fun!" > /fun.txt
RUN echo "For profit!" > /profit.txt

USER heroku
