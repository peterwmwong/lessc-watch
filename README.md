Wish `lessc` could watch your directory of `*.less` files?


Install
=======
    git clone git://github.com/peterwmwong/lessc-watch.git
    npm install less vows@0.5.2 coffee-script

    TODO: create/register npm package

Running
=======
    coffee lessc-watch/src/lessc-watch.coffee [src directory] [output directory]

    TODO: create bin script... so
        lessc-watch [src directory] [output directory]


What it does (by the tests)
===========================

    ♢ lessc-watch

     When given invalid arguments: mock/less_dir mock/file
       ✓ Should print:
    output directory '/home/zrow/proj/lessc-watch2/test/mock/file' is not a directory

    lessc-watch [src directory] [output directory]


     When given invalid arguments: mock/less_dir bogus_out_dir
       ✓ Should print:
    output directory '/home/zrow/proj/lessc-watch2/test/bogus_out_dir' does not exist

    lessc-watch [src directory] [output directory]


     When given invalid arguments:
       ✓ Should print:
    src directory is empty

    lessc-watch [src directory] [output directory]


     When given invalid arguments: mock/file mock/less_dir
       ✓ Should print:
    src directory '/home/zrow/proj/lessc-watch2/test/mock/file' is not a directory

    lessc-watch [src directory] [output directory]


     When given invalid arguments: bogus_src_dir mock/less_dir
       ✓ Should print:
    src directory '/home/zrow/proj/lessc-watch2/test/bogus_src_dir' does not exist

    lessc-watch [src directory] [output directory]


     When given invalid arguments: mock/less_dir
       ✓ Should print:
    output directory is empty

    lessc-watch [src directory] [output directory]


     When a nested LESS file is changed
       ✓ ... recompile it
     When a LESS file is changed
       ✓ ... recompile it
     When a LESS file is added
       ✓ ... compile and placed it in the output directory
     When the src directory contains directories with other directories
       ✓ ... created it in the output directory
     When the src directory contains a LESS file
       ✓ ... compile and placed it in the output directory
     When a LESS file is removed
       ✓ ... remove it from the output directory
     When a directory is removed
       ✓ ... remove it from the output directory
     When the src directory contains another directory
       ✓ ... create it in the output directory
    
    ✓ OK » 14 honored (2.123s)

