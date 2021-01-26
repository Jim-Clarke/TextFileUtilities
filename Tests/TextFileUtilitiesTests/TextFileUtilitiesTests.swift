import XCTest
@testable import TextFileUtilities

// In this file are tests that don't belong specifically to input or output,
// such as nameToPath().
//
// First a longish note about setting up.

// YOU (probably) HAVE TO CHANGE A SETTING!
//
// Why? because this package is all about files, so you need to test it with
// files. But you can't put test files in Xcode's working directory,
// /private/tmp (see below); they're part of the package you retrieved from git,
// and they should stay with the rest of the package.
//
// YOU HAVE TO TELL XCODE WHERE TO FIND THE DIRECTORY Tests/Resources, which
// contains those test files.
//
// I do this by defining an Xcode environment variable called
//      TestFileDirectory
// giving the whole path from my home directory to Tests/Resources
//
// For me, that means the value of TestFileDirectory is
//      Documents/computing/src/Swift/TextFileUtilities/Tests/Resources/
// For you, it is probably at least somewhat different.
//
// So: click on the project name with the little house (Greek temple?) beside
// it, on the Xcode toolbar, and select the "Edit Scheme..." option. Click on
// Test and then on the Arguments tab. You should be set to define your new
// variable, TestFileDirectory.
//
// You're probably asking, "But don't I have to tell Xcode my home directory?"
// Happily, no. Xcode sets up another variable, HOME, all by itself.
//
// Take a look at the beginning of InFileTests or OutFileTests to see how all
// this works.

// One other thing, one of the InFile tests, testReadFromURL(), is fragile. It
// depends on one of the files on my computer and on a file in my web page. The
// computer file is inaccessible to you, so that part is commented out, but I'm
// daring the fates by leaving the web file in. Go to the end of
// InFileTests.swift and comment it out if it turns out that the fates are
// laughing at me.


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
