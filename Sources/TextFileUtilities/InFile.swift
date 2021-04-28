//
//  InFile.swift: definitions for text-file input
//  
//
//  Created by Jim Clarke on 2021-01-14.

import Foundation
    
// Don't forget that Swift has a readLine() for standard input:
//  func readLine(strippingNewline: Bool = true) -> String?

public class InFile {

    // An object of this class reads text from an entire file into a single
    // string, and then splits the string on newlines. What if the file is
    // huge? Well, the splitting process could take a long time.
    //
    // To fix that, you could rewrite contentsToLines(), perhaps offering the
    // new version as an alternative method in this class. My preferred
    // alternative is to wait until Swift grows up and offers something
    // efficient instead of making you call obscure NS functions.
    //
    // But if you can't wait for Swift to grow up, here's a place to look at
    // several alternative implementations, current as of late 2020:
    // https://forums.swift.org/t/difficulties-with-efficient-large-file-parsing/23660/20

    // How to read a file, and where it happens
    // -----
    // 1. init(): Convert the file name to an absolute path name.
    // 2. init(): Convert the path to a URL.
    // 3. readContents(): Check whether the file exists.
    // 4. readContents(): Read the contents of the file as a single string.
    // 5. chooseNewline(): Pick a newline character (by default "\n").
    // 6. contentsToLines(): Break up the contents into lines.
    //
    // The calls for steps 3 to 6 are in read(). To make the process run
    // faster, you'll want to rewrite contentsToLines(), as mentioned above.
    //
    // But if you're OK with the process as provided here, just make an InFile
    // object init() and call its read(). You can accept read()'s default
    // newline unless the file gives trouble.


    public let name: String // the name the caller gave us, and probably the one to use
        // in displayed or returned messages
    // let path: String // No! Get the path from url.path!
    public let url: URL
    let checkURLforValidPath: Bool // If it's a non-file URL, don't do this.

    public var contents: String = "" // initialized to keep the compiler happy,
        // -- and the user. And yes, it needs to be publicly writable too.
    public internal(set) var lines = [Substring]()
    
    // Make an object representing the named file. The name is relative to the
    // working directory (unless it begins with "/" or "~"), so in many cases
    // the name is simply the string you would use from the command line to
    // specify this file.
    
    public init(_ name: String) {
        self.name = name

        // 1. Convert the file name to an absolute path name.
        let path = nameToPath(fileName: self.name)
        self.checkURLforValidPath = true

        // 2. Convert the path to a URL.
        self.url = URL(fileURLWithPath: path) //checked in readContents()
    }

    // Build an InFile that lives somewhere out there on, perhaps, the Internet.
    // The name argument is just for decoration, and the urlString's path is not
    // checked to see that it's a valid path to a file.
    //
    // I wouldn't expect this form of InFile to be of much use, but here it is,
    // with minimal testing.
    
    public init(name: String, urlString: String) throws {
        self.name = name
        if let url = URL(string: urlString) {
            self.url = url
        } else {
            throw FileError.failedRead(
                "Invalid URL \"\(urlString)\""
                )
        }
        self.checkURLforValidPath = false // It might not be a file.
    }


    // Read this file's contents. Ordinarily the user is not expected to call
    // this method -- it's called by read() -- but the contents are available
    // directly from the file's contents property after the method call.
    //
    // Throws a FileError if reading fails.

    public func readContents() throws
    {
        // 3. Check whether the file exists.
        if checkURLforValidPath
                && !FileManager.default.fileExists(atPath: url.path) {
            throw FileError.failedRead("""
File input failed from file \"\(self.name)\"
    File does not exist.
""")
        }

        // 4. Read the file URL.
        do {
            try contents = String(contentsOf: url)
        } catch {
            // Decorate and rethrow.
            throw FileError.failedRead("""
File input failed from file \"\(self.name)\"
    Error description from read call:
    \(error)
""")
        }
    }


    // Examine the contents of this file, and decide what newline character is
    // appropriate. If "\n" occurs anywhere in the file, choose "\n";
    // otherwise, if "\r\n" occurs anywhere,  choose "\r\n" (which is a single
    // character, except when encoded in the actual file); otherwise, return
    // nil.
    //
    // We do not consider the ancient Mac newline, "\r". Notice that it doesn't
    // matter which newline appears first: a "\n" anywhere takes precedence over
    // any number of preceding instances of "\r\n".
    
    public func chooseNewline() -> Character?
    {
        if contents.firstIndex(of: "\n") != nil {
            return "\n"
        } else if contents.firstIndex(of: "\r\n") != nil {
            return "\r\n"
        } else {
            return nil
        }
    }


    // Break the contents of this file into lines around the newline character,
    // storing the results in the file's "lines" member.
    //
    // This function could be a time sink for very large files. See the
    // comments at the beginning of this class.
    //
    // If newline is not provided, or is nil, use "\n".

    public func contentsToLines(newline: Character? = nil)
    {
        // If the caller chose a newline for us, use it. Otherwise, use the
        // usual one, "\n".
        //
        // If the caller "chose" a nil newline, that may be because no usable
        // newline was found in the file. In that case, we'll be producing one
        // giant Substring (as the single element of an array [Substring]).
        
        if newline == nil {
            lines = contents.split(separator: "\n")
        } else {
            lines = contents.split(separator: newline!)
        }
    }


    // Return the contents of this file, read from the file and broken into an
    // list of Substrings. If no newline is specified, a hopefully suitable
    // value is obtained by examining the contents before splitting.
    //
    // The conversion to an list of Substrings is done by a call to
    // contentsToLines(). It may be time-consuming if the file is very large.
    // See the comments at the beginning of this class for discussion.
    //
    // If newline is specified in the call, and is not nil, that newline is
    // used. If it is unspecified or nil, chooseNewline() is called in the hope
    // of figuring it out; if it fails, then "\n" is used.
    //
    // If the results are unsatisfactory, then instead of calling this
    // function, you can call readContents() and analyze the resulting string as
    // you like. If the file uses more than one newline character, it may help
    // to make multiple calls to contentsToLines().
    //
    // Throws a FileError if reading fails.

    public func read(newline: Character? = nil) throws -> [Substring]
    {
        do {
            try readContents()
            
            var usingNewline: Character?
            if newline != nil {
                usingNewline = newline
            } else {
                usingNewline = chooseNewline()
                // usingNewline may still be nil, but we tried.
                // contentsToLines() will decide what to do (namely, use "\n").
            }
            
            contentsToLines(newline: usingNewline)
            
            return lines
            
        } catch FileError.failedRead(let msg) {
            // Rethrow.
            throw FileError.failedRead(msg)
        } catch {
            // Decorate and rethrow.
            throw FileError.failedRead("""
File input failed from file \"\(self.name)\"
    Error description from read call:
    \(error)
""")
        }
    }
} // end of class InFile
