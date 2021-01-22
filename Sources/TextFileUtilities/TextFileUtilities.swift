// This package wraps the vanilla Swift processes for input and output of text
// data from and to files. I'm unhappy with their likely inefficiency in the
// case of very large (many-megabyte) files, but I'd be unhappier to be using
// bridged NS-based functions. Surely Swift will eventually include less
// shaky-looking approaches?
//
// In the meantime, my hope is that this package will help me to remember what
// how to read and write a little better, and that it will help me to replace
// these implementations, when Swift actually does improve, without having to
// uproot a bunch of nearly forgotten code.
//
// Although input and output implementations are nearly completely separate,
// they do have in common that they represent the entire contents of a file with
// a single String.
//
// -- Dec/20 - Jan/21

// References that helped, and might again in the future:
// https://nshipster.com/filemanager/
// https://nshipster.com/temporary-files/

/*
* Choices
* -----
*
* The definitions and discussion here are intended to help with reading and
* writing text files from beginning to end (that is, not altering a file
* in-place). Besides providing useful functions and other definitions, a
* second goal is to provide reminders to the reader (me!) of things likely to be
* forgotten.
*
* Output is implicitly line-by-line. Input proceeds by reading an entire file
* and then splitting it into lines, but the splitting step can be omitted.
*
* For input, I avoid using unsafe pointers, and I prefer standard Swift. This
* means choosing String.init(file) rather than fgets. See input reference (4)
* for some background.
*
* Output is simpler than input, but I still prefer just plain Swift.
*/


import Foundation

// Definitions needed for both input and output


// Errors are classified according to what was happening when they arose --
// either input or output. If a call throws an error, then we attempt to wrap
// it in a FileError, with the thrown error included in the "msg" of the
// FileError.

enum FileError: Error, Equatable {
    case failedRead(_ msg: String)
    case failedWrite(_ msg: String)
    
    // We need an explicit == function, even though one is provided if we don't
    // say anything. The problem is that the provided implementation checks the
    // error messages for equality, and code trying to ensure standardized
    // messages would be quite fragile.
    static func ==(lhs: FileError, rhs: FileError) -> Bool {
        switch (lhs, rhs) {
        case (.failedRead, .failedRead):
            return true
        case (.failedWrite, .failedWrite):
            return true
        default:
            return false
        }
    }
}


// Convert fileName into an absolute path name suitable for conversion to a file
// URL with URL(fileURLWithPath: nameToPath(...)).
//
// The path returned by nameToPath is going to be handed to
// URL(fileURLWithPath: path) to get a file URL. You can also just give the
// fileName directly to URL(fileURLWithPath:), but that misbehaves with tilde
// for the home directory, so it's better to go through nameToPath first.
// However, after creating the URL, you should prefer to retrieve the path by
// using the URL's path property: myURL.path.
//
// fileName - a String representing a file name, for example a command-line
//      argument. It may start with a tilde ('~') indicating an account name, or
//      with a slash ('/') indicating an absolute path.
// return value - a String representing a fully-qualified path to a file, but
//      which has not yet been converted into a file URL

func nameToPath(fileName name: String) -> String
{
    // let heredir = FileManager.default.currentDirectoryPath
    let startChar = name[name.startIndex]

    // var path = ""
    if !"/~".contains(startChar) {
        // path = heredir + "/" + name
        return NSString(string: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(name)
    } else if startChar == "/" {
        return name
    } else if startChar == "~" {
        return NSString(string: name).expandingTildeInPath
    }
    
    assert(false, "reached end of nameToPath() choices")
}
