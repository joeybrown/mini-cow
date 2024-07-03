ARG TARGET_PLATFORM
FROM --platform=${TARGET_PLATFORM} heroku/heroku:24

USER root

RUN echo "For the children!" > /children.txt
RUN echo "For the environment!" > /environment.txt
RUN echo "For the animals!" > /animals.txt

USER heroku
