import XCTest
@testable import TextFileUtilities

// Test the InFile class.

final class OutFileTests: XCTestCase {

    // Where to find test files: the Xcode environment variable
    // TestFileDirectory tells us where to look.

    let testOutFileDirectory = ProcessInfo.processInfo.environment["HOME"]!
        + "/" + ProcessInfo.processInfo.environment["TestFileDirectory"]!
        + "testfiles/out/"

    // Some tests create new files. We don't want to leave them lying around.
    
    // Files that some test actually wrote to and that shouldn't be left
    // lying around.
    var filesToForget = [OutFile]()
    
    override func tearDown() {
        // Remember, this happens after every test, and should be unnecessary
        // if our bookkeeping is good. But any waste of time is pretty
        // irrelevant in these rather quick tests.
        
        // Make sure the next test can assume the list OutFile.outfiles is
        // empty, so there's nothing waiting to be finalized.
        while !OutFile.outfiles.isEmpty {
            OutFile.outfiles.removeLast()
        }

        // Get rid of any created files that the creator (us!) marked to be
        // deleted.
        //
        // To see those files, comment out this loop and run the tests. Then
        // uncomment it and rerun the tests so the files aren't left lying
        // around.
        while !filesToForget.isEmpty {
            let file = filesToForget.removeLast()
            XCTAssertNoThrow(try FileManager.default.removeItem(at: file.url))
        }
    }
    
    
    // File registration and deregistration
    
    func testRegistration() {
        XCTAssertEqual(OutFile.outfiles.count, 0, "checking OutFile registration")
        let treg1 = OutFile(testOutFileDirectory + "testreg1")
        XCTAssertEqual(OutFile.outfiles.count, 1, "checking OutFile registration")
        let treg2 = OutFile(testOutFileDirectory + "testreg2")
        XCTAssertEqual(OutFile.outfiles.count, 2, "checking OutFile registration")
        let treg3 = OutFile(testOutFileDirectory + "testreg3")
        XCTAssertEqual(OutFile.outfiles.count, 3, "checking OutFile registration")
        let treg4 = OutFile(testOutFileDirectory + "testreg4")
        XCTAssertEqual(OutFile.outfiles.count, 4, "checking OutFile registration")
        
        // Deregister, not in order of registering
        XCTAssertNoThrow(try treg3.deregister())
        XCTAssertEqual(OutFile.outfiles.count, 3, "checking OutFile deregistration")
        XCTAssertNoThrow(try treg1.deregister())
        XCTAssertEqual(OutFile.outfiles.count, 2, "checking OutFile deregistration")
        XCTAssertNoThrow(try treg4.deregister())
        XCTAssertEqual(OutFile.outfiles.count, 1, "checking OutFile deregistration")
        XCTAssertNoThrow(try treg2.deregister())
        XCTAssertEqual(OutFile.outfiles.count, 0, "checking OutFile deregistration")

        // Double deregister
        XCTAssertThrowsError(try treg4.deregister(), "expected double-deregistration error") {
            error in
            XCTAssertEqual(error as? FileError,
                           .failedWrite("""
deregister unregistered file \"\(treg4.name)\"
--- possible double deregistration?
"""),
                           "wrong error message: \(error)")
        }
    }
    
    // Nonexistent directory

    func testNonexistentDirectory() {
        let baddirname = "nosuchdir/" // no such directory
        let nodirwritefilename = "out.shouldnotexist"  // no such file
        let nodirwritefile = OutFile(testOutFileDirectory + baddirname + nodirwritefilename)
        XCTAssertThrowsError(try nodirwritefile.finalize(), "expected no-such-directory error") {
            error in
            XCTAssertEqual(error as? FileError,
                           .failedWrite(
                            /* Warning! non-ASCII double and single quotes */
"""
folder “out.shouldnotexist” doesn’t exist
"""),
                           "wrong error message: \(error)")
        }
        XCTAssertNoThrow(try nodirwritefile.deregister())
    }

    // Bad permissions on file
    
    func testBadFilePermissions() {
        let nowritefilename = "out.nowritepermission"  // permissions 400/r--...
        let nowritefile = OutFile(testOutFileDirectory + nowritefilename)
        nowritefile.baseWrite("hi, mom")
        XCTAssertThrowsError(try nowritefile.finalize(), "expected no-write-permission error") {
            error in
            XCTAssertEqual(error as? FileError,
                           .failedWrite(
                           /* Warning! non-ASCII double and single quotes */
"""
file \"\(nowritefile.name)\"
    File does not have write permission
"""),
                           "wrong error message: \(error)")
        }
        XCTAssertNoThrow(try nowritefile.deregister())
    }

    // Bad permissions on directory

