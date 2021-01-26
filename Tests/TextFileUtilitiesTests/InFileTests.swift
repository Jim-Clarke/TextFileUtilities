import XCTest
@testable import TextFileUtilities

// Test the InFile class.

final class InFileTests: XCTestCase {

    // Where to find test files: the Xcode environment variable
    // TestFileDirectory tells us where to look.

    let testInFileDirectory = ProcessInfo.processInfo.environment["HOME"]!
        + "/" + ProcessInfo.processInfo.environment["TestFileDirectory"]!
        + "testfiles/in/"
    
    // Test a couple of cases that involve files but don't involve the
    // actual file contents.
    
    func testNonexistentInFile() {
        let dummyreadfilename = "data.doesnotexist"  // no such file
        let dummyreadfile = InFile(dummyreadfilename)
        XCTAssertThrowsError(try dummyreadfile.read(), "expected no-such-file error") { error in
            XCTAssertEqual(error as? FileError, .failedRead(""), "wrong error type") }
    }
    
    func testBadPermissions() {
        // To run this test, we need a file without read permissions. File like
        // that break the copying operations needed for repository commits and
        // retrievals.
        //
        // So the test file used here is kept WITH read permission, which the
        // code below removes programmatically before running the test and
        // restores after the test.
        //
        // If you cleverly take the read permission away, thinking things are
        // broken, the "restore the permission" step below will "restore" the
        // read NON-permission. So don't do that.
        
        let noreadfilename = "data.noreadpermission"  // permissions 200/-w-...
        let noreadfile = InFile(testInFileDirectory + noreadfilename)

        do {
            // Retrieve existing file permissions
            let filePath = noreadfile.url.path
            var attribs =
                try FileManager.default.attributesOfItem(atPath: filePath)
            let oldPermissions = Int("\(attribs[.posixPermissions]!)")!
            
            // Take away all read permissions
            let newPermissions = oldPermissions & 0b011011011
            attribs[.posixPermissions] = newPermissions
            try FileManager.default.setAttributes(attribs,
                                                  ofItemAtPath: filePath)
            
            // Run the test
            XCTAssertThrowsError(try noreadfile.read(),
                                 "expected no-read-permission error")
            {
                error in
                XCTAssertEqual(error as? FileError,
                               .failedRead(""),
                               "wrong error type")
            }
            
            // Restore the original permissions
            attribs[.posixPermissions] = oldPermissions
            try FileManager.default.setAttributes(attribs,
                                                  ofItemAtPath: filePath)
        } catch {
            XCTFail(
            "unexpected error during InFile no-read-permissions test: \(error)")
        }
    }


    // Test string splitting without reading from a file.
    
    struct TestString {
        var value: String
        // the remaining fields are the EXPECTED values
        var newline: Character?
        var lines: [Substring]
        
        init(_ value: String, _ newline: Character?, _ lines: [Substring]) {
            self.value = value
            self.newline = newline
            self.lines = lines
        }
    }
    
    let teststrings = [
        TestString("hi,\nmom\nit's \nme\n", "\n", ["hi,", "mom", "it's ", "me"]),
        TestString("hi,\r\nmom\r\nit's \r\nme\r\n", "\r\n", ["hi,", "mom", "it's ", "me"]),
        TestString("hi,\nmom\r\nit's \nme\r\n", "\n", ["hi,", "mom\r\nit's ", "me\r\n"]),
        TestString("hi,\r\nmom\nit's \r\nme\n", "\n", ["hi,\r\nmom", "it's \r\nme"]),
        TestString("hi, mom it's me\n", "\n", ["hi, mom it's me"]),
        TestString("", nil, []),
        // TestString("\n\n", nil, []), // nil isn't the newline that would be
        // chosen, so we'll have to check this one separately.
        TestString("\n\n", "\n", []),
        TestString("Hi, mom, I forgot my newline.", nil, ["Hi, mom, I forgot my newline."]),
    ]
    
    // Read two empty lines with nil newline.
    //
    // This is the test case omitted from teststrings[]. It checks that "\n" is
    // correctly chosen, but then if nil is force-fed to contentsToLines(newline:),
    // the process still uses "\n".
    
    func testTwoEmptyLinesWithNilNewline() {
        let twonewlinetestreadfilename = "data.twonewlinetest"  // no such file
        let twonewlinetestreadfile = InFile(twonewlinetestreadfilename)
        
        twonewlinetestreadfile.contents = "\n\n"
        let twonewline = twonewlinetestreadfile.chooseNewline()
        XCTAssertEqual(twonewline, "\n") // ... but we want to use newline == nil instead
        twonewlinetestreadfile.contentsToLines(newline: nil)
        XCTAssertEqual(twonewlinetestreadfile.lines, [])
    }
    
