#FreeSWITCH with AMR Support (BYO Licencing)
FROM debian:buster-slim

RUN apt-get update && apt-get install -yq gnupg2 wget lsb-release vim tcpdump sngrep
RUN wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add -
RUN echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
RUN echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list
RUN apt-get update


# # Install dependencies required for the build
#Install OpenJRE first because Java is a jerk
RUN mkdir -p /usr/share/man/man1
RUN apt-get install openjdk-11-jre-headless:amd64 -y
RUN apt-get build-dep freeswitch -y


WORKDIR /usr/src/

#Install Opencore-AMR
RUN apt-get install libopencore-amrwb-dev libopencore-amrwb0 libopencore-amrwb0-dbg libvo-amrwbenc-dev libvo-amrwbenc0 vo-amrwbenc-dbg


# # then let's get the source. Use the -b flag to get a specific branch
WORKDIR /usr/src/
RUN git clone https://github.com/signalwire/freeswitch.git -bv1.10 freeswitch
WORKDIR /usr/src/freeswitch
RUN git config pull.rebase true
#Copy over AMR files
RUN cp /usr/include/opencore-amrnb/interf_enc.h /usr/src/freeswitch/src/mod/codecs/mod_amr/
RUN cp /usr/include/opencore-amrnb/interf_dec.h /usr/src/freeswitch/src/mod/codecs/mod_amr/
RUN cp /usr/include/opencore-amrwb/dec_if.h  /usr/src/freeswitch/src/mod/codecs/mod_amrwb/
RUN cp /usr/include/vo-amrwbenc/enc_if.h /usr/src/freeswitch/src/mod/codecs/mod_amrwb/

RUN ./bootstrap.sh -j

#Add AMR WB to modules list
RUN sed -i '/#codecs\/mod_amrwb/s/^#//g' modules.conf

RUN ./configure
RUN make
RUN make install

#Add sounds
RUN make cd-sounds-install cd-moh-install

CMD ["/usr/local/freeswitch/bin/freeswitch"]