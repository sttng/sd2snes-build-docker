#!/bin/bash

# stop on first error:
set -e

# clone sd2snes repo into sd2snes/ if that directory does not already exist:
if [ ! -d "sd2snes" ]; then
  echo Cloning sd2snes repository into sd2snes/
  git clone https://github.com/mrehkopf/sd2snes.git
else
  echo Existing working copy of sd2snes/ found.
fi

# build the docker image which compiles the sd2snes firmware:
echo Building docker image which compiles the sd2snes firmware and FPGA
docker build . -t sd2snes-fpga

# create the container from the image to extract the im3 build results:
echo Creating docker container from the built image to extract im3 files
container_id=$(docker create sd2snes-fpga)

docker cp ${container_id}:/work/sd2snes/ ./out/

echo Extracting im3 files
docker cp ${container_id}:/work/sd2snes/src/obj-mk3/firmware.im3 ./out/
docker cp ${container_id}:/work/sd2snes/src/obj-mk3-stm32/firmware.stm ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_base/fpga_base.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_mini/fpga_mini.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_dsp/fpga_dsp.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_cx4/fpga_cx4.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_gsu/fpga_gsu.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_obc1/fpga_obc1.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_sa1/fpga_sa1.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_sdd1/fpga_sdd1.bi3 ./out/
docker cp ${container_id}:/work/sd2snes/verilog/sd2snes_sgb/fpga_sgb.bi3 ./out/
echo Removing temporary container
docker rm ${container_id}
echo Successfully built firmware and FPGA images for MK3
