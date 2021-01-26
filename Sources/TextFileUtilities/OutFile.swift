//
//  OutFile.swift: definitions for text-file output
//  
//
//  Created by Jim Clarke on 2021-01-14.

import Foundation

// Don't forget that Swift has print() for standard output -- or, using the to:
// parameter, for other streams such as standard error:
//
//   func print<Target>(Any,
//       separator: String,
//       terminator: String,
//       to: inout Target)


// You might expect to find the following stream classes and the function
// printerr() inside the class StreamedOutFile. But we're going to need them
// outside it too, and they're not defined in terms of its members, so here they
// are.

public class StdStream: TextOutputStream {
    public func write(_ string: String) {}
}

public class StdoutStream: StdStream {
    override public func write(_ string: String) { fputs(string, stdout) }
}

public class StderrStream: StdStream {
    override public func write(_ string: String) { fputs(string, stderr) }
}

public var stderrStream = StderrStream()
public var stdoutStream = StdoutStream()

// Call print(), accepting the usual defaults, sending the output to stderr.
// For stdout, just plain print(String) already works.
public func printerr(_ line: String) {
    print(line, to: &stderrStream)
}


public class OutFile {

    // An object of this class writes text to a file, by preparing a single
    // string that will be the entire file contents, and writing it all at once
    // when the contents are complete.
    //
    // You might want instead to write parts of the output -- say, lines -- as
    // soon as they are ready. That would be streamed output, allowed by the
    // child class StreamedOutFile. It requires you as caller to provide the
    // stream, after creating it if necessary. You can use the two standard
    // streams stdout and stderr, which obviously don't need to be created, but
    // they do need to be wrapped in a TextOutputStream, as shown above.
    //
    // If you're not using streams, you need to remember to call finalize() on
    // your file before your program ends, or the output will never be written.
    // You can do this for all your files at once by calling
    //      OutFile.finalizeAll()
    // Files register themselves on creation in a static list, and finalizeAll()
    // calls finalize() on all files in the list.
    //
    // (I think there are no memory-leak problems arising from maintaining the
    // list of files, but I'm newish to Swift, so we'll see.)
    //
    // It is legal but has no effect to call finalize() on a StreamedOutFile.
    //
    // If you want to make your own streams, or to think harder about file I/O
    // in Swift, here are some references:
    //
    // https://nshipster.com/textoutputstream/
    // -- roughly what we do here in StdStream, but bigger and better
    // https://stackoverflow.com/questions/24097826/read-and-write-a-string-from-text-file
    // https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift


    public let name: String // the name the caller gave us, and probably the one to use
        // in displayed or returned messages
    // let path: String // No! Get the path from url.path!
    public var url: URL
    var output: String
    
    // A caller might want to check whether there has been output to an OutFile
    // after the output has been saved. For example, if the file takes error
    // output, the user might want to see a message printed about whether there
    // have been any errors. Hence this property:
    public internal(set) var hasBeenUsed = false // so we can check without
        // examining "output" -- or in case (e.g. in a StreamedOutFile)
        // "output" is not used
        
    let msgPrefix: String
    
    public init(_ name: String, msgPrefix prefix: String = "") {
        self.name = name
        let path = nameToPath(fileName: self.name)
        let url = URL(fileURLWithPath: path)
        assert(url.path != "", "can't get full path name for file \"name\"")
        self.url = url
        // Further checks on the file URL occur (implicitly) when output is
        // attempted.
        
        self.output = ""
        self.msgPrefix = prefix
        
        // Get on the list of files to be finalize()ed at the end of execution.
        register()
    }


    // "Write" the message, perhaps by adding it to the store of strings to be
    // written later. The write is "base" because any other function wishing to
    // write must do so by calling this function.
    //
    // Child classes rolling their own write techniques will override this
    // function and finalize().
    public func baseWrite(_ message: String) {
        output += message
        hasBeenUsed = true
    }
    
    
    // A collection of "write" functions adding decorations to baseWrite().
    // Leaving them out might be good for the readability of this class (and
    // you can always make more by putting them in an extension to OutFile),
    // but I// decided to make the kitchen sink easy to get to.
    //
    // So, here goes with the first inhabitant of the "write" zoo:
    //
    // "Write" the message ...
    //
    // ... preceded by this file's standard msgPrefix (a label for every line).
    public func write(_ message: String) {
        baseWrite(msgPrefix + message)
    }
    
