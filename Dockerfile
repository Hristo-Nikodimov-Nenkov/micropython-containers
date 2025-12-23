FROM docker:25-cli AS base

RUN apt update && apt upgrade -y
