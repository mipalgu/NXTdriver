# NXTdriver
C++ interface for the LEGO NXT driver trough USB or bluetooth

This is an organization of r2d2 using plain POSIX made by 
Vlad Estivill-Castro (MiPal) and although intended for Ubuntu-14.04 it is
offered without any warranty whatsoever. Its has contributions from
Carl Lusty, Rene Hexel and Esteve Fernandez.

It should wok for the test.cpp program of the original distribution. 
It tries to avoid the use of cmake and clang and explicitly  
calls /usr/bin/c++  THE GNU-c++/c compilers.

It is intended to be compiled with ROS-Indigo and catkin.

Its origins are the The share-ware nxtpp0-5 which only for for LINUX, 
and unfortunately this is share-ware that is not supported anymore,
and whose documentation is lost as the host Web site for it is no
longer maintained. Therefore, somewhat in MiPal we maintain this version,
but please report and if possible fix compatibility issues (Linux 32-bit vs 64-bit, 
blue-tooth compatibility, ROS-compatibility, etc). The README file for nxtpp0-5 says the following.
"NXT++ is an interface written in C++ that allows the control LEGO MIND-STORMS robots 
directly through a USB connection. The interface is intended to be simple and easy
 to use. The interface can be used in any C++program"

r2d2 (From Esteve Fernandez) can't compile under Ubuntu 12.4 and clang because of errors
like:

===================
In file included from /usr/include/c++/4.6/mutex:39:
/usr/include/c++/4.6/chrono:666:7: error: static_assert expression is not an integral constant expression
      static_assert(system_clock::duration::min()
      ^             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Usually, r2d2 can't compile with gcc without special flags otherwise we get errors like
cc1: error: command line option ‘-std=c++0x’ is valid for C++/ObjC++ but not for C [-Werror]

The MiPal make infrastructure gives preference to CLANG in src/MiPal/GUNao/mk/Linux.mk with tests like
HOST_CC!=which clang 2> /dev/null || which gcc
and
HOST_CXX!=which clang++ 2> /dev/null || which g++

Alternatively, we can give preference to GNU GCC
HOST_CC!=which gcc 2> /dev/null || which clang
and
HOST_CXX!=which g++ 2> /dev/null || which clang++

and place the flag in the local Makefile
you also have to use the file 
r2d2module.mk

which should be in 
GUNao/mk
