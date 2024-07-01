ARG TARGET_PLATFORM
FROM --platform=${TARGET_PLATFORM} ubuntu:24.04

RUN echo "For science!" > /science.txt
RUN echo "For fun!" > /fun.txt
RUN echo "For profit!" > /profit.txt
