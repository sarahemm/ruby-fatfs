# ruby-slowfat - FAT library for Ruby designed for slow links/media

## Description

Ruby class/gem to access FAT filesystems (currently only FAT16) over slow links or media, such as serial connections. Prioritizes minimum I/O whenever possible, and flexible backing (files, sockets, etc.).

## Features
 * FAT16 support
 * Read and format directory listings
 * Read contents of files

## TODO
 * FAT12 support
 * Write support
 * Optimize a couple places where we might do more I/O than required

## Use
    require 'slowfat'

    img = File.open("test_fat16.img", 'r')
    fs = Fat::Filesystem.new(backing: img, base: 0x7E00)
    print fs.dir("WINDOWS").to_s
    print fs.file("WINDOWS/SETUP.TXT").contents


## Full Documentation
YARD docs included, also available on [RubyDoc.info](https://www.rubydoc.info/github/sarahemm/ruby-syncsign/master)
