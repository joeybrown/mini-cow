ARG TARGET_PLATFORM
FROM --platform=${TARGET_PLATFORM} heroku/heroku:24

USER root

RUN echo "For the children!" > /science.txt
RUN echo "For the environment!" > /fun.txt
RUN echo "For the animals!" > /profit.txt

USER heroku
