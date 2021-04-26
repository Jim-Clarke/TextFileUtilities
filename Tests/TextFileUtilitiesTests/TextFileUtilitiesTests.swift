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


// extension FileError: Equatable {
//     // We need an explicit == function, even though one is provided if we don't
//     // say anything. The problem is that the provided implementation checks the
//     // error messages for equality, and code trying to ensure standardized
//     // messages would be quite fragile.
//     public static func ==(lhs: FileError, rhs: FileError) -> Bool {
//         switch (lhs, rhs) {
//         case (.failedRead, .failedRead):
//             return true
//         case (.failedWrite, .failedWrite):
//             return true
//         default:
//             return false
//         }
//     }
// }



extension FileError: Equatable {

    // An explicit == function to replace the one provided. I don't want
    // to compare the error messages for exact equality, because if the tests
    // failed every time a message changed, I'd get tired of fixing tests.
    // So this implementation of Equatable checks that the shorter "error
    // message" -- presumably as specified in the test case -- is contained in
    // the actual error message produced by the code that is run in the test.
    //
    // At one point I tried using a special test-checking case of the enum, just
    // to carry the expected test "error message", but this required ignoring
    // which enum case carried the real error message, and that seemed bad.

    public static func ==(lhs: FileError,
                          rhs: FileError) -> Bool {

        // func longerContainsShorter(_ one: String, _ two: String) -> Bool {
        //     // s.contains("") is false for any String s, it seems; but if either
        //     // parameter is empty, surely the empty one is contained by the
        //     // other.
        //     if one == "" || two == "" {
        //         return true
        //     }
        //     let oneLonger = one.count > two.count
        //     return (oneLonger && one.contains(two))
        //         || (!oneLonger && (two.contains(one)))
        // }

        func oneContainsOther(_ dum: String, _ dee: String) -> Bool {
            // It's possible to write a version of this function that checks the
            // lengths of the two strings and avoids one of the two contains()
            // calls; but the gain is an improvement of efficiency that occurs
            // only during unit testing and is very likely minimal, while the
            // cost is a noticeably more complicated mental effort in checking
            // the code, so it's a net loss. (But see the commented-out function
            // above to realize that it seduced me for a while.)
            //
            // The last two checks, for the case where one string is empty, are
            // unavoidable because s.contains("") is false for any String s. I
            // suppose there must be a good argument for this, but not here:
            // if the parameters are error messages, and either one is empty,
            // we want to think the empty one is contained by the other.

            return dum.contains(dee) || dee.contains(dum)
                || dum == "" || dee == ""
        }

        switch (lhs, rhs) {
        case (.failedRead(let left), .failedRead(let right)):
            return oneContainsOther(left, right)
        case (.failedWrite(let left), .failedWrite(let right)):
            return oneContainsOther(left, right)
        default:
            return false
        }
    }
}

