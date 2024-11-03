# gl

learning opengl!

## zig version and libraries

I am using zig `0.14.0-dev.1550+4fba7336a`. Some of the libraries I use here
only support 13.x, so they are manually patched to make this project work. So I
vendor them in `./vendored` instead of something more sane like a package
manager or even submodules. :-)

## build and run

`zig build run`
