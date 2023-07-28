#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#                                                                              #
# --------------------------- BUILD (ogmios) --------------------------------- #
#                                                                              #

FROM --platform=${TARGETPLATFORM:-linux/amd64} busybox:1.35 as ogmios

ARG NETWORK=mainnet

LABEL name=ogmios
LABEL description="A JSON WebSocket bridge for cardano-node."

COPY ./bin/ogmios /bin/ogmios
COPY ./server/cardano-configurations/network/${NETWORK} /config

EXPOSE 1337/tcp
HEALTHCHECK --interval=10s --timeout=5s --retries=1 CMD /bin/ogmios health-check

STOPSIGNAL SIGINT
ENTRYPOINT ["/bin/ogmios"]

#                                                                              #
# --------------------- RUN (cardano-node & ogmios) -------------------------- #
#                                                                              #

FROM inputoutput/cardano-node:${CARDANO_NODE_VERSION} as cardano-node-ogmios

ARG NETWORK=mainnet
ENV TINI_VERSION v0.19.0

LABEL name=cardano-node-ogmios
LABEL description="A Cardano node, side-by-side with its JSON WebSocket bridge."

COPY ./bin/ogmios /bin/ogmios
COPY ./server/cardano-configurations/network/${NETWORK} /config
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini && mkdir -p /ipc

WORKDIR /root

 # Ogmios, cardano-node, ekg, prometheus
EXPOSE 1337/tcp 3000/tcp 12788/tcp 12798/tcp
HEALTHCHECK --interval=10s --timeout=5s --retries=1 CMD /bin/ogmios health-check

STOPSIGNAL SIGINT
COPY scripts/cardano-node-ogmios.sh cardano-node-ogmios.sh
ENTRYPOINT ["/tini", "-g", "--", "/root/cardano-node-ogmios.sh" ]
