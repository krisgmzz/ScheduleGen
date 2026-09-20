cmake_minimum_required(VERSION 3.10)
project(ScheduleGen C)

set(CMAKE_C_STANDARD 11)

include_directories(include)

add_executable(main main.c loader.c writer.c)