# use a recent ARM compiler
FROM stronglytyped/arm-none-eabi-gcc:latest AS install

WORKDIR /work/quartus
RUN wget https://downloads.intel.com/akdlm/software/acdsinst/25.1std/1129/ib_tar/Quartus-lite-25.1std.0.1129-linux.tar
RUN tar xf Quartus-lite-25.1std.0.1129-linux.tar && \
	./setup.sh --mode unattended --accept_eula 1 --installdir /opt/intelFPGA_lite/25.1 --disable-components quartus_help,cyclone10lp,cyclonev,max,max10,arria_lite,questa_fse,questa_fe && \
	rm -fr *

######################################################

FROM stronglytyped/arm-none-eabi-gcc:latest

COPY --from=install /opt /opt

# available components: discover with `./setup.sh --help`
# quartus quartus_help devinfo arria_lite cyclone cyclone10lp cyclonev max max10 quartus_update modelsim_ase modelsim_ae

# install necessary build tools:
WORKDIR /work
RUN apt update && apt install -y gawk zip unzip curl libglib2.0-0 libtcmalloc-minimal4
RUN curl https://getmic.ro | bash ; cp micro /usr/local/bin/

RUN wget https://bisqwit.iki.fi/src/arch/snescom-1.8.1.1.tar.gz
RUN tar xf snescom-1.8.1.1.tar.gz
RUN cd ./snescom-1.8.1.1 && make all
RUN cp ./snescom-1.8.1.1/snescom /usr/local/bin/
RUN cp ./snescom-1.8.1.1/sneslink /usr/local/bin/

# LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4 LD_LIBRARY_PATH=/opt/intelFPGA_lite/25.1/quartus/linux64
#RUN mv /opt/intelFPGA_lite/25.1/quartus/linux64/libboost_system.so /opt/intelFPGA_lite/25.1/quartus/linux64/libboost_system.so.disabled ; \
#	mv /opt/intelFPGA_lite/25.1/quartus/linux64/libccl_curl_drl.so /opt/intelFPGA_lite/25.1/quartus/linux64/libccl_curl_drl.so.disabled ; \
#	mv /opt/intelFPGA_lite/25.1/quartus/linux64/libstdc++.so.6 /opt/intelFPGA_lite/25.1/quartus/linux64/libstdc++.so.6.disabled ; \
#	mv /opt/intelFPGA_lite/25.1/quartus/linux64/libstdc++.so /opt/intelFPGA_lite/25.1/quartus/linux64/libstdc++.so.disabled

# clone develop from sd2snes firmware repo:
#RUN git clone --depth 1 https://github.com/mrehkopf/sd2snes.git
ADD ./sd2snes /work/sd2snes

WORKDIR /work/sd2snes

# override verilog/settings.mk with linux-specific Quartus 25.1 paths and env var overrides:
ADD ./verilog-settings.mk verilog/settings.mk

# these are required build steps for utilities:
RUN cd ./utils && make
RUN cd ./src/utils && make

#RUN cd ./snes/spc7110_test && make all

RUN make all

# # build the fpga_base.bi3 file:
# RUN cd ./verilog/sd2snes_base && make mk3
# # output is /work/sd2snes/verilog/sd2snes_base/fpga_base.bi3
# RUN cd ./verilog/sd2snes_mini && make mk3
# # output is /work/sd2snes/verilog/sd2snes_mini/fpga_mini.bi3

# RUN cd ./verilog/sd2snes_dsp && make mk3
# # output is /work/sd2snes/verilog/sd2snes_dsp/fpga_dsp.bi3
# RUN cd ./verilog/sd2snes_cx4 && make mk3
# # output is /work/sd2snes/verilog/sd2snes_cx4/fpga_cx4.bi3
# RUN cd ./verilog/sd2snes_gsu && make mk3
# # output is /work/sd2snes/verilog/sd2snes_gsu/fpga_gsu.bi3
# RUN cd ./verilog/sd2snes_obc1 && make mk3
# # output is /work/sd2snes/verilog/sd2snes_obc1/fpga_obc1.bi3
# RUN cd ./verilog/sd2snes_sa1 && make mk3
# # output is /work/sd2snes/verilog/sd2snes_sa1/fpga_sa1.bi3
# RUN cd ./verilog/sd2snes_sdd1 && make mk3
# # output is /work/sd2snes/verilog/sd2snes_sdd1/fpga_sdd1.bi3
# RUN cd ./verilog/sd2snes_sgb && make mk3
# # output is /work/sd2snes/verilog/sd2snes_sgb/fpga_sgb.bi3

#RUN cd ./verilog/sd2snes_spc7110 && make mk3
# # output is /work/sd2snes/verilog/sd2snes_spc7110/fpga_spc7110.bi3

# # PATCH to add a missing #include which otherwise breaks compilation
# RUN sed -i '27 i #include <ctype.h>' ./src/sgb.c
# RUN cd ./src && make VERSION=* CONFIG=config-mk3
# # output is /work/sd2snes/src/firmware.im3
# RUN cd ./src && make VERSION=* CONFIG=config-mk3-stm32
# # output is /work/sd2snes/src/firmware.stm
