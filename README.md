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
facilities that would simplify this package, perhaps in the not too distant
future.

### In the file TextFileUtilities.swift:
- FileError
- nameToPath(fileName: ) -> String


### In the file InFile.swift:
You probably just need to do this:

    let myInFile = InFile(fileName)
    var fileLines: [Substring]
    try fileLines = myInFile.read()

But you can get into the messy details if necessary:

- class InFile, with attributes ...
    - name
    - URL
    - contents
    - lines
- ... and functions
    - init(name:)
    - init(name: urlString)
    - readContents()
    - chooseNewline() -> Character?
    - contentsToLines()
    - read() -> [Substring]


### In the file OutFile.swift:
OutFile.swift starts with definitions of output streams that let you work with stdout and stderr.
You can just use plain old `print`, but using `StreamedOutFile` (a child class of `OutFile`)
makes it easier to change your choice from streaming to non-streaming or vice versa.

To send output to an ordinary text file, you should just need to do this:

    let myOutFile = OutFile(fileName)
    myOutFile.writeln("some line") // and more lines, and more
    try myInFile.finalize()

But, as with InFile, you can get into some messy details:

- class OutFile, with attributes ...
    - name
    - url
    - hasBeenUsed
- ... and functions
    - init(name:)
    - a bunch of versions of write(message:)
    - finalize()
    - safeWrite()
    - register() [to assist with remembering to call `finalize` on all your OutFiles]
    - finalizeAll()

- class StreamedOutFile, a child class of OutFile as mentioned already. It simply overrides writing to a file and closing it.
