#lang at-exp racket ;;-*- Scheme -*-
(require slideshow
	 slideshow/code
	 slideshow/code-pict
	 scheme/gui/base
	 (except-in "utils.rkt" system module force file eval error))

;; TODO: have multiple presentations?
;; (1) using CL as a scripting language, also, deploying executables and image life-cycle hooks.
;; (2) the story of bug that begat ASDF3, exploring subtleties in the ASDF dependency model,
;;   and a surprising conclusion. [My article's Appendix F]
;; (3) laundry list of new features in ASDF3.1 since ASDF2.
;; (4) LAMBDA, the Ultimate Culture War — Live Programming vs Cult-of-Dead programs.
;; (5) other (please specify).

(define ~ @t{ })
(define *blue* (make-object color% "blue"))
(define *red* (make-object color% "red"))
(define *grey* (make-object color% 200 200 200))
(define (url x) (colorize (tt x) *blue*))
(define (red x) (colorize x *red*))
(define (grey x) (colorize x *grey*))

(define (emph x) (red x))

(define (title x) (text x (cons 'bold 'default) 38))

(define slides
  (make-keyword-procedure
   (lambda (kws kvs repeats . lines)
     (for ([i repeats])
       (let ((m (λ (xs) (map (λ (x) (x i)) xs))))
	 (keyword-apply
	  slide kws (m kvs) (m lines)))))))

(define (always x) (lambda (i) x))
(define (repeat-fun test n iftesttrue [iftestfalse ~] [ifnorepeat ~])
  (lambda (i)
    (cond
     ((not i) ifnorepeat)
     ((test i n) iftesttrue)
     (#t iftestfalse))))
(define (if= n x [y ~] [z ~]) (repeat-fun = n x y z))
(define (if<= n x [y ~] [z ~]) (lambda (i) (if (<= i n) x y)))
(define (if>= n x [y ~] [z ~]) (lambda (i) (if (>= i n) x y)))

(define (?highlight n m object [shaded grey] [highlit red] [normal identity])
  (if n
      (if (eqv? n m)
	  (highlit object)
	  (shaded object))
      (normal object)))

(define (tASDF3 . x)
  (title (apply string-append "ASDF 3: " x)))

(define (tslide _title . body)
  (keyword-apply slide '(#:title) (list (title _title)) body))

(tslide "Another System Definition Facility version 3.1"
  @bt{Why Lisp is Now an Acceptable Scripting Language}
  ~
  @t{François-René Rideau <tunes@"@"google.com>}
  (comment "\
Hi, I'm François-René Rideau, and I'm here to tell you about ASDF 3, \
the de facto standard build system for Common Lisp.

My paper at the European Lisp Symposium 2014 is titled \
\"ASDF3: Why CL is now an acceptable Scripting Language\". \

Indeed, one of my the too many take-home points of my paper \
is that CL is now available to compete as a scripting language \
against Unix shells, Perl, Python, Ruby, etc.

I'll explain why the last missing piece for that was ASDF 3, \
and how you can hack your own Lisp into providing the same service.
"))

(tslide "An Acceptable Scripting Language"
  (comment "\
First, let's see how you now can use CL as a scripting language"))

(tslide "Writing a Unix-style script in Lisp"
  (code
   |#!/usr/bin/cl| -sp lisp-stripper -E main
   (defun main (argv)
     (if argv
         (map () |'print-loc-count| argv)
         (print-loc-count *standard-input*)))
   ||
   ||
   ||
   |_lispwc *.lisp|)
  (comment "\
Here is a simple script.

Here, the script \"interpreter\" is the ASDF companion program cl-launch \
that invokes your favorite Common Lisp compiler.

As you can see, I am homesteading the path /usr/bin/cl. \
The -sp option loads a system and changes the current *package* in one go. \
The -E option specifies a main function to which to pass command-line arguments \
when running the program.

This script counts lines of CL code using a library called lisp-stripper \
that strips blank lines, comments, docstrings, and extra lines in string constants."))

(tslide "Invoking Lisp code from the shell"
  (code
   |#!/bin/sh|
   ||
   |form='`#5(1 ,@`(2 3))'|
   ||
   |for l in allegro ccl clisp sbcl ecl |\\
   |      lispworks abcl cmucl gcl scl xcl ; |\\
   |do |
   |_  cl -l $l |\\
   |      "(format t \"$l ~S~%\" $form)" |\\
   |  2>&1 |\|| grep "^$l " # LW, GCL are verbose|
   |done|)
  (comment "\
You can also invoke Common Lisp code directly from a shell script.

This simple script compares how the many implementations evaluate a same form, \
printing on each line the name of the implementation followed by the value. \

In this case, the form involves the unspecified interaction \
between known-length vector and unquote-splicing. \
The standard says that with the the hash-number-paren notation, \
whereby the reader will repeat the last form to fill a vector of specified size; \
it also says that comma-at will be spliced at read-time; \
but what happens when you do both?

That's an interesting question, but of course, \
since CL is a scripting language far superior to the Unix shell \
you could use CL instead of /bin/sh to write the same script.
"))

(tslide "Invoking external commands from Lisp"
  (code
   |#!/usr/bin/cl -sp inferior-shell|
   ||
   (loop with form = "`#5(1 ,@`(2 3))"
      ||
      for l in '(allegro ccl clisp sbcl ecl
                 lispworks abcl cmucl gcl scl xcl)
      do
      (run `(pipe (cl -l ,l (>& 2 1)
                      ("(format t \"" ,l " ~S~%\" "
                         ,form ")"))
              (grep ("^" ,l " "))))))
  (comment "\
The following script is doing exactly the same thing as the previous one, \
except it is written in CL.

It uses the system inferior-shell, that supports pipes, redirections, \
and user-friendly synthesis of Unix commands and their arguments.

But the point is not just to do as well as a Unix shell, but to do better."))

(tslide "Better abstractions for scripting"
  (code
   ||
   ||
   (loop with form = "`#5(1 ,@`(2 3))"
      ||
      for l in '(allegro ccl clisp sbcl ecl
                 lispworks abcl cmucl gcl scl xcl)
      collect
      (run `(pipe (cl -l ,l (>& 2 1)
                      ("(format t \"" ,l " ~S~%\" "
                         ,form ")"))
              (grep ("^" ,l " "))) :output :forms)))
  (comment "\
And here, since you're using CL, \
you can write an expression that returns structured data, not strings. \
Ewww, strings are so uncivilized!

Structured data is a much better paradigm \
to build composable software abstractions. \
And with its ability to WRITE and READ back arbitrary symbolic expressions, \
CL still has an edge over many other languages. \
But of course, you can still exchange XML or JSON if you like."))

(tslide "Standards-based portability"
  (code
   |_`#5(1 ,@`(2 3))|
   ||
   ||
   ((ALLEGRO |#(1 2 3 2 3 2 3 2 3)|)
    (CCL |#(1 2 3 2 3 2 3 2 3))|)
    (CLISP |#(1 2 3 2 3 2 3 2 3))|)
    (SBCL |#(1 2 3 2 3 2 3 2 3))|)
    (ECL |#(1 2 3 3 3))|)
    (LISPWORKS |#(1 2 3 3 3))|)
    (ABCL |#(1 2 3))|)
    (CMUCL |#(1 2 3))|)
    (GCL |#(1 2 3))|)
    (SCL |#(1 2 3))|)
    (XCL |#(1 2 3))|)))
  (comment "\
Incidentally, here is the break down of how various implementations \
evaluate the contentious form.

For the record, my fare-quasiquote implementation agrees with ECL and LispWorks: \
if the user specified a vector of size n, the implementation should return a vector of size n.

Allegro, Clozure CL, GNU CLISP and SBCL first read a comma-at form in a vector of size n, \
then expand it; sure you can imagine how it can make sense, but this is confusing.

As for ABCL, CMUCL, GCL, SCL and XCL, they just ignore any specified size in a quasiquote context; \
I admit I find that tasteless; but of course, when the result is unspecified, \
they are allowed to send dragons flying through your nose, \
so consider yourself lucky to be given such a nice result.

So, cl-launch, ASDF, and other libraries can abstract over \
 a lot of discrepancies between CL implementations, \
but there will still remain discrepancies in many underspecified parts of the standard, \
Even then cl-launch can help you run test and experiments on all implementations."))

(tslide "What prevented scripting?"
  (comment "\
So why was scripting in CL not possible before?

What does your programming language need to possess, \
before it can be used to write scripts?")
  'next
  (para #:align 'left (t "finding source code"))
  (para #:align 'left (t "locating output files"))
  ~
  (para #:align 'left (t "command line invocation"))
  (para #:align 'left (t "argv access"))
  ~
  (para #:align 'left (t "run-program"))
  (para #:align 'left (t "pipes, expansion"))
  (comment "So why was scripting in CL not possible before?

Well, it was stricto sensu possibe, but completely not portable. \
Every user would have to modify every script to match his particular situation. \
There were several aspects requiring modification, that involved various amounts of pain.

Some of these aspects were universally inflicted to every common lisp user: \
finding source code and choosing output file location were basic unfulfilled needs \
before ASDF, and still painful with ASDF1. \
Without this, scripts couldn't reliably use any library or scale to large programs. \
This was not just for scripts: \
Even applications with no ambition of being distributed for execution without modification \
was difficult to configure right. \
Also, by saving the compiled output files next to the source code, \
ASDF1 and its predecessors made it impossible to share a same program \
between multiple users (at least not without security issues), \
or between multiple compilers, or multiple machines, etc. \
This might have been a mere inconvenience for writing and testing complete heavy-weight applications, \
and various kluges existed to allow to move output files aside, \
but this how a show-stopper for writing scripts.

Then there were more obvious but still quite annoying issues for writing scripts.

Invoking CL code from other a Unix shell or other program, \
and accessing arguments passed to your code, \
were non-trivial tasks, that varied wildly with your implementation.

Finally, calling an external program and extrating results was extremely difficult, \
and there again varied wildly with your implementation.

All these factors together conspired to make CL wholly unsuitable to write scripts. \
Write once, run anywhere was an unreachable dream, \
despite the large compatibility of all implementations with each other \
thanks to the CL standard."))

(tslide "What made scripting possible?"
  (para #:align 'left (t "finding source code → asdf2 (source-registry)"))
  (para #:align 'left (t "locating output files → asdf2 (output-translations)"))
  ~
  (para #:align 'left (t "command line invocation → cl-launch"))
  (para #:align 'left (t "argv access → cl-launch"))
  ~
  (para #:align 'left (t "run-program → asdf3 (uiop)"))
  (para #:align 'left (t "pipes, expansion → inferior-shell"))
  (comment "\
These issues have now been addressed.

The most pressing issues with CL, not specific to scripting, were solved by ASDF 2. \
With its source-registry, locating source became modular, \
and you didn't need per-program, per-library or even per-user configuration \
of where to find code. \
With the output-translations layer, you could the share source code tree \
between multiple users, multiple implementations, multiple machines, \
and there would be no clash or additional security issues.

Invoking CL programs in a uniform way was made possible by cl-launch. \
cl-launch was actually written before ASDF2, but it was made simpler and more powerful \
with ASDF2's output-translations and with ASDF3's portability layer UIOP.

As for invoking external programs from CL and capturing their output nicely, \
this was initially made possible by XCVB and its xcvb-driver, \
and moved into ASDF3's portability layer UIOP and further developed there. \
A more usable layer is available in the system inferior-shell,
that I demonstrated just before."))

(tslide "Finding source code (before)"
  @para[#:align 'left]{Q: Where is system @tt{foo} ?}
  @para[#:align 'left]{The hard way: modify every client}
  @para[#:align 'left]{logical-pathname: system and client must agree}
  @para[#:align 'left]{ASDF: user maintains a link farm to .asd files}
  @para[#:align 'left]{but how to configure? @tt{~/.sbclrc}, etc.}
  (comment "\
First to locate the source code of the various systems, \
each user had to specially configure his Lisp implementation \
in a non-portable way.

Back in the dark ages, every program that used libraries had to be modified to load them, \
or equivalently, had to rely on a load script or system definition \
that would be modified to load them first from where they are.

Then came logical pathnames, and all relevant software only had to be modified once \
to use logical pathnames everywhere. \
But now every user had to be a bit of a system administrator \
and ensure that each of his implementations had the proper logical-pathname configuration \
for each of the libraries used. \
The problem had been moved and concentrated rather than solved, \
but at least now it had to be solved only once per user. \
Adding and removing libraries required editing a configuration file \
and was somewhat painful, though.

ASDF1 made it configuration much simpler. \
With the clever use of *load-truename*, it could retrieve the location of a system \
given a symbolic link to the .asd system definition file; \
you could thus register a directory in its *central-registry* \
and fill it with symlinks to all the .asd files you cared about. \
This meant you could write your configuration file once, \
and you could write a shell script to update \
the symlinks in your configured directory. \
System administration thus became easy — \
but every user still had to be their own system administrator.

What more, to configure things early, \
users would typically load ASDF and configure it \
from within their implementation's initialization file, \
for instance ~/.sbclrc on SBCL. \
But this had issues of its own. \
First, not every implementation supported initialization files, \
and then you would have to manually load one. \
Second, if using multiple implementations, you had to either \
repeat information in every file, or create your own system of files that load other files. \
Third, scripts that wanted to rely on configuration being implicitly there \
were thus denied a predictable execution mode where \
no user customization could interfere with their assumptions; \
if the implementation allowed to disable user configuration, \
scripts could use it but then lose the ability to find systems \
without being edited for configuration.

That was all a big mess"))

(tslide "Finding source code (after)"
  @para[#:align 'left]{ASDF 2: @tt{source-registry}}
  @para[#:align 'left]{Implementation-independent}
  @para[#:align 'left]{Nice DSL}
  @para[#:align 'left]{Can recurse into subtrees}
  @para[#:align 'left]{Prog > Env > User > Sys, Explicit > Defaults}
  @para[#:align 'left]{Sensible defaults}
  @para[#:align 'left]{ASDF 3.1: @tt{~/common-lisp/}}
  (comment "\
ASDF 2 solved that by introducing the source-registry; \
previous central-registry is still supported for backward compatibility.

It's implementation-independent; \
it does not rely on an implementation-dependent configuration file that might not exist.

It has a nice flexible DSL to specify paths, so you can refer to the home directory, \
to a string that identifies the implementation, including its version, \
its salient configuration features, \
the operating system and hardware architecture, etc.

Unlike the ASDF1 central-registry, the ASDF2 source-registry can recurse into subtrees; \
no more having to manually scan directories and manually update link farms when the libraries \
are removed, added or modified.

The ASDF2 source-registry have a nice way to get configuration from various sources \
and merge them so that the program can override the environment that can override \
user configuration files that can override system configuration files that can override defaults.

The ASDF2 source-registry provides sensible defaults that will work with your implentation, \
with systems provided by your Linux distribution (e.g. Debian), etc.

ASDF3 introduces a universal pre-configured location, ~/common-lisp/
in which to put your code"))

(tslide "Finding source code (lessons)"
  @para[#:align 'left]{@it{Who knows specifies, who doesn't needn't}}
  @para[#:align 'left]{It @it{just works} by default}
  ~
  @para[#:align 'left]{Modular configuration}
  @para[#:align 'left]{Reusable DSL for pathname designators}
  ~
  @para[#:align 'left]{Better than in C!}
  (comment "\
The source-registry illustrates a few essential principles of design. \
First, configuration should follow the constraint that \
\"He who knows specifies the configuration, he who doesn't neededn't\". \
That's very important, so that users are not required \
to also become programmers or system administrators, \
while authors are not required to be omniscient about where their systems will be installed.

A second principle is that the defaults should JUST WORK. \
Configuration is for advanced users only. \
Common cases should work without any configuration whatsoever. \
Power users will have to configure things anyway; \
but that shouldn't get into the way of newbies.

As a consequence of these principles, the source-registry configuration is modular: \
a user may mix systems from different origins, \
and they can each be configured independently \
— including by download automation utilities, such as Quicklisp. \
When combining software from many layers, \
the configuration for the most specific layer can always override less specific layers, \
and thus any issues with them. \
Each can thus focus on what he knows and delegate the rest to others.

Large parts of the source-registry configuration infrastructure are general-purpose, \
and indeed are reused and shared by the output-translations layer (see below).

The result compares very favorably, where \
many completely different and mutually incompatible mechanisms exist \
at either runtime or compile-time \
to locate where source code, interface headers, and \
corresponding library, executable, data and configuration files are located. \
LD_LIBRARY_PATH, libtool, autoconf, pkg-config, kde-config, ./configure scripts, \
and countless other protocols.

In conclusion, \
if you develop a programming language and its build system, \
you may want a similar mechanism to ASDF 2's."))

(tslide "Locating output files"
  @para[#:align 'left]{ASDF 2: @tt{output-translations}}
  @para[#:align 'left]{Configuration similar to @tt{source-registry}}
  ~
  @para[#:align 'left]{Default: persistent cache, per user, per ABI}
  @para[#:align 'left]{Cache not shared, for security}
  ~
  @para[#:align 'left]{a JIT, but persistent and coarse-grained}
  @para[#:align 'left]{a portable bytecode VM, with code 40, 41...}
  ~
  (comment "\
To share source code available on a system-wide basis between multiple users, \
or to use the same source code it with different implementations, \
you needed to somehow segregate compilation output files per user, per implementation.

That was not generally possible before ASDF; \
Using logical-pathnames was possible in theory, \
but required a lot of knowledge of both the implementation and the software being compiled, \
in addition to being cumbersome.

With ASDF, people could define :around methods for the function output-files \
and thus systematically divert all output files; extensions existed to help do just that. \
But there again special setup was required to load and configure such extensions. \
Another \"solution\" would have been to never compile anything, \
or equivalenty to always compile everything from scratch to new private files; \
but that would be quite slow and would not have scaled to large files and big libraries. \
Yet that was exactly what had to be used for these extensions themselves, \
to avoid bootstrap issues.

The problem ultimately the same as with finding source code, and so was the solution: \
Not to force every user to be a system administrator, \
ASDF had to include the functionality and a nice modular configuration mechanism for it. \
That's what I did with ASDF 2 and its output-translations facility.

By default, ASDF2 is configured so that all output is redirected in a per-user, per-ABI cache, \
so that there is no interference between users who cannot trust each other, \
or between incompatible implementations or variants of a same implementation. \
But this is completely under user control; \
the user can wholly disable the facility, or can reconfigure it in different ways, \
with the same modular infrastructure as for the source-registry.

The result is that scripts can rely on there being a persistent cache of compiled output files. \
In comparison with Java, one way to see it is that Common Lisp has a JIT, \
except persistent and coarse-grained, at the file level rather than function level. \
Also, the Common Lisp bytecode is not stack-based but structure-based; \
bytecode 40 (ascii code for open paren) starts new code structure,
bytecode 41 (ascii code for open paren) finishes the current code structure, etc."))

(tslide "Shell interface"
  @para[#:align 'left]{shell-to-Lisp: @tt{cl-launch}}
  ~
  @para[#:align 'left]{Lisp-to-shell: @tt{uiop/run-program}, @tt{inferior-shell}}
  ~
  @para[#:align 'left]{100% solution, 100% portable}
  (comment "\
Every Lisp implementation has to be invoked in its own way, \
that differs from every other implementation; \
implementations also differ wildly on how you may access command-line arguments; \
a few implementations won't even let you reliably pass arbitrary arguments, \
and a helper script is required in these case; \
and Windows support often is particularly tricky. \
cl-launch abstracts over these details and gives you a uniform interface. \
We saw how that works in previous slides, including why uniformity matter. \
The Lisp side of its support has been moved to ASDF 3, and \
on the better implementations can be used by standalone executables without cl-launch.

Each Lisp implementation also has its own variants of the run-program facility; \
all too often, it is only a thin layer around the underpowered system() function \
from the C stdlib; \
capturing the output is a huge pain, and doing it portably even more so. \
Tens of systems had their own half-assed attempts at a semi-portable variant of the idea.

cl-launch and uiop/run-program follow the principle well stated \
by Olin Shivers (in his the Preamble to his SRE library) \
that problems are better solved \
if programmers each provide a complete \"100%\" solution to a handful problems, \
than if the same programmers each provide a different partial \"80%\" solution \
to each of the same problems."))

(tslide "Easier delivery with bundle operations"
  @para[#:align 'left]{Deliver an executable: @tt{cl-launch}}
  ~
  @para[#:align 'left]{Deliver a library: @tt{compile-bundle-op}}
  ~
  @para[#:align 'left]{Deliver code as only one or two files!}
  (comment "\
On implementations that don't support standalone executables, \
the delivery will have to be in two files: \
an image, and a launch shell script; \
that plus the Lisp implementation, if the image isn't executable.

From Lisp, you can use asdf:program-op and asdf:image-op, \
but beware that on some implementations, this causes Lisp to quit. \
Often, the solution would be to fork before you dump an image, \
but forking is not available on all those implementations!
"))

(tslide "Image Life-cycle support"
  @para[#:align 'left]{Need to use environment variables?}
  ~
  (code
   (uiop:register-image-dump-hook 'clear-env-vars)
   ||
   (uiop:register-image-restore-hook 'init-env-vars))
  (comment "\
You don't want to leak build environment information \
into your executable binaries. \
It's not just an issue that makes your build harder to reproduce and bugs harder to track. \
It's not just a potential source of production bugs that are not detected during testing. \
It's also a potential security threat that you need to take seriously.

ASDF 3's portability layer UIOP provides a portable way to register hook functions \
that will clean up your environment before you dump an image. \
You can also register other functions, that will for instance \
extract from source control an accurate identifier for the current build, \
finalize some data structures and dictionaries based on the complete code, \
generate some code based on various data schemas, \
precompile the above as well as various CLOS methods, \
etc.

UIOP also allows you to register hook functions that will initialize your environment \
when you restart a new process from the Lisp image, \
including right now during the build for the current image.")
  'next
  ~
  @para[#:align 'left]{Many other uses}
  ~
  @para[#:align 'left]{A standard interface @it{matters}}
  (comment "\
Being able to do all that in a standard portable way means that \
you can write libraries that rely on these services being present, \
and on the libraries they themselves depend on being initialized. \
Users can use these libraries and not have to be aware \
of magic hooks they need to call to finalize or initialize each of them, \
either as a special step in their build script, \
or by using some arcane hook in their implementation at some point. \
There is no more trouble with libraries either initializing their dependencies \
and then finding that there are bugs when two libraries both try to initialize a same dependency; \
or not initializing their dependencies and then finding that there are subtle bugs \
because the user failed to initialize all the libraries in the correct order. \
Hooks are run in the correct order, depending on the order they are registered, \
which itself is compatible with the order of declared dependencies between libraries.

Remember, that as said Jeff Atwood:
\"Any time you're asking the user to make a choice they don't care about,
you have failed the user\""))

(tslide "Scripting Language?"
  (comment "\
So. I claim that with all these improvements,
CL is now an acceptable scripting language, which it wasn't before.
This begs the question: what is an acceptable scripting language?")
  'next
  @para[#:align 'left]{Low-overhead programming}
  @para[#:align 'left]{No boilerplate}
  @para[#:align 'left]{Write once, run everywhere @it{unmodified}}
  @para[#:align 'left]{No setup needed}
  @para[#:align 'left]{Spawn or be spawned by other programs}
  @para[#:align 'left]{call or be called by functions in other languages}
  (comment "\
To me, the general criterion to a scripting language is low-overhead programming.
This means little or no boilerplate
between the programmer and a runnable program:
one short line max as in #!/usr/bin/cl is OK;
ten lines to include plenty of header files, class definitions,
or a main(argc, argv) function prototype, is NOT OK.
Having to write your own portability layer is NOT OK.
cl-launch and ASDF3 solved that for CL.

This also means little or no boilerplate between the user and running the program.
Having to install the program and its dependencies is OK,
though it should be mostly automated.
Requiring a special setup and/or system administration skills is NOT OK.
Having to configure variables specific to the task at hand is OK.
The need to modify the script itself so it runs at all on your machine is NOT OK.
cl-launch and ASDF2 mainly solved the configuration issue,
but many small improvements have been made since.

Finally, this means easy interoperation with other software on the system.
Since the shell command line is the standard way for multiple programs to interoperate,
it should be supported, both ways.
cl-launch and ASDF3 solve that.
And since C libraries is the standard way to provide new services
— respectively JVM libraries, .NET libraries, etc., depending on your platform —
the scripting language should provide an easy to interface to that, both ways.
CFFI provides that for CL.
"))

(tslide "What is it all about?"
  (comment "\
Why do we need scripting languages, or a build system, to begin with?
")
  'next
  @para[#:align 'left]{ASDF3 does nothing that cannot be done without it}
  (comment "\
In the end, detractors will deride, ASDF3 does nothing that cannot be done without it.
Any program you write that uses ASDF3 or cl-launch could be written without either.
At the very worst, it would include relevant snippets of ASDF3 or cl-launch to do the same thing,
just lighter weight for not having to support cases irrelevant to the program at hand.")
  'next
  @para[#:align 'left]{Neither does any piece of software}
  (comment "\
But the same can be said of any and all software, beside the end applications:
no computable function can ever extend the set of things that can theoretically be computed.
No library can do anything that couldn't be done by duplicating relevant parts of its code
in all client code. etc.")
  'next
  @para[#:align 'left]{Division of labor}
  (comment "\
The point of any and every library is division of labor:
human creativity is a scarce resource, and
by cooperating with each other, we can achieve more than we could separately,
avoiding to each have to redundantly solve the same problems,
when we could each be solving new problems that we can specialize on.")
  'next
  @para[#:align 'left]{@it{Enabling} the division of labor}
  (comment "\
The point of a build system is to enable the division of labor between other programmers.
It achieves that by making it easy to divide software into many components that complement each other,
that each may somehow fit into some programmer's brain,
while reducing friction in combining these components into a complete program."))

(tslide "Beyond ASDF3"
  (comment "\
So what is the next step for ASDF?
")
  'next
  @para[#:align 'left]{less overhead:}
  @para[#:align 'left]{ASDF 3.1: @tt{one-package-per-file}}
  ~
  @para[#:align 'left]{more modularity:}
  @para[#:align 'left]{ASDF 3.1: @tt{*readtable*} protection}
  ~
  @para[#:align 'left]{more access:}
  @para[#:align 'left]{Integrate with other languages?}
  (comment "\
ASDF 3.1 has two innovations that further improve the language.

First, it sports an alternative lower-overhead way to declare dependencies, \
using the one-package-per-file style previously promoted by faslpath and quick-build. \
Since we have files and packages anyway, we might as well reuse package declarations, \
deduce dependencies from them, and match package names to file names to system names. \
This unsurprisingly makes component management more like Java or Python. \
The implementation about a hundred lines of code only, \
and for less than two hundred lines, you could have the equivalent of ASDF, \
except without all the bells and whistles, in one 1/50th to 1/100th of the size.

Second, ASDF 3.1 increases modularity by protecting the syntax of modules being compiled \
as determined by the *readtable* used while compiling, from the syntax of the toplevel, \
as determined by the *readtable* at the REPL. \
Common Lisp has too many special or global parameters, \
and by better isolating the parameters used during the build, \
we can make the build more modular.

Third, in ASDF 2 the dependency model was so specialized it could only be used to compile Lisp code; \
with ASDF 3, it is fully general and can be used to compile anything in any language, \
or manage any dependency-based build.
"))

(tslide "Lessons for other languages"
  @para[#:align 'left]{less overhead}
  ~
  ~
  @para[#:align 'left]{more modularity}
  ~
  ~
  @para[#:align 'left]{more access}
  ~
  (comment "\
If you're developing a language other than CL, \
consider these axes for improvement.

Can you reduce the overhead to writing useful programs?

Can you remove shared state?
Minimize configuration?
If any configuration is needed, can you let the user or programs override the defaults?

Can you access the rest of the system? Be accessed from it?
"))

(tslide "Also in the extended article..."
  @para[#:align 'left]{The basic design of ASDF}
  @para[#:align 'left]{Why it rocks / sucks compared with C build tools}
  @para[#:align 'left]{Innovations in ASDF 1 2 2.26 3 3.1}
  @para[#:align 'left]{The Problem with Pathnames}
  @para[#:align 'left]{Lessons in Software Design including Pitfalls}
  @para[#:align 'left]{A great bug chase story}
  ~
  @para[#:align 'center]{@tt{http://github.com/fare/asdf3-2014}}
  (comment "\
The extended version of the article I published for ELS 2014
also contains many other themes, which explains why it's 26 pages long.

Many among you might enjoy reading all or part of it.
"))

(tslide "Share and Enjoy!"
  @para[#:align 'left]{@tt{http://common-lisp.net/project/asdf/}}
  @para[#:align 'left]{@tt{http://cliki.net/cl-launch}}
  @para[#:align 'left]{@tt{http://cliki.net/inferior-shell}}
  @para[#:align 'left]{@tt{http://www.quicklisp.org/beta/}}
  ~
  @para[#:align 'left]{@tt{http://github.com/fare/asdf3-2014}}
  ~
  @para[#:align 'center]{Any Questions?}
  (comment "\
All the software I've described is published as free software. \
You can find them at the following addresses."))