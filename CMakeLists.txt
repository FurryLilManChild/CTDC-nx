# CTDC-nx: Crazy Taxi and Crazy Taxi 2 (Dreamcast, USA) through dream-recomp, PC first, then
# Switch. dream-recomp is consumed as a submodule; it skips its own reference titles when it is
# not the top-level project, so the only game targets here are ours.
cmake_minimum_required(VERSION 3.24)
project(CTDC_nx LANGUAGES C CXX)

add_subdirectory(dream-recomp)
add_subdirectory(games/crazytaxi)
# Crazy Taxi 2 joins once Crazy Taxi plays: add_subdirectory(games/crazytaxi2)
