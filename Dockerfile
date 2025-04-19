FROM ubuntu:latest AS builder
ARG FIKA=HEAD^
ARG FIKA_BRANCH=v2.1.1
ARG SPT=HEAD^
ARG SPT_BRANCH=3.8.3
ARG NODE=20.11.1
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
WORKDIR /opt
RUN apt update && apt install -yq git git-lfs curl
RUN git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm || true
RUN \. $HOME/.nvm/nvm.sh && nvm install $NODE
RUN git clone --branch $SPT_BRANCH https://github.com/sp-tarkov/server.git srv || true
WORKDIR /opt/srv/project
RUN git checkout $SPT
RUN git-lfs pull
RUN sed -i '/setEncoding/d' /opt/srv/project/src/Program.ts || true
RUN \. $HOME/.nvm/nvm.sh && npm install && npm run build:release -- --arch=$([ "$(uname -m)" = "aarch64" ] && echo arm64 || echo x64) --platform=linux
RUN mv build/ /opt/server/
WORKDIR /opt
RUN rm -rf srv/
RUN git clone --branch $FIKA_BRANCH https://github.com/project-fika/Fika-Server.git ./server/user/mods/fika-server
RUN \. $HOME/.nvm/nvm.sh && cd ./server/user/mods/fika-server && git checkout $FIKA && npm install
RUN rm -rf ./server/user/mods/FIKA/.git
FROM ubuntu:latest
WORKDIR /opt/
RUN apt update && apt upgrade -yq && apt install -yq dos2unix
COPY --from=builder /opt/server /opt/srv
COPY fcpy.sh /opt/fcpy.sh
RUN dos2unix /opt/fcpy.sh
RUN chmod o+rwx /opt -R
EXPOSE 6969
EXPOSE 6970
EXPOSE 6971
CMD bash ./fcpy.sh
