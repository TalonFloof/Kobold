FROM ubuntu:latest AS setup
LABEL authors="talon"

WORKDIR /work

RUN apt update
RUN apt upgrade -y
RUN apt install -y nasm xorriso python3 python3-pip python3-venv wget lsb-release software-properties-common gnupg curl git
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" llvm 20 all
RUN bash -c "python3 -m venv .cutekit/venv; source .cutekit/venv/bin/activate; pip3 install git+https://github.com/cute-engineering/cutekit.git@v0.9.1"

FROM setup AS build
COPY meta meta
COPY source source
COPY project.json .
