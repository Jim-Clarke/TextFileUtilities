import XCTest
@testable import TextFileUtilities

// In this file are tests that don't belong specifically to input or output,
// such as nameToPath().
//
// There's also some advice and help. Here goes; the first one is longish.

// YOU MIGHT HAVE TO CHANGE SOME SETTINGS!
//
// Why? because this package is all about files, so you need to test it with
// files. Butyou can't put test files in Xcode's working directory,
// /private/tmp (see (1) below), and some files just don't want to be moved
// around (see (2)).
//
// 1) THIS PACKAGE INCLUDES SOME STANDARD TEST FILES, LOCATED IN THE DIRECTORY
// TESTS/RESOURCES. YOU HAVE TO TELL XCODE WHERE TO LOOK FOR THEM, and the way
// I've picked is to define an Xcode environment variable called
//      TestFileDirectory
// giving the whole path from my home directory to .../Tests/Resources
// For me, that means the value of TestFileDirectory is
//      Documents/computing/src/Swift/TextFileUtilities/Tests/Resources/
// For you, it probably is at least somewhat different.
//
// So: click on the project name with the little house (Greek temple?) beside
// it, on the Xcode toolbar, and select the "Edit Scheme..." option. Click on
// Test and then on the Arguments tab. You should be set to define your new
// variable, TestFileDirectory.
//
// (Xcode has already set up another variable, HOME, that says where your home
// directory is. That's why TestFileDirectory is defined relative to your home.
// Take a look at the beginning of InFileTests or OutFileTests to see this.)
//
//
// 2) ONE OF THE TEST FILES NEEDS ITS UNIX PERMISSIONS FIXED.
// The test files are in two directories, "testfiles/in" and "testfiles/out",
// The file testfiles/in/data.noreadpermission needs to exist but be unreadable,
// as its name says -- but if it's unreadable, it can't be committed to the git
// repository, so as you've downloaded it from github, it is readable.
//
// To fix that, open Terminal and cd to testfiles/in. Look at the file:
//  [your command prompt] $ ls -l data.noreadpermission
//  -rw-------  [...] data.noreadpermission
// The fix is:
//  [your command prompt] $ chmod 200 data.noreadpermission
// and fixed, it looks like this:
//  --w-------  [...] data.noreadpermission
//
// (You'd think you could do that from the Finder's Get Info on the file. Nope.
// Finder thinks what you want is silly -- which it is, but some tests have to
// be silly.)
//
// There's another file, testfiles/out/out.nowritepermission, but git is happy
// with that one, and you shouldn't have to bother with it.

// In addition, one of the InFile tests, testReadFromURL(), is fragile:
// it depends on one of the files on my computer and on a file in my
// web page. The computer file is inaccessible to you, so that part is
// commented out, but I'm daring the fates by leaving the web file in.
// Go to the end of InFileTests.swift and comment it out if it turns
// out that the fates are laughing at me.


final class TextFileUtilitiesTests: XCTestCase {
    
    // If you'd like to see all the environment variables, uncomment this function
    // and struggle through the results, buried in the printed test output.
    
//    func testWhereWeAre() {
//        for (key, value) in ProcessInfo.processInfo.environment {
//            print("\(key)\t\t\(value)")
//        }
////        print(ProcessInfo.processInfo.environment["PROJECT_FILE_PATH"]!) // doesn't exist
//        XCTAssert(true)
//    }

    func testTestLocation() {
        XCTAssert(FileManager.default.currentDirectoryPath == "/private/tmp")
    }

    let testFileNamePairs = [
        ["anything", FileManager.default.currentDirectoryPath + "/anything"],
        ["anything", "/private/tmp/anything"],
           ["~/anything", "/Users/clarke/anything"],
        ["~clarke/anything", "/Users/clarke/anything"],
//        ["~someone/anything", "/Users/someone/anything"], // fails -- because no such user?
    ]

    func testNameToPath() {
        for pair in testFileNamePairs {
            XCTAssert(nameToPath(fileName: pair[0]) == pair[1])
        }
    }

}