    // ... preceded by this file's msgPrefix and followed by a newline.
    public func writeln(_ message: String) {
        // Calling "write" instead of calling baseWrite directly.
        // output += addedMsg
        write(message + "\n")
    }
    
    // ... preceded by this file's msgPrefix and identified by the line number.
    // The line number is increased by 1 on the assumption that the "line" is
    // part of an array with 0-based indices, but that the reader is looking at
    // a 1-based file listing.
    public func writeln(_ line: Int, _ message: String) {
        // Notice that we're calling writeln, so we get msgPrefix automatically.
        writeln("at line \(line + 1), " + message)
    }
    
    // ... and that's all the kitchen sinks (or zoo animals), folks.
    
    
    // This function, like baseWrite(), will be overridden by child classes
    // building their own way of producing output.
    //
    // Throws a FileError if writing fails.
    
    public func finalize() throws {
        if FileManager.default.fileExists(atPath: url.path)
                && !FileManager.default.isWritableFile(atPath: url.path) {
            throw FileError.failedWrite("""
File output failed for file \"\(self.name)\"
    File does not have write permission.
""")
        }
        do {
            try output.write(to: url,
                          atomically: true,
                          // encoding: String.Encoding.utf8)
                          encoding: .utf8)
        } catch {
            // Decorate and rethrow.
            throw FileError.failedWrite("""
File output failed for file \"\(self.name)\"
    Error description from write call:
    \(error)
""")
        }
    }

    // Do the same work as finalize(), but write to a temporary file first and
    // then move the temporary file to the actual file location. The purpose is
    // to ensure that if there is a failure during writing to the temporary
    // file, the actual file is left undamaged; or that if the actual file is
    // unwritable, the temporary file is left still available.
    //
    // Throws a FileError if writing fails to either the temporary file or the
    // actual file.
    //
    // Child classes that cannot simply inherit this implementation should
    // either override this function with a working replacement or override it
    // with a replacement that throws an error, so as not to mislead the caller
    // into unjustified complacency.
    
    public func safeWrite() throws {
        // Step 1: write to a temporary file.
        var temporaryFileURL: URL
        do {
            // Make a temporary directory.
            let temporaryDirectoryURL =
                try FileManager.default.url(for: .itemReplacementDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: self.url,
                                            create: true)
            let temporaryFilename = ProcessInfo().globallyUniqueString
            temporaryFileURL =
                temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
            try output.write(to: temporaryFileURL,
                          atomically: true,
                          encoding: .utf8)
        } catch {
            // Decorate and rethrow.
            throw FileError.failedWrite("""
Output to temporary file failed for file \"\(self.name)\"
The original file should be intact (but unchanged).
    Error description from write to temporary file:
    \(error)
""")
        }

        // Step 2: move the temporary file to the actual file's location.
        let backupName = FileManager.default.displayName(atPath: self.url.path)
            + ".backup"
        do {
            // can't use FileManager.default.moveItem(at:to:); it won't
            // overwrite an existing file!
            let newURL = try FileManager.default.replaceItemAt(self.url,
                withItemAt: temporaryFileURL,
                backupItemName: backupName,
                // options: [.withoutDeletingBackupItem])
                options: [])
            if newURL != self.url {
                throw FileError.failedWrite("mismatched file copy URLs")
            }
        } catch {
            // Decorate and rethrow.
            throw FileError.failedWrite("""
File output failed for file \"\(self.name)\" during move from temporary file.
The output is temporarily available in the file
        \"\(temporaryFileURL.path)\"
If you want to use the temporary file's contents, please do so soon.

Error description from attempted move:
    \(error)
"""
            // The error message used to say this ...
            // The output is temporarily available in the file
            //         \"\(backupName)\"
            // or, if that is unavailable, in
            //         \"\(temporaryFileURL.path)\"
            // ... but the backup file was being deleted even though the
            // operation failed.
)
        }
    }
    
    
    // The class maintains a list of files that have been created. A file is
    // registered by init() and, if finalizeAll() is called, has its own
    // finalize() called then.
    //
    // A file can be registered by the user, by calling its register() method,
    // and can also be deregistered with deregister(). However, the hope is that
    // that will seldom be necessary. All the user should have to do is to call
    // the class method finalizeAll() when output to all files is complete.
    //
    // It may be a design error to make deregistration optional, or even to let
    // the caller mess with the registration process at all. As an alternative,
    // deregistration could happen automatically within finalize(), or perhaps
    // collectively within finalizeAll(). Right now, I don't have a clear enough
    // idea of what a reasonable caller could want, so I'm leaving things loose.
    
