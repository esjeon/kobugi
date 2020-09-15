
Kobugi - A minimal website generator
====================================

Kobugi is a GNU Make-based minimalistic website generator.

Note that this is a personal project and still a work-in-progress.


Getting Started
---------------

Kobugi is make-based, so using it is as simple as copying files and running
`make`.

1. Checkout Kobugi

        git checkout https://github.com/esjeon/kobugi

2. Create a symbolic link to `kobugi/Makefile` under your site root.

        ln -s kobugi/Makefile ${site_root}/Makefile

   Kobugi will track through the symlink to find its components.

3. Run the makefile.

        cd ${site_root}
        make

   It can also be run in parallel mode:

        make -j


Function
--------

Kobugi is a site generator, so it does what other generators do: generate HTML
by applying templates.


                     [ .MD .HTM .RUN ]
                             |  
        [ index.map ]        V       [ .C .JS .CSS ]
              |        +----------+  [ .SH .MK ... ]
              |        | Document |         |
              |        |  Parser  |         |
              V        +----------+         V
         +----------+        |        +-----------+      
         |  Index   |        V        |  Syntax   |
         | Template |<---( .HTMP )    | Highlight |
         +----------+        |        +-----------+
              |              V              |
              |      +---------------+      |
              +----->| Base Template |<-----+
                     +---------------+
                             |                
                             V                
                         [ .HTML ]

          <<< The logical structure of Kobugi >>>   


### Generate Page

### Generate Index

### Generate View



Rationale
---------

### Why `make`?

Website generation is about running a set of independent rules, and this is what
make exteremly good at. On top of that, using make simplifies things like
partial update and job parallelization.


### Why "GNU" make?

GNU make is clearly bloated compared to POSIX make, but it's because of the
difference in their expected roles. POSIX make is a passive set of build
scripts. Any dynamic aspects of build process must be handled outside, by
running scripts or generating include(`*.mk`) files. As a project grows, this
becomes burdensome very quickly.

On the other hand, GNU make is a script language of its own. GNU people
introduced function and macro capabilities into make language, and these
significantly reduce the amount of external management code. Less code is
better, always.


### Why use `dash` instead `bash`?

Because bash is much larger and much more complicated software, yet the benefit
is slim unlike POSIX make vs GNU make. Also, dash is known to be much faster
than bash, and is the most practical yet minimal alternative to bash.


### Why not language XXX?

One big problem was error handling. Writing Kobugi was mostly about writing
*procedures*, that bails out immediately on error. To write this in many modern
languages, error values must be checked after *EVERY* procedure call, and this
takes 4x more code than just writing shell scripts. There are high-level
languages w/ exception handling constructs (e.g. try-catch), but they are
usually big and require big runtime or compiler.

An exception is Python, which is universally available on linux, thanks to that
even system software often rely on it for tooling. But it had another problem,
which my next point.

Another problem was extensibility. Well, a full disclosure: I'm certainly
inspired by good ol' CGI interface, which communicated information through
environment variables. Kobugi utilizes both environment variable and piping for
passing information to sub-programs. This allows incorporating software of
various origin (or language). While this is also possible in other languages,
this is most trivial w/ make & shell.

Therefore, I concluded make is the best tool for writing minimal site
generators.