    func testBadDirectoryPermissions() {
        let nowritedir = "dir.nowritepermission" // inside testOutFileDirectory;
                                                  // permissions 500/r-x...
        // Trailing slash omitted from nowritedir to make it easier to construct
        // expected error message for XCTAssertEqual call, below.
        
        let cantcreatefile = OutFile(testOutFileDirectory + nowritedir + "/" + "cantcreate")
        cantcreatefile.baseWrite("hi, mom")
        XCTAssertThrowsError(try cantcreatefile.finalize(),
                             "expected dir-no-write-permission error") {
            error in
            XCTAssertEqual(error as? FileError,
                           .failedWrite("""
You don’t have permission to save the file “cantcreate” in the folder “\(nowritedir)”.
"""),
                           "wrong error message: \(error)")
        }
        XCTAssertNoThrow(try cantcreatefile.deregister())
    }

    // Done testing bad file permissions and existence


    // Test baseWrite(message:)

    func testBaseWrite() {
        let baseWriteFile = OutFile(testOutFileDirectory + "baseWrite", msgPrefix: "xy")
        XCTAssertEqual(baseWriteFile.output, "")
        XCTAssertFalse(baseWriteFile.hasBeenUsed)
        baseWriteFile.baseWrite("hi")
        XCTAssertTrue(baseWriteFile.hasBeenUsed)
        XCTAssertEqual(baseWriteFile.output, "hi")
        baseWriteFile.baseWrite("mom")
        XCTAssertEqual(baseWriteFile.output, "himom")
        baseWriteFile.baseWrite("\ndad")
        XCTAssertEqual(baseWriteFile.output, "himom\ndad")
        XCTAssertNoThrow(try baseWriteFile.deregister())
    }

    // Test write(message:)

    func testWrite() {
        let writeFile = OutFile(testOutFileDirectory + "write", msgPrefix: "xy")
        XCTAssertEqual(writeFile.output, "")
        XCTAssertFalse(writeFile.hasBeenUsed)
        writeFile.write("hi")
        XCTAssertTrue(writeFile.hasBeenUsed)
        XCTAssertEqual(writeFile.output, "xyhi")
        writeFile.write("mom")
        XCTAssertEqual(writeFile.output, "xyhixymom")
        writeFile.write("\ndad")
        XCTAssertEqual(writeFile.output, "xyhixymomxy\ndad")
        XCTAssertNoThrow(try writeFile.deregister())
    }

    // Test writeln(message:)

    func testWriteLn() {
        let writelnFile = OutFile(testOutFileDirectory + "writeln", msgPrefix: "xy")
        XCTAssertEqual(writelnFile.output, "")
        XCTAssertFalse(writelnFile.hasBeenUsed)
        writelnFile.writeln("hi")
        XCTAssertTrue(writelnFile.hasBeenUsed)
        XCTAssertEqual(writelnFile.output, "xyhi\n")
        writelnFile.writeln("mom")
        XCTAssertEqual(writelnFile.output, "xyhi\nxymom\n")
        writelnFile.writeln("\ndad")
        XCTAssertEqual(writelnFile.output, "xyhi\nxymom\nxy\ndad\n")
        writelnFile.writeln() // Checking default output string "".
        XCTAssertEqual(writelnFile.output, "xyhi\nxymom\nxy\ndad\nxy\n")
        writelnFile.write("rover")
        XCTAssertEqual(writelnFile.output, "xyhi\nxymom\nxy\ndad\nxy\nxyrover")
        XCTAssertNoThrow(try writelnFile.deregister())
    }

    // Test writeln(line:message:)

    func testWriteLnMsg() {
        let writelnmsgFile = OutFile(testOutFileDirectory + "writelnmsg", msgPrefix: "xy")
        XCTAssertEqual(writelnmsgFile.output, "")
        XCTAssertFalse(writelnmsgFile.hasBeenUsed)
        writelnmsgFile.writeln(23, "hi")
        XCTAssertTrue(writelnmsgFile.hasBeenUsed)
        XCTAssertEqual(writelnmsgFile.output, "xyat line 24, hi\n")
        writelnmsgFile.writeln(35, "mom")
        XCTAssertEqual(writelnmsgFile.output, "xyat line 24, hi\nxyat line 36, mom\n")
        writelnmsgFile.writeln(-12, "\ndad")
        XCTAssertEqual(writelnmsgFile.output,
                       "xyat line 24, hi\nxyat line 36, mom\nxyat line -11, \ndad\n")
        writelnmsgFile.write("rover")
        XCTAssertEqual(writelnmsgFile.output,
                       "xyat line 24, hi\nxyat line 36, mom\nxyat line -11, \ndad\nxyrover")
        XCTAssertNoThrow(try writelnmsgFile.deregister())
    }

    // Done testing writing to OutFile -- but without saving results
    // to the actual file system

    
    // Test StreamedOutFile with stdout and stderr
    