    // I don't think the references in the outfiles list need to be weak, or
    // that the OutFile class needs to have a deinit(). Of course, if there
    // were a deinit(), there might be no need for finalize() or finalizeAll();
    // but I'm not happy to just leave the whole output thing up to the memory
    // cleanser.

    public static var outfiles = [OutFile]()

    public func register() {
        OutFile.outfiles.append(self)
    }
    // public static func register(_ outfile: OutFile) {
    //     OutFile.outfiles.append(outfile)
    // }
    
    // Remove file from the registry. You should not need to call this function
    // unless you are calling file.finalize() separately and don't want it to be
    // called twice. And why are you doing that (unless you're debugging)?
    //
    // If file is not in the registry, throws a FileError.failedWrite. Since all
    // OutFiles are registered at initialization, this error can presumably only
    // happen if a file is deregistered twice.
    
    public func deregister() throws
    {
        if let which = OutFile.outfiles.firstIndex(where: {$0 === self}) {
            OutFile.outfiles.remove(at: which)
        } else {
            throw FileError.failedWrite("""
attempt to deregister unregistered file \"\(name)\"
--- possible double deregistration?
"""
            )
        }
    }
    
    // It is probably a mistake to call finalize() on one file if you also call
    // finalizeAll() -- or vice versa. Consider calling deregister() after
    // finalize(), to prevent finalizeAll() from touching the file.
    //
    // If finalize() fails on any file on the output list, we proceed to the
    // next file, saving the error message, and throw a FileError.failedWrite
    // at the end, with the whole collection of error messages.
    
    public static func finalizeAll() throws {
        var message = ""
        for file in OutFile.outfiles {
            do {
                try file.finalize()
            } catch FileError.failedRead(let msg) {
                // Build message for later combined rethrow.
                message += msg
            } catch {
                // This shouldn't happen, because <file>.finalize() should only
                // throw FileErrors. But just in case, keep building the message ...
                message += """
File output failed for file \"\(file.name)\"
    Error description from write call:
    \(error)
"""
            }
        }
        
        if message != "" {
            let prefix = """
There was a failure during final output for at least one file.
Here are all the error messages:

"""
            throw FileError.failedWrite(prefix + message)
        }
    }
}


class StreamedOutFile: OutFile {
    
    // This class allows you to dress up stdout and stderr in the mechanims
    // defined by OutFile. You can just use print() directly, of course, but
    // this allows you to change your mind about whether a part of your output
    // is going to a file or not, changing only the definition of your OutFile.
    //
    // Also, it's kind of fun.
    //
    // Be aware that output from a StreamedOutFile appears "immediately" rather
    // than being saved up for the end of execution. That's a choice, which
    // could be changed by rewriting baseWrite() and finalize().


    var stream: StdStream

    public init(_ name: String, msgPrefix prefix: String = "",
            stream: StdStream)
    {
        self.stream = stream
        super.init(name, msgPrefix: prefix)
    }
    
    public override func baseWrite(_ message: String) {
        // "message" is not added to "output" string.
        print(message, terminator: "", to: &stream)
        hasBeenUsed = true

        // To switch to producing output at the end of execution, comment out
        // the previous "print" line, and uncomment this line:
        //      output += message
        // And also, fix finalize() as noted there.
    }

    public override func finalize() {
        // We don't have to do anything, since the output has been printed on
        // the go. However, we do need this empty function so that
        // OutFile.finalizeAll() works properly.

        // Should we assert that "output" is empty?
        
        // To switch to producing output at the end of execution, uncomment this
        // line:
        // print(output, to: &stream)
    }
    
    public override func safeWrite() throws {
        throw FileError.failedWrite("""
Safe writing failed: not available for file \"\(self.name)\"
"""
        )
    }
}
