import XCTest
@testable import TextFileUtilities

// In this file are tests that don't belong specifically to input or output,
// such as nameToPath().
//
// There's also some advice and help. Here goes; the first one is longish.

// YOU MIGHT HAVE TO CHANGE AN XCODE SETTING! Here's why:
//
// This package is all about files, so you need to test it with files.
// You can't put test files in Xcode's working directory, /private/tmp.
//
// Consequently, in any test class that uses the test files, you have
// to tell Xcode where to look for them. For this project, the test
// classes InFileTests and OutFileTests are the ones that use test files.
// (This class you're looking at right now, TextFileUtilitiesTests, does
// not.)
//
// The test files are in two directories, "testfiles/in" and
// "testfiles/out", and "testfiles" itself is where I decided to put it:
// in a directory given by the Xcode environment variable
//      TestFileDirectory
// TestFileDirectory is a string representing a path relative to the home
// directory of the account running the tests. Xcode sets that location
// automatically for you, and saves it in another environment variable,
//      HOME
// so the test classes actually look in
//      HOME + TestFileDirectory + "testfiles" + ["in" or "out"}
// with "/" added where needed.
//
// To set TestFileDirectory, edit (in Xcode) the scheme for the project,
// by clicking on the project name in the largish control on the window's
// title bar.
//
// To retrieve TestFileDirectory, do this:
//      ProcessInfo.processInfo.environment["TestFileDirectory"]
// The environment is a dictionary, so the value returned is an optional;
// but since we're testing, not running, it's OK to force-unwrap it.
// You'll see that in the test classes' code.
//
// If you want to run the tests outside Xcode, you'll need to set the
// appropriate locations in the obvious (I hope) places. A greater
// annoyance will be replacing all the XCTAssert...() calls with plain
// assert().


// ONE OF THE TEST FILES NEEDS ITS UNIX PERMISSIONS FIXED.
//
// The file is testfiles/in/data.noreadpermission. I can't distribute
// it without read permission! But you have to fix that before the
// tests can work:
//  [your command prompt] $ chmod 200 data.noreadpermission
// You should now see:
//  [your command prompt] $ ls -l data.noreadpermission
//  --w-------  1 [your account]  staff  29 31 Dec 14:31 data.noreadpermission
//
// You might have to fix testfiles/out/out.nowritepermission. If
// there's trouble, you can see it and fix it with these commands:
//  [your command prompt] $  ls -l out.nowritepermission
//  -rw-------@ 1 clarke  staff  0  7 Jan 15:35 out.nowritepermission
//  [your command prompt] $ chmod 400 out.nowritepermission
//  [your command prompt] $ ls -l out.nowritepermission
//  -r--------@ 1 clarke  staff  0  7 Jan 15:35 out.nowritepermission


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