    // Test chosen newline and split-up content (without an actual file) ...
    // ... starting with two helper functions.
    
    func checkChooseNewline(data: String, expectedNewline: Character?)
    {
        let tempfile = InFile("no such file")
        tempfile.contents = data
        let newline: Character? = tempfile.chooseNewline()
        XCTAssertEqual(newline, expectedNewline)
    }
    
    
    func checkContentsToLines(data: String,
                              expected: [Substring],
                              newline: Character? = nil)
    {
        let tempfile = InFile("no such file")
        tempfile.contents = data
        tempfile.contentsToLines(newline: newline)
        XCTAssertEqual(tempfile.lines, expected)
    }

    func testContentsAndNewLines() {
        for ts in teststrings {
            checkContentsToLines(data: ts.value,
                                 expected: ts.lines,
                                 newline: ts.newline
            )
            checkChooseNewline(data: ts.value, expectedNewline: ts.newline)
        }
    }
    
    // Done testing string splitting
    
    
    // Test file reading and splitting into lines, using files located in
    // testInFileDirectory.
    
    struct TestFile {
        var name: String
        // the remaining fields are the EXPECTED values
        var contents: String
        var lines: [Substring]
        
        init(_ name: String, _ contents: String, _ lines: [Substring]) {
            self.name = name
            self.contents = contents
                // These are the file contents as a single string for the entire
                // file -- that is, before splitting into lines. Within the actual
                // files, presumably the contents are encoded as UTF-8, so the \r
                // and \n characters are separate, even though Swift views \r\n as a
                // single character when it is used as a newline for splitting the
                // file contents into lines.
            self.lines = lines
        }
    }

    let testfiles = [ // Yes, I know, "testfiles" is also a directory name.
        TestFile("data.crlf", """
hi,\r
mom\r
it's\r
me\r

""",  ["hi,", "mom", "it's", "me"]),
        
        TestFile("data.crlffirst", """
hi,\r
mom
it's\r
me

""", ["hi,\r\nmom", "it's\r\nme"]),
        
// Aargh! Xcode editor keeps deleting trailing blank on the "it's " line,
// in the files data.nl and data.nlfirst. The .crlf files are OK, presumably
// because in those files the blank isn't seen as trailing.
//
// Fix: I'm deleting the trailing blanks in all files -- both .nl and .crlf.
        
        TestFile("data.nl", """
hi,
mom
it's
me

""", ["hi,", "mom", "it's", "me"]),

        TestFile("data.nlfirst", """
hi,
mom\r
it's
me\r

""", ["hi,", "mom\r\nit's", "me\r\n"]),
        
        TestFile("data.nonewline",
                 "Hi, mom, I forgot my newline.", ["Hi, mom, I forgot my newline."]),
    ]
    
    func testReadAndSplitFiles() {
        for tf in testfiles {
            let file = InFile(testInFileDirectory + tf.name)
            do {
                XCTAssertNoThrow(try file.readContents())
                // I needed the elaborate message for a while, and it can't hurt to keep it.
                XCTAssertEqual(file.contents, tf.contents, """
file: \(file.name) contents:
\(file.contents)
expected:
\(tf.contents)
""")
                
                var filelinesread: [Substring]
                try filelinesread = file.read()
                XCTAssertEqual(filelinesread, tf.lines, "lines different!\n\n\n")
            } catch {
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    // Done testing file reading
 
    
    // Test reading directly from URL
    
    func testReadFromURL() {
        let fileIDs = [
//            [ // An innocent file that I don't expect will change soon
//                "ignore1",
//                "file:///Users/clarke/.zshrc",
//                "# March 2020: switching from bash to zsh"
//            ],
            [ // This one has been the same for years
                "ignore2",
                "http://www.cs.utoronto.ca/~clarke/index.html",
                "<!DOCTYPE HTML PUBLIC \"-//W3C"
            ],
        ]
        for fileID in fileIDs {
            let name = fileID[0]
            let urlString = fileID[1]
            var urlFile = InFile("keep the compiler quiet")
            XCTAssertNoThrow(urlFile = try InFile(name: name, urlString: urlString))
            XCTAssertNoThrow(try urlFile.readContents())
            XCTAssert(urlFile.contents.starts(with: fileID[2]))
        }
    }

    // Done testing reading from URL
    
    // Done testing InFile

}
