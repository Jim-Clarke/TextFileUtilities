# TextFileUtilities

This package helps with reading and writing text files from command-line
programs written in Swift.

These are not difficult operations, but a little too easy to forget if you're
new to Swift; and the assumption here is that information like file and
directory names is typed by the user somewhere, for example as command-line
arguments, rather than coming from a file chooser, so you have to identify and
open your files explicitly.

For me, this package will often be as much a reminder of what to do as a tool
for doing it.

Swift file I/O likes to treat the file contents as single (possibly very large)
Strings. Although this doesn't come naturally to me, this package goes along
with this, avoiding non-vanilla Swift as far as possible. It seems possible,
judging from the tone of online forums, that the language and its API may add
facilities that would simplify this package, perhars in the not too distant
future.
