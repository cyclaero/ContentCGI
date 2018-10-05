How-to create a nice Icon in the ICO file format

1. Create the design using your favorite graphic tool,
   I am comfortable with Adobe Illustrator, and hence
   the example file is ContentIcon.ai (this can be
   opened by any .pdf-reader as well).

2  Export the design as PNG files in various pixel sizes,
   namely 16×16, 24×24, 32×32, 48×48, 128×128, 256×256,
   all into the same directory, let’s say ~/Desktop/ICOfiles/

3. On https://github.com/cyclaero/icopacker, download the
   icopacker.c source code file, and compile it using the
   following command:

     clang -g0 -O3 -std=gnu11 -fno-pic -fstrict-aliasing -fno-common \
     -fvisibility=hidden -Wno-parentheses icopacker.c -o icopacker

4. Pack the PNG files in ~/Desktop/ICOfiles/ into one ICO
   file ~/Desktop/ICOfile.ico using the following command:

     ./icopacker ~/Desktop/ICOfiles/ ~/Desktop/ICOfile.ico

That's it.