    func testStreamedOutFile() {
        let reportfile = StreamedOutFile(testOutFileDirectory + "report",
                                         msgPrefix: "reporting: ", stream: stdoutStream)
        
        XCTAssertFalse(reportfile.hasBeenUsed, "StreamedOutFile with stdout before use")
        reportfile.writeln("Line 1 from reportfile")
        XCTAssertTrue(reportfile.hasBeenUsed, "StreamedOutFile with stdout after use")
        reportfile.finalize()
        
        let errorsfile = StreamedOutFile(testOutFileDirectory + "errors",
                                         msgPrefix: "ERROR: ", stream: stderrStream)
        
        // There is actual output here! -- to stdout and stderr.
        XCTAssertFalse(errorsfile.hasBeenUsed, "StreamedOutFile with stderr before use")
        errorsfile.writeln("Line 1 from errorsfile")
        XCTAssertTrue(errorsfile.hasBeenUsed, "StreamedOutFile with stderr after use")
        errorsfile.finalize()
        
        // Make sure finalizeAll() doesn't complain.
        XCTAssertNoThrow(try OutFile.finalizeAll())
        XCTAssertNoThrow(try reportfile.deregister())
        XCTAssertNoThrow(try errorsfile.deregister())
        XCTAssertEqual(OutFile.outfiles.count, 0)
   }
    
    // Done testing writing to StreamedOutFile


    // Test finalizeAll()
    
    func testFinalizeAll() {
        // The list OutFile.outfiles is empty, because if some previous
        // test accidentally didn't deregister its files, then tearDown()
        // cleaned them up.
        
        // Make a couple of StreamedOutFiles and a couple of regular OutFiles,
        // and send the regular files something to write.
        _ = StreamedOutFile(testOutFileDirectory + "streamed1",
                                         msgPrefix: "streamed one: ", stream: stdoutStream)
        _ = StreamedOutFile(testOutFileDirectory + "streamed2",
                                         msgPrefix: "streamed two: ", stream: stderrStream)

        let outfile1 = OutFile(testOutFileDirectory + "tempfile1", msgPrefix: "file one: ")
        outfile1.writeln("my url is: \(outfile1.url)")
        
        let outfile2 = OutFile(testOutFileDirectory + "tempfile2", msgPrefix: "file two: ")
        outfile2.writeln("my url is: \(outfile2.url)")
        
        XCTAssertNoThrow(try OutFile.finalizeAll())

        // We wrote actual files. Make a note to delete them.
        filesToForget.append(outfile1)
        filesToForget.append(outfile2)
    }
    
// Done testing finalizeAll

    // Test write-then-read
    
    func testWriteThenRead() {
        
        let writereadfile = OutFile(testOutFileDirectory + "tempwriteread")
        writereadfile.writeln("")
        writereadfile.writeln("\n")
        writereadfile.writeln("hi, mom")
        XCTAssertNoThrow(try writereadfile.finalize())
        
        let readwrittenfile = InFile(writereadfile.name)
        XCTAssertNoThrow(try readwrittenfile.readContents())
        XCTAssertEqual(readwrittenfile.contents, writereadfile.output,
                  "comparing as-read with as-written")
        
        filesToForget.append(writereadfile)
    }

// Done testing write-then-read


    // Test safeWrite

    func testSafeWrite() {
        // safeWrite on a normal nonexistent file
        let safewritefile = OutFile(testOutFileDirectory + "tempsafewrite")
        safewritefile.writeln("safe line 1")
        safewritefile.writeln("safe line 2")
        safewritefile.writeln("safe line 3")
        XCTAssertNoThrow(try safewritefile.safeWrite())
        
        // safeWrite on a normal existing file -- the same one we just used
        safewritefile.writeln("another line")
        XCTAssertNoThrow(try safewritefile.safeWrite())
        
        filesToForget.append(safewritefile)
    }
    
    func testBadSafeWrite() {
         // Test safeWrite on a non-writable file (a regular OutFile)
        let nopermsafewritefile = OutFile(testOutFileDirectory + "out.nowritepermission")
        nopermsafewritefile.writeln("safe line 1")
        XCTAssertThrowsError(try nopermsafewritefile.safeWrite(),
                             "expected no-write-permission error") { error in
            XCTAssertEqual(error as? FileError,
                           .failedWrite("""
File output failed for file "\(nopermsafewritefile.name)" during move from temporary file.
The output is temporarily available in
"""),
                           "wrong error message: \(error)")
        }
        
        // Test safeWrite on a StreamedOutFile
        let streamedsafewritefile = StreamedOutFile(
            testOutFileDirectory + "tempstreamedsafewrite",
            stream: stdoutStream)
        // streamedsafewritefile.writeln("safe line 1")
        XCTAssertThrowsError(try streamedsafewritefile.safeWrite(),
                             "expected safeWrite on StreamedOutFile to fail") { error in
            XCTAssertEqual(error as? FileError,
                           .failedWrite("""
Safe writing failed: not available for file \"\(streamedsafewritefile.name)\"
"""),
                           "wrong error message: \(error)")
        }
    }
    
    // Done testing safeWrite
    
    // Done testing OutFile
    
}
